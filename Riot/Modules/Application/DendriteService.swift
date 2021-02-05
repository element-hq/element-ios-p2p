// 
// Copyright 2020 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import Gobind
import CoreBluetooth

@objc class DendriteService: NSObject, CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate {
   
    // MARK: Setup
    
    private var dendrite = GobindDendriteMonolith()
    
    private static let serviceUUID = "a2fda8dd-d250-4a64-8b9a-248f50b93c64"
    private static let serviceUUIDCB = CBUUID(string: serviceUUID)
    
    private static let characteristicUUID = "15d4151b-1008-41c0-85f2-950facf8a3cd"
    private static let characteristicUUIDCB = CBUUID(string: characteristicUUID)
    
    private var central: CBCentralManager?
    private var peripherals: CBPeripheralManager?
    
    private var ourService = CBMutableService(type: DendriteService.serviceUUIDCB, primary: true)
    private var ourPSM: CBL2CAPPSM?
    
    private var foundPeripherals: [String: CBPeripheral] = [:]
    private var foundServices: [String: [CBService]] = [:]
    private var connectedChannels: [String: CBL2CAPChannel] = [:]
    private var connectedPeerings: [String: DendriteBLEPeering] = [:]
   
    override init() {
        super.init()
        
        // Storage directory for Dendrite databases
        self.dendrite.storageDirectory = "\(NSHomeDirectory())/Documents"
        
        // Core Bluetooth setup
        self.central = CBCentralManager(delegate: self, queue: nil)
        self.peripherals = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    // MARK: BLE peering
    ///
    /// `DendriteBLEPeering` is an instance of a single connection to a given nearby device.
    /// We'll create an instance of this for each `CBL2CAPChannel`.
    ///
    /// There will possibly be more than one nearby device, so it's quite likely that we'll have mutiple
    /// `DendriteBLEPeering` objects in play. Each one of them will request a "conduit" from
    /// Dendrite, which corresponds to a port on the Pinecone overlay switch. We will read from the
    /// BLE input stream and write to the conduit, and likewise, read from the conduit and write to
    /// the BLE output stream. Once the connection dies, so does the instance of this object.
    ///
    class DendriteBLEPeering: NSObject, StreamDelegate {
        // References to Dendrite and
        private var dendrite: GobindDendriteMonolith?
        private var conduit: GobindConduit?
        
        private var inputStream: InputStream?
        private var outputStream: OutputStream?
        
        private var readerQueue = DispatchQueue(label: "Reader")
        private var writerQueue = DispatchQueue(label: "Writer")
        
        private static let bufferSize = 65535*2
        private var inputData = Data(count: DendriteBLEPeering.bufferSize)
        private var outputData = Data(count: DendriteBLEPeering.bufferSize)
        
        private var inputOpen: Bool = false
        private var outputOpen: Bool = false
        
        init(_ dendrite: GobindDendriteMonolith, channel: CBL2CAPChannel) throws {
            super.init()
            
            guard let inputStream = channel.inputStream else { return }
            guard let outputStream = channel.outputStream else { return }
            
            inputStream.delegate = self
            inputStream.schedule(in: .main, forMode: .default)
            inputStream.open()
            
            outputStream.delegate = self
            outputStream.schedule(in: .main, forMode: .default)
            outputStream.open()
            
            self.inputStream = inputStream
            self.outputStream = outputStream
            
            let zone = "BLE-" + channel.peer.identifier.uuidString
            NSLog("DendriteService: Zone \(zone)")
            
            self.dendrite = dendrite
            try self.conduit = dendrite.conduit(zone)
        }
        
        // MARK: BLE streams
        
        func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
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
                NSLog("DendriteService: Unexpected stream")
            }
        }
        
        // MARK: BLE input stream
        
        func inputStream(_ aStream: Stream, handle eventCode: Stream.Event) {
            guard let conduit = self.conduit else { return }
            guard let inputStream = aStream as? InputStream else { return }
            
            switch eventCode {
            case Stream.Event.openCompleted:
                self.inputOpen = true
            
            case Stream.Event.hasBytesAvailable:
                if !self.inputOpen {
                    NSLog("DendriteService: input stream not open yet")
                    return
                }
                
                var rn: Int = 0
                var wn: Int = 0
                self.inputData.withUnsafeMutableBytes { address in
                    if let ptr = address.bindMemory(to: UInt8.self).baseAddress {
                        rn = inputStream.read(ptr, maxLength: DendriteBLEPeering.bufferSize)
                    }
                }
                if rn <= 0 {
                    return
                }
                let c = self.inputData.subdata(in: 0..<rn)
                do {
                    try conduit.write(c, ret0_: &wn)
                } catch {
                    NSLog("DendriteService: conduit.write: \(error)")
                    return
                }
                //NSLog("DendriteService: BLE \(rn) -> \(wn) Pinecone")
                
            case Stream.Event.endEncountered:
                NSLog("DendriteService: inputStream encountered end")
                self.inputOpen = false
                
            case Stream.Event.errorOccurred:
                NSLog("DendriteService: inputStream encountered error")
                self.inputOpen = false
                
            default:
                NSLog("DendriteService: outputStream unexpected event")
            }
        }
        
        // MARK: BLE output stream
        
        func outputStream(_ aStream: Stream, handle eventCode: Stream.Event) {
            guard let conduit = self.conduit else { return }
            guard let outputStream = aStream as? OutputStream else { return }
            
            switch eventCode {
            case Stream.Event.openCompleted:
                self.outputOpen = true
            
            case Stream.Event.hasSpaceAvailable:
                if !self.outputOpen {
                    NSLog("DendriteService: output stream not open yet")
                    return
                }
                
                var wn: Int = 0
                do {
                    let c = try conduit.readCopy()
                    c.withUnsafeBytes { address in
                        if let ptr = address.bindMemory(to: UInt8.self).baseAddress {
                            wn = outputStream.write(ptr, maxLength: c.count)
                        }
                    }
                    //NSLog("DendriteService: Pinecone \(c.count) -> \(wn) BLE")
                } catch {
                    NSLog("DendriteService: conduit.read: \(error)")
                }
                
            case Stream.Event.endEncountered:
                NSLog("DendriteService: outputStream encountered end")
                self.outputOpen = false
                
            case Stream.Event.errorOccurred:
                NSLog("DendriteService: outputStream encountered error")
                self.outputOpen = false
                
            default:
                NSLog("DendriteService: outputStream unexpected event")
            }
        }
    }
    
    // MARK: Scan for peripherals
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        
        NSLog("DendriteService: Starting Bluetooth scan")
        
        self.central?.scanForPeripherals(
            withServices: [DendriteService.serviceUUIDCB],
            options: nil
        )
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        NSLog("DendriteService: Found peripheral \(peripheral.identifier)")
    
        self.foundPeripherals[peripheral.identifier.uuidString] = peripheral
        central.connect(peripheral, options: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        self.foundServices[peripheral.identifier.uuidString] = services
        
        for service in services {
            if service.uuid != DendriteService.serviceUUIDCB {
                continue
            }
            peripheral.delegate = self
            peripheral.discoverCharacteristics([DendriteService.characteristicUUIDCB], for: service)
        }
    }
    
    // MARK: Discover services
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NSLog("DendriteService: Connected to \(peripheral.identifier)")
        
        peripheral.delegate = self
        peripheral.discoverServices([DendriteService.serviceUUIDCB])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NSLog("DendriteService: Failed to connect to \(peripheral.identifier): \(String(describing: error?.localizedDescription))")
        
        self.foundPeripherals.removeValue(forKey: peripheral.identifier.uuidString)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        NSLog("DendriteService: Disconnected from \(peripheral.identifier): \(String(describing: error?.localizedDescription))")
    }
    
    // MARK: Discover characteristics
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid != DendriteService.characteristicUUIDCB {
                continue
            }
            peripheral.readValue(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let value = characteristic.value else { return }
        
        let psmvalue = value.reduce(0) { soFar, byte in
            return soFar << 8 | UInt32(byte)
        }
        let psm = CBL2CAPPSM(UInt16(psmvalue))
    
        if let storedPeripheral = self.foundPeripherals[peripheral.identifier.uuidString] {
            NSLog("DendriteService: Found \(peripheral.identifier) PSM \(psm), opening L2CAP channel...")
            storedPeripheral.openL2CAPChannel(psm)
        } else {
            NSLog("DendriteService: No stored peripheral (this shouldn't happen)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        guard let channel = channel else { return }
        NSLog("DendriteService: L2CAP channel open \(channel.debugDescription)")
        
        self.connectedChannels[peripheral.identifier.uuidString] = channel
        try? self.connectedPeerings[peripheral.identifier.uuidString] = DendriteBLEPeering(dendrite, channel: channel)
    }
    
    // MARK: Accept incoming L2CAP
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        NSLog("DendriteService: Peripheral manager updated state")
        
        peripheral.publishL2CAPChannel(withEncryption: false)
    }
    
    // MARK: Advertise services
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
        NSLog("DendriteService: Peripheral manager started publishing PSM \(PSM)")
    
        guard let peripherals = self.peripherals else { return }
        
        peripherals.delegate = self
        peripherals.add(ourService)
        peripherals.startAdvertising([:])
    }
    
    // MARK: UI-driven functions
    
    @objc public func baseURL() -> String {
        return self.dendrite.baseURL()
    }
    
    @objc public func start() {
        self.dendrite.start()
    }
    
    @objc public func stop() {
        self.dendrite.stop()
    }
    
    @objc public func setMulticastEnabled(_ enabled: Bool) {
        self.dendrite.setMulticastEnabled(enabled)
    }
    
    @objc public func setStaticPeer(_ uri: String) {
        try? self.dendrite.setStaticPeer(uri)
    }
    
    @objc public func peers() -> NSString {
        let peerCount = self.dendrite.peerCount()
        if peerCount == 0 {
            return "No connected peers"
        }
        
        let sessionCount = self.dendrite.sessionCount()
        let text = NSMutableString()
        
        switch sessionCount {
        case 0:
            text.append("No connections")
        case 1:
            text.append("\(sessionCount) connection")
        default:
            text.append("\(sessionCount) connections")
        }
        
        switch peerCount {
        case 1:
            text.append(" via \(peerCount) peer")
        default:
            text.append(" via \(peerCount) peers")
        }
        
        return text
    }
}
