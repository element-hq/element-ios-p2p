// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import Gobind
import Network

class BonjourPineconePeer: NSObject {
    private var conduit: GobindConduit
    private let connection: NWConnection
    
    private var open: Bool = false
    private var whenStopped: () -> Void
    
    private var receiver = DispatchQueue(label: "Peer Reader")
    private var sender = DispatchQueue(label: "Peer Writer")
    
    private static let bufferSize = Int(truncatingIfNeeded: GobindMaxFrameSize)
    
    private let TAG = "Dendrite - BonjourPineconePeer"
    
    init(_ pinecone: GobindDendriteMonolith, connection: NWConnection, whenStopped: @escaping () -> Void) throws {
        let zone = connection.endpoint.debugDescription
        self.connection = connection
        self.whenStopped = whenStopped
        self.conduit = try pinecone.conduit(zone, peertype: GobindPeerTypeBonjour)
        super.init()
        
        self.connection.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                MXLog.info("Dendrite - BonjourPineconePeer: Connection ready: \(zone)")
                self.open = true
                self.receiver.async { self.receive() }
                self.sender.async { self.send() }
                
            case .cancelled:
                MXLog.info("Dendrite - BonjourPineconePeer: Connection cancelled: \(zone)")
                self.close()
                
            case .failed:
                MXLog.warning("Dendrite - BonjourPineconePeer: Connection failed: \(zone)")
                self.close()
                
            default:
                return
            }
        }
        
        self.connection.start(queue: .main)
    }
    
    func send() {
        guard self.open else { return }
        guard self.connection.state != .cancelled else { return }
        var data: Data?
        do {
            data = try self.conduit.readCopy() // readCopy is potentially blocking
        } catch {
            self.close()
            return
        }
        if let data = data {
            self.connection.send(content: data, contentContext: .defaultMessage, isComplete: false, completion: .contentProcessed({ error in
                if error != nil {
                    self.close()
                } else {
                    self.sender.async { self.send() }
                }
            }))
        }
    }
    
    func receive() {
        guard self.open else { return }
        guard self.connection.state != .cancelled else { return }
        self.connection.receive(minimumIncompleteLength: 1, maximumLength: BonjourPineconePeer.bufferSize, completion: { data, _, isComplete, error in
            if let data = data {
                do {
                    var wn: Int = 0
                    try self.conduit.write(data, ret0_: &wn) // write is potentially blocking
                } catch {
                    self.close()
                    return
                }
            }
            if error != nil {
                self.close()
            } else if !isComplete {
                self.receiver.async { self.receive() }
            }
        })
    }
    
    public func close() {
        if !self.open {
            return
        }
        MXLog.info("\(TAG): Closing connection: \(self.connection.endpoint.debugDescription.string)")
        
        self.open = false
        try? self.conduit.close()
        if self.connection.state != .cancelled {
            self.connection.cancel()
        }
        
        self.whenStopped()
    }
    
    public func isOpen() -> Bool {
        return self.open
    }
}
