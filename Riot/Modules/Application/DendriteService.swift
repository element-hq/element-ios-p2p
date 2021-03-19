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
    
    private var dendrite: GobindDendriteMonolith?
    
    private static let serviceUUID = "a2fda8dd-d250-4a64-8b9a-248f50b93c64"
    private static let serviceUUIDCB = CBUUID(string: serviceUUID)
    
    private static let characteristicUUID = "15d4151b-1008-41c0-85f2-950facf8a3cd"
    private static let characteristicUUIDCB = CBUUID(string: characteristicUUID)
    
    private var central: CBCentralManager?
    private var peripherals: CBPeripheralManager?
    private var timer: Timer?
    
    private var ourService = CBMutableService(type: DendriteService.serviceUUIDCB, primary: true)
    private var ourCharacteristic: CBMutableCharacteristic?
    private var ourPSM: CBL2CAPPSM?
    
    private var connecting: [String: Bool] = [:]
    private var foundPeripherals: [String: CBPeripheral] = [:]
    private var foundServices: [String: [CBService]] = [:]
    private var connectedChannels: [String: CBL2CAPChannel] = [:]
    private var connectedPeerings: [String: DendriteBLEPeering] = [:]
   
    override init() {
        super.init()
        
        // self.timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
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
        
        private var open: Bool = false
        private var whenStopped: () -> Void
        
        init(_ dendrite: GobindDendriteMonolith, channel: CBL2CAPChannel, whenStopped: @escaping () -> Void) throws {
            self.whenStopped = whenStopped
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
            
            let zone = "ble" // BLE-" + channel.peer.identifier.uuidString
            
            self.dendrite = dendrite
            try self.conduit = dendrite.conduit(zone, peertype: GobindPeerTypeBluetooth)
        }
    
        public func close() {
            self.open = false
            self.whenStopped()
            
            self.inputStream?.close()
            self.outputStream?.close()
            try? self.conduit?.close()
        }
        
        public func isOpen() -> Bool {
            return self.open
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
                self.open = true
            
            case Stream.Event.hasBytesAvailable:
                var rn: Int = 0
                var wn: Int = 0
                self.inputData.withUnsafeMutableBytes { address in
                    if let ptr = address.bindMemory(to: UInt8.self).baseAddress {
                        rn = inputStream.read(ptr, maxLength: DendriteBLEPeering.bufferSize) // BLOCKING OPERATION
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
                
            case Stream.Event.endEncountered:
                NSLog("DendriteService: inputStream encountered end")
                if open {
                    close()
                }
                
            case Stream.Event.errorOccurred:
                NSLog("DendriteService: inputStream encountered error")
                if open {
                    close()
                }
                
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
                self.open = true
            
            case Stream.Event.hasSpaceAvailable:
                do {
                    let c = try conduit.readCopy() // BLOCKING OPERATION
                    c.withUnsafeBytes { address in
                        if let ptr = address.bindMemory(to: UInt8.self).baseAddress {
                            let n = outputStream.write(ptr, maxLength: c.count)
                            //NSLog("DendriteService: wrote \(n) bytes to BLE")
                        }
                    }
                } catch {
                    NSLog("DendriteService: conduit.read: \(error)")
                }
                
            case Stream.Event.endEncountered:
                NSLog("DendriteService: outputStream encountered end")
                if open {
                    close()
                }
                
            case Stream.Event.errorOccurred:
                NSLog("DendriteService: outputStream encountered error")
                if open {
                    close()
                }
                
            default:
                NSLog("DendriteService: outputStream unexpected event")
            }
        }
    }
    
    // MARK: State restoration
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {
        
    }
    
    // MARK: Scan for peripherals

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            guard !RiotSettings.shared.yggdrasilDisableBluetooth else { return }
            NSLog("DendriteService: Starting Bluetooth scan")
            self.central?.scanForPeripherals(
                withServices: [DendriteService.serviceUUIDCB],
                options: [
                    CBCentralManagerScanOptionSolicitedServiceUUIDsKey: [DendriteService.serviceUUIDCB]
                ]
            )
            
        case .poweredOff:
            self.central?.stopScan()
            self.connectedPeerings.forEach { (uuid, peering) in
                peering.close()
            }
            self.foundPeripherals.removeAll()
            self.foundServices.removeAll()
            
        default:
            NSLog("DendriteService: Unexpected Bluetooth state")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let uuid = peripheral.identifier.uuidString
        guard self.connecting[uuid] == nil else { return }
        guard self.connectedChannels[uuid] == nil else { return }
        
        NSLog("DendriteService: centralManager:didDiscover \(peripheral.identifier.uuidString)")
        
        self.foundPeripherals[peripheral.identifier.uuidString] = peripheral
        self.connecting[peripheral.identifier.uuidString] = true
        
        central.connect(peripheral, options: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let err = error {
            NSLog("DendriteService: Failed to discover services: \(err)")
            self.connecting.removeValue(forKey: peripheral.identifier.uuidString)
            self.foundPeripherals.removeValue(forKey: peripheral.identifier.uuidString)
            self.foundServices.removeValue(forKey: peripheral.identifier.uuidString)
            return
        }
        
        guard let services = peripheral.services else { return }
        self.foundServices[peripheral.identifier.uuidString] = services
        
        NSLog("DendriteService: centralManager:didDiscoverServices \(peripheral.identifier.uuidString)")
        
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
        peripheral.delegate = self
        peripheral.discoverServices([DendriteService.serviceUUIDCB])
        
        NSLog("DendriteService: centralManager:didConnect \(peripheral.identifier.uuidString)")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NSLog("DendriteService: Failed to connect to \(peripheral.identifier): \(String(describing: error?.localizedDescription))")
        
        self.connecting.removeValue(forKey: peripheral.identifier.uuidString)
        self.foundPeripherals.removeValue(forKey: peripheral.identifier.uuidString)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        NSLog("DendriteService: Disconnected from \(peripheral.identifier): \(String(describing: error?.localizedDescription))")
        
        self.connecting.removeValue(forKey: peripheral.identifier.uuidString)
        self.foundPeripherals.removeValue(forKey: peripheral.identifier.uuidString)
    }
    
    // MARK: Discover characteristics
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let err = error {
            self.connecting.removeValue(forKey: peripheral.identifier.uuidString)
            NSLog("DendriteService: Failed to discover characteristics: \(err)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        NSLog("DendriteService: centralManager:didDiscoverCharacteristicsFor \(peripheral.identifier.uuidString)")
        
        for characteristic in characteristics {
            if characteristic.uuid != DendriteService.characteristicUUIDCB {
                continue
            }
            peripheral.readValue(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            NSLog("DendriteService: Failed to update value for characteristic: \(err)")
            self.connecting.removeValue(forKey: peripheral.identifier.uuidString)
            return
        }
        
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
            self.connecting.removeValue(forKey: peripheral.identifier.uuidString)
        }
    }
    
    // MARK: Listen for L2CAP
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            guard !RiotSettings.shared.yggdrasilDisableBluetooth else { return }
            NSLog("DendriteService: Publishing L2CAP channel")
            peripheral.publishL2CAPChannel(withEncryption: false)
                
        case .poweredOff:
            self.peripherals?.stopAdvertising()
            self.peripherals?.removeAllServices()
            
        default:
            NSLog("DendriteService: Unexpected Bluetooth state")
        }
    }
    
    // MARK: Accept incoming L2CAP
    
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        guard let channel = channel else { return }
        guard let dendrite = self.dendrite else { return }
        
        self.connecting.removeValue(forKey: peripheral.identifier.uuidString)
        
        if let err = error {
            NSLog("DendriteService: Failed to open outbound L2CAP: \(err)")
            return
        }
        
        NSLog("DendriteService: Outbound L2CAP channel open \(channel.debugDescription)")
        
        let key = channel.peer.identifier.uuidString
        if let peer = self.connectedPeerings[key] {
            if peer.isOpen() {
                peer.close()
            }
        }
        
        self.connectedChannels[key] = channel
        try? self.connectedPeerings[key] = DendriteBLEPeering(dendrite, channel: channel, whenStopped: {
            self.connectedChannels.removeValue(forKey: key)
            self.connectedPeerings.removeValue(forKey: key)
        })
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
        guard let channel = channel else { return }
        guard let dendrite = self.dendrite else { return }
        
        self.connecting.removeValue(forKey: channel.peer.identifier.uuidString)
        
        if let err = error {
            NSLog("DendriteService: Failed to open inbound L2CAP: \(err)")
            return
        }
        
        NSLog("DendriteService: Inbound L2CAP channel open \(channel.debugDescription)")
        
        let key = channel.peer.identifier.uuidString
        if let peer = self.connectedPeerings[key] {
            if peer.isOpen() {
                peer.close()
            }
        }
        
        self.connectedChannels[key] = channel
        try? self.connectedPeerings[key] = DendriteBLEPeering(dendrite, channel: channel, whenStopped: {
            self.connectedChannels.removeValue(forKey: key)
            self.connectedPeerings.removeValue(forKey: key)
        })
    }
    
    // MARK: Advertise services
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        NSLog("DendriteService: Starting advertising")
        
        if !RiotSettings.shared.yggdrasilDisableBluetooth {
            peripheral.startAdvertising([
                CBAdvertisementDataServiceUUIDsKey: [DendriteService.serviceUUIDCB]
            ])
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
        NSLog("DendriteService: Peripheral manager started publishing PSM \(PSM)")
        
        ourPSM = PSM
        if let psm = ourPSM {
            let characteristic = CBMutableCharacteristic(
                type: DendriteService.characteristicUUIDCB,
                properties: [.read],
                value: Data([UInt8(psm >> 8 & 0x00ff), UInt8(psm & 0x00ff)]),
                permissions: [.readable]
            )
            
            ourCharacteristic = characteristic
            ourService.characteristics = [characteristic]

            peripheral.delegate = self
            peripheral.add(ourService)
        }
    }
    
    // MARK: UI-driven functions
    
    @objc public func baseURL() -> String? {
        guard let dendrite = self.dendrite else { return nil }
        return dendrite.baseURL()
    }
    
    @objc public func start() {
        if self.dendrite == nil {
            self.dendrite = GobindDendriteMonolith()
            self.dendrite?.storageDirectory = "\(NSHomeDirectory())/Documents"
            self.dendrite?.start()
            
            if RiotSettings.shared.yggdrasilEnableStaticPeer {
                self.setStaticPeer(RiotSettings.shared.yggdrasilStaticPeerURI)
            } else {
                self.setStaticPeer("")
            }
            
            self.setBluetoothEnabled(!RiotSettings.shared.yggdrasilDisableBluetooth)
            self.setMulticastEnabled(!RiotSettings.shared.yggdrasilDisableMulticast)
        }
    }
    
    @objc public func stop() {
        if self.dendrite != nil {
            self.setBluetoothEnabled(false)
            self.setMulticastEnabled(false)
            self.setStaticPeer("")
            
            self.dendrite?.stop()
            self.dendrite = nil
        }
    }
    
    @objc public func setBluetoothEnabled(_ enabled: Bool) {
        if enabled {
            self.central = CBCentralManager(delegate: self, queue: nil, options: [
                CBCentralManagerOptionShowPowerAlertKey: true
            ])
            self.peripherals = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        } else {
            self.central?.stopScan()
            self.peripherals?.stopAdvertising()
            
            self.dendrite?.disconnectType(GobindPeerTypeBluetooth)
            
            self.central = nil
            self.peripherals = nil
        }
    }
    
    @objc public func setMulticastEnabled(_ enabled: Bool) {
        guard self.dendrite != nil else { return }
        guard let dendrite = self.dendrite else { return }
        dendrite.setMulticastEnabled(enabled)
    }
    
    @objc public func setStaticPeer(_ uri: String) {
        guard self.dendrite != nil else { return }
        guard let dendrite = self.dendrite else { return }
        dendrite.setStaticPeer(uri.trimmingCharacters(in: .whitespaces))
    }
    
    @objc public func peers() -> String {
        guard let dendrite = self.dendrite else { return "Dendrite is not running" }
        
        let staticPeerCount = dendrite.peerCount(GobindPeerTypeRemote)
        let wirelessPeerCount = dendrite.peerCount(GobindPeerTypeMulticast)
        let bluetoothPeerCount = dendrite.peerCount(GobindPeerTypeBluetooth)
        
        if staticPeerCount+wirelessPeerCount+bluetoothPeerCount == 0 {
            return "No connectivity"
        }
        
        var texts: [String] = []
        if staticPeerCount > 0 {
            texts.append("Static")
        }
        if wirelessPeerCount > 0 {
            texts.append("\(wirelessPeerCount) LAN")
        }
        if bluetoothPeerCount > 0 {
            texts.append("\(bluetoothPeerCount) BLE")
        }
        var text = texts.joined(separator: ", ") + " peer"
        if staticPeerCount+wirelessPeerCount+bluetoothPeerCount != 1 {
            text += "s"
        }
        return text
    }
    
    // MARK: Timer functions
    
    @objc func fireTimer() {
        guard !RiotSettings.shared.yggdrasilDisableBluetooth else { return }
        
        if let central = self.central {
            central.stopScan()
            self.centralManagerDidUpdateState(central)
        }
        if let peripheral = self.peripherals {
            peripheral.stopAdvertising()
            peripheral.startAdvertising([
                CBAdvertisementDataServiceUUIDsKey: [DendriteService.serviceUUIDCB]
            ])
        }
    }
}
