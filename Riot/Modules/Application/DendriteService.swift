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
   
    private var monolith = GobindDendriteMonolith()
    
    private static let serviceUUID = "a2fda8dd-d250-4a64-8b9a-248f50b93c64"
    private static let serviceUUIDCB = CBUUID(string: serviceUUID)
    
    private static let characteristicUUID = "15d4151b-1008-41c0-85f2-950facf8a3cd"
    private static let characteristicUUIDCB = CBUUID(string: characteristicUUID)
    
    private var central: CBCentralManager?
    private var peripherals: CBPeripheralManager?
    
    private var foundPeripherals: [String: CBPeripheral] = [:]
    private var foundServices: [String: [CBService]] = [:]
    private var connectedChannels: [String: CBL2CAPChannel] = [:]
    private var connectedSessions: [String: DendriteBLEPeering] = [:]
    
    private var service = CBMutableService(type: DendriteService.serviceUUIDCB, primary: true)
    private var psm: CBL2CAPPSM?
   
    override init() {
        super.init()
        
        self.monolith.storageDirectory = "\(NSHomeDirectory())/Documents"
        self.central = CBCentralManager(delegate: self, queue: nil)
        self.peripherals = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    class DendriteBLEPeering: NSObject, StreamDelegate {
        private var monolith: GobindDendriteMonolith?
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
        
        init(_ monolith: GobindDendriteMonolith, channel: CBL2CAPChannel) throws {
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
            
            self.monolith = monolith
            try self.conduit = monolith.conduit("BLE")
        }
        
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
                
                var n: Int = 0
                self.inputData.withUnsafeMutableBytes { address in
                    n = inputStream.read(address, maxLength: DendriteBLEPeering.bufferSize)
                }
                if n <= 0 {
                    return
                }
                NSLog("DendriteService: inputStream.read got \(n) bytes")
                do {
                    try conduit.write(self.inputData[0..<n], ret0_: &n)
                } catch {
                    NSLog("DendriteService: conduit.write: \(error)")
                    return
                }
                NSLog("DendriteService: conduit.write wrote \(n) bytes")
                
            case Stream.Event.endEncountered:
                NSLog("DendriteService: inputStream encountered end")
                self.inputOpen = false
                
            case Stream.Event.errorOccurred:
                NSLog("DendriteService: inputStream encountered error")
                
            default:
                NSLog("DendriteService: outputStream unexpected event")
            }
        }
        
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
                
                var n: Int = 0
                do {
                    try conduit.read(self.outputData, ret0_: &n)
                } catch {
                    NSLog("DendriteService: conduit.read: \(error)")
                    return
                }
                if n <= 0 {
                    return
                }
                NSLog("DendriteService: conduit.read read \(n) bytes")
                self.outputData.withUnsafeMutableBytes { address in
                    n = outputStream.write(address, maxLength: n)
                }
                NSLog("DendriteService: outputStream.write wrote \(n) bytes")
                
            case Stream.Event.endEncountered:
                NSLog("DendriteService: outputStream encountered end")
                self.outputOpen = true
                
            case Stream.Event.errorOccurred:
                NSLog("DendriteService: outputStream encountered error")
                
            default:
                NSLog("DendriteService: outputStream unexpected event")
            }
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        
        NSLog("DendriteService: Starting Bluetooth scan")
        
        self.central?.scanForPeripherals(
            withServices: [DendriteService.serviceUUIDCB],
            options: nil
        )
    }
    
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
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        NSLog("DendriteService: Peripheral manager updated state")
        
        peripheral.publishL2CAPChannel(withEncryption: false)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
        NSLog("DendriteService: Peripheral manager started publishing PSM \(PSM)")
    
        guard let peripherals = self.peripherals else { return }
        
        peripherals.delegate = self
        peripherals.add(service)
        peripherals.startAdvertising([:])
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
        try? self.connectedSessions[peripheral.identifier.uuidString] = DendriteBLEPeering(monolith, channel: channel)
    }
    
    @objc public func baseURL() -> String {
        return self.monolith.baseURL()
    }
    
    @objc public func start() {
        self.monolith.start()
    }
    
    @objc public func stop() {
        self.monolith.stop()
    }
    
    @objc public func setMulticastEnabled(_ enabled: Bool) {
        self.monolith.setMulticastEnabled(enabled)
    }
    
    @objc public func setStaticPeer(_ uri: String) {
        try? self.monolith.setStaticPeer(uri)
    }
    
    @objc public func peers() -> NSString {
        let peerCount = self.monolith.peerCount()
        if peerCount == 0 {
            return "No connected peers"
        }
        
        let sessionCount = self.monolith.sessionCount()
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
