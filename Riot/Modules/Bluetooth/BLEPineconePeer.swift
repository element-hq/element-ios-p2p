// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import CoreBluetooth
import Gobind

///
/// `BLEPineconePeer` is an instance of a single connection to a given nearby device.
/// We'll create an instance of this for each `CBL2CAPChannel`.
///
/// There will possibly be more than one nearby device, so it's quite likely that we'll have mutiple
/// `BLEPineconePeer` objects in play. Each one of them will request a "conduit" from
/// Dendrite, which corresponds to a port on the Pinecone overlay switch. We will read from the
/// BLE input stream and write to the conduit, and likewise, read from the conduit and write to
/// the BLE output stream. Once the connection dies, so does the instance of this object.
///
class BLEPineconePeer: NSObject, StreamDelegate {
    private var dendrite: GobindDendriteMonolith?
    private var conduit: GobindConduit?
    
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    
    private var readerQueue = DispatchQueue(label: "Reader")
    private var writerQueue = DispatchQueue(label: "Writer")
    
    private static let bufferSize = Int(truncatingIfNeeded: GobindMaxFrameSize)
    private var inputData = Data(count: BLEPineconePeer.bufferSize)
    private var outputData = Data(count: BLEPineconePeer.bufferSize)
    
    private var open: Bool = false
    private var whenStopped: () -> Void
    private var l2capChannel: CBL2CAPChannel
    
    private let TAG = "Dendrite - BLEPineconePeer"
    
    init(_ dendrite: GobindDendriteMonolith, channel: CBL2CAPChannel, whenStopped: @escaping () -> Void) throws {
        MXLog.info("\(TAG): Opening BLE Peering")
        self.whenStopped = whenStopped
        self.l2capChannel = channel
        super.init()
        
        guard let inputStream = channel.inputStream else { return }
        guard let outputStream = channel.outputStream else { return }
        
        let zone = "ble" // BLE-" + channel.peer.identifier.uuidString
        
        MXLog.info("\(TAG): Creating conduit")
        self.dendrite = dendrite
        try self.conduit = dendrite.conduit(zone, peertype: GobindPeerTypeBluetooth)
        
        MXLog.info("\(TAG): Creating peer streams")
        
        self.inputStream = inputStream
        self.outputStream = outputStream
        
        MXLog.info("\(TAG): Opening peer streams")
        inputStream.delegate = self
        inputStream.schedule(in: .main, forMode: .default)
        inputStream.open()
        
        outputStream.delegate = self
        outputStream.schedule(in: .main, forMode: .default)
        outputStream.open()
    }
    
    public func close() {
        MXLog.info("\(TAG): Closing BLE Peering")
        if !self.open {
            return
        }
        self.open = false
        try? self.conduit?.close()
        self.inputStream?.close()
        self.outputStream?.close()
        self.whenStopped()
    }
    
    public func isOpen() -> Bool {
        return self.open
    }
    
    // MARK: BLE streams
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            self.open = true
            
        case .hasBytesAvailable, .hasSpaceAvailable:
            switch aStream {
            case self.inputStream:
                self.readerQueue.async {
                    self.inputStream(aStream, handle: eventCode)
                }
            case self.outputStream:
                self.writerQueue.async {
                    self.outputStream(aStream, handle: eventCode)
                }
            default:
                MXLog.warning("\(TAG): Unexpected stream")
            }
            
        case .endEncountered:
            MXLog.warning("\(TAG): Stream ended")
            if self.open {
                self.close()
            }
            return
            
        case .errorOccurred:
            MXLog.warning("\(TAG): Stream encountered error")
            // if self.open {
            //    self.close()
            // }
            return
            
        default:
            MXLog.warning("\(TAG): Unexpected stream state")
        }
    }
    
    // MARK: BLE input stream
    
    func inputStream(_ aStream: Stream, handle eventCode: Stream.Event) {
        guard let conduit = self.conduit else { return }
        guard let inputStream = aStream as? InputStream else { return }
        guard eventCode == .hasBytesAvailable else { return }
        
        var rn: Int = 0
        var wn: Int = 0
        self.inputData.withUnsafeMutableBytes { address in
            if let ptr = address.bindMemory(to: UInt8.self).baseAddress {
                rn = inputStream.read(ptr, maxLength: BLEPineconePeer.bufferSize) // BLOCKING OPERATION
            }
        }
        if rn <= 0 {
            return
        }
        let c = self.inputData.subdata(in: 0..<rn)
        do {
            try conduit.write(c, ret0_: &wn)
        } catch {
            MXLog.warning("\(TAG): conduit.write: \(error.localizedDescription)")
            if self.open {
                self.close()
            }
            return
        }
    }
    
    // MARK: BLE output stream
    
    func outputStream(_ aStream: Stream, handle eventCode: Stream.Event) {
        guard let conduit = self.conduit else { return }
        guard let outputStream = aStream as? OutputStream else { return }
        guard eventCode == .hasSpaceAvailable else { return }
        
        do {
            let c = try conduit.readCopy() // BLOCKING OPERATION
            c.withUnsafeBytes { address in
                if let ptr = address.bindMemory(to: UInt8.self).baseAddress {
                    _ = outputStream.write(ptr, maxLength: c.count)
                }
            }
        } catch {
            MXLog.warning("\(TAG): conduit.read: \(error.localizedDescription)")
            if self.open {
                self.close()
            }
            return
        }
    }
}
