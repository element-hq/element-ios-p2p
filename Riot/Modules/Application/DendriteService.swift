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
import Network
import MatrixSDK

@objc class DendriteService: NSObject, CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate {
   
    // MARK: Setup
    
    private var dendrite: GobindDendriteMonolith?
    
    private static let serviceUUID = "a2fda8dd-d250-4a64-8b9a-248f50b93c64"
    private static let serviceUUIDCB = CBUUID(string: serviceUUID)
    
    private static let characteristicUUID = "15d4151b-1008-41c0-85f2-950facf8a3cd"
    private static let characteristicUUIDCB = CBUUID(string: characteristicUUID)
    
    private lazy var central: CBCentralManager = { [unowned self] () -> CBCentralManager in
        CBCentralManager(delegate: self, queue: nil, options: [
            CBCentralManagerOptionShowPowerAlertKey: true
        ])
    }()
    private lazy var peripherals: CBPeripheralManager = { [unowned self] () -> CBPeripheralManager in
        CBPeripheralManager(delegate: self, queue: nil, options: [:])
    }()
    private var timer: Timer?
    
    private var tcpOptions: NWProtocolTCP.Options
    private var nwParameters: NWParameters
    private var ourNetListener: NWListener?
    private var ourNetBrowser: NWBrowser?
    
    private var ourService = CBMutableService(type: DendriteService.serviceUUIDCB, primary: true)
    private var ourCharacteristic: CBMutableCharacteristic?
    private var ourPSM: CBL2CAPPSM?
    
    private var foundPeripherals: [String: CBPeripheral] = [:]
    private var foundServices: [String: [CBService]] = [:]
    
    private var connecting: [String: Bool] = [:]
    private var connectingChannels: [String: CBL2CAPPSM] = [:]
    
    private var connectedChannels: [String: CBL2CAPChannel] = [:]
    private var connectedPeerings: [String: DendriteBLEPeering] = [:]
    private var connectedNetPeerings: [NWEndpoint: DendriteBonjourPeering] = [:]
    
    override init() {
        self.tcpOptions = NWProtocolTCP.Options()
        // self.tcpOptions.noDelay = true
        // self.tcpOptions.enableFastOpen = true
        
        self.nwParameters = NWParameters(tls: nil, tcp: tcpOptions)
        self.nwParameters.includePeerToPeer = true
        self.nwParameters.prohibitedInterfaceTypes = [.loopback]
        self.nwParameters.serviceClass = .background
        
        super.init()
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
        
        private static let bufferSize = Int(truncatingIfNeeded: GobindMaxFrameSize)
        private var inputData = Data(count: DendriteBLEPeering.bufferSize)
        private var outputData = Data(count: DendriteBLEPeering.bufferSize)
        
        private var open: Bool = false
        private var whenStopped: () -> Void
        
        init(_ dendrite: GobindDendriteMonolith, channel: CBL2CAPChannel, whenStopped: @escaping () -> Void) throws {
            self.whenStopped = whenStopped
            super.init()
            
            guard let inputStream = channel.inputStream else { return }
            guard let outputStream = channel.outputStream else { return }
            
            self.inputStream = inputStream
            self.outputStream = outputStream
            
            inputStream.delegate = self
            inputStream.schedule(in: .main, forMode: .default)
            inputStream.open()
            
            outputStream.delegate = self
            outputStream.schedule(in: .main, forMode: .default)
            outputStream.open()
            
            let zone = "ble" // BLE-" + channel.peer.identifier.uuidString
            
            self.dendrite = dendrite
            try self.conduit = dendrite.conduit(zone, peertype: GobindPeerTypeBluetooth)
        }
    
        public func close() {
            if !self.open {
                return
            }
            self.open = false
            DispatchQueue.global().sync {
                self.inputStream?.close()
                self.outputStream?.close()
                try? self.conduit?.close()
                self.whenStopped()
            }
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
                    MXLog.error("DendriteService: Unexpected stream")
                }
                
            case .endEncountered:
                MXLog.error("DendriteService: Stream ended")
                if open {
                    close()
                }
                return
                
            case .errorOccurred:
                MXLog.error("DendriteService: Stream encountered error")
                if open {
                    close()
                }
                return
                
            default:
                MXLog.error("DendriteService: Unexpected stream state")
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
                // MXLog.error("DendriteService: conduit.write: %@", error.localizedDescription)
                if open {
                    close()
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
                        // MXLog.debug("DendriteService: wrote \(n) bytes to BLE")
                    }
                }
            } catch {
                // MXLog.error("DendriteService: conduit.read: \(error.localizedDescription)")
                if open {
                    close()
                }
                return
            }
        }
    }
    
    // MARK: Network peering
    
    class DendriteBonjourPeering: NSObject {
        private var conduit: GobindConduit
        private let connection: NWConnection
        
        private var open: Bool = false
        private var whenStopped: () -> Void
        
        private var receiver = DispatchQueue(label: "Peer Reader")
        private var sender = DispatchQueue(label: "Peer Writer")
        
        private static let bufferSize = Int(truncatingIfNeeded: GobindMaxFrameSize)
     
        init(_ pinecone: GobindDendriteMonolith, connection: NWConnection, whenStopped: @escaping () -> Void) throws {
            let zone = connection.endpoint.debugDescription
            self.connection = connection
            self.whenStopped = whenStopped
            self.conduit = try pinecone.conduit(zone, peertype: GobindPeerTypeBonjour)
            super.init()
            
            self.connection.stateUpdateHandler = { newState in
                switch newState {
                case .ready:
                    MXLog.info("Connection ready: %@", zone)
                    self.open = true
                    self.receiver.async { self.receive() }
                    self.sender.async { self.send() }
                    
                case .cancelled:
                    MXLog.info("Connection cancelled: %@", zone)
                    self.close()
                    
                case .failed:
                    MXLog.error("Connection failed: %@", zone)
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
            self.connection.receive(minimumIncompleteLength: 1, maximumLength: DendriteBonjourPeering.bufferSize, completion: { data, _, isComplete, error in
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
            MXLog.info("Closing connection: %@", self.connection.endpoint.debugDescription)
            
            self.open = false
            if self.connection.state != .cancelled {
                self.connection.cancel()
            }
            try? self.conduit.close()
            
            DispatchQueue.global().sync {
                self.whenStopped()
            }
        }
        
        public func isOpen() -> Bool {
            return self.open
        }
    }
    
    // MARK: Scan for peripherals

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        central.delegate = self
        switch central.state {
        case .poweredOn:
            guard !RiotSettings.shared.yggdrasilDisableBluetooth else { return }
            MXLog.info("DendriteService: Starting Bluetooth scan")
            self.central.scanForPeripherals(
                withServices: [DendriteService.serviceUUIDCB],
                options: [
                    CBCentralManagerScanOptionSolicitedServiceUUIDsKey: [DendriteService.serviceUUIDCB],
                    CBCentralManagerScanOptionAllowDuplicatesKey: true
                ]
            )
            
        case .poweredOff, .resetting:
            self.central.stopScan()
            self.connectedPeerings.forEach { (uuid, peering) in
                peering.close()
            }
            self.foundPeripherals.removeAll()
            self.foundServices.removeAll()
            self.connectingChannels.removeAll()
            self.connectedPeerings.removeAll()
            
        case .unauthorized, .unsupported:
            MXLog.error("DendriteService: Bluetooth not authorised or not supported in centralManagerDidUpdateState")
            
        default:
            MXLog.error("DendriteService: Unexpected Bluetooth state in centralManagerDidUpdateState")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        peripheral.delegate = self
        let uuid = peripheral.identifier.uuidString
        guard self.connectedPeerings[uuid] == nil else { return }
        guard self.connectedChannels[uuid] == nil else { return }
        guard self.connecting[uuid] == nil else { return }
        
        MXLog.debug("DendriteService: centralManager:didDiscover \(peripheral.identifier.uuidString)")
        
        self.foundPeripherals[peripheral.identifier.uuidString] = peripheral
        self.connecting[peripheral.identifier.uuidString] = true
        
        central.connect(peripheral, options: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral.delegate = self
        let uuid = peripheral.identifier.uuidString
        if let err = error {
            MXLog.error("DendriteService: Failed to discover services: %@", err.localizedDescription)
            self.connecting.removeValue(forKey: uuid)
            return
        }
        
        guard self.connectedPeerings[uuid] == nil else { return }
        guard self.connectedChannels[uuid] == nil else { return }
        guard self.connectingChannels[uuid] == nil else { return }
        
        guard let services = peripheral.services else { return }
        self.foundServices[uuid] = services
        
        MXLog.debug("DendriteService: peripheral:didDiscoverServices \(uuid)")
        
        for service in services {
            if service.uuid != DendriteService.serviceUUIDCB {
                continue
            }
            peripheral.delegate = self
            peripheral.discoverCharacteristics([DendriteService.characteristicUUIDCB], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        peripheral.delegate = self
        MXLog.debug("DendriteService: peripheral:didModifyServices \(peripheral.identifier.uuidString)")
        
        for service in invalidatedServices {
            if let servicePeripheral = service.peripheral {
                self.foundServices.removeValue(forKey: servicePeripheral.identifier.uuidString)
            }
        }
    }
    
    // MARK: Discover services
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        
        let key = peripheral.identifier.uuidString
        guard self.connectedPeerings[key] == nil else { return }
        guard self.connectedChannels[key] == nil else { return }
        
        peripheral.discoverServices([DendriteService.serviceUUIDCB])
        
        MXLog.debug("DendriteService: centralManager:didConnect \(key)")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        MXLog.error("DendriteService: Failed to connect to %@: %@", peripheral.identifier.debugDescription, error?.localizedDescription ?? "unknown error")
        
        let key = peripheral.identifier.uuidString
        self.connecting.removeValue(forKey: key)
        self.connectingChannels.removeValue(forKey: key)
        self.foundPeripherals.removeValue(forKey: key)
        self.foundServices.removeValue(forKey: key)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        MXLog.info("DendriteService: Disconnected from \(peripheral.identifier): \(String(describing: error?.localizedDescription))")
        
        let key = peripheral.identifier.uuidString
        self.connecting.removeValue(forKey: key)
        self.connectingChannels.removeValue(forKey: key)
        self.foundPeripherals.removeValue(forKey: key)
        self.foundServices.removeValue(forKey: key)
    }
    
    // MARK: Discover characteristics
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let err = error {
            self.connecting.removeValue(forKey: peripheral.identifier.uuidString)
            MXLog.error("DendriteService: Failed to discover characteristics: %@", err.localizedDescription)
            return
        }
        
        let key = peripheral.identifier.uuidString
        guard self.connectedPeerings[key] == nil else { return }
        guard self.connectedChannels[key] == nil else { return }
        guard let characteristics = service.characteristics else { return }
        
        MXLog.debug("DendriteService: centralManager:didDiscoverCharacteristicsFor \(peripheral.identifier.uuidString)")
        
        for characteristic in characteristics {
            if characteristic.uuid != DendriteService.characteristicUUIDCB {
                continue
            }
            peripheral.readValue(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        MXLog.debug("DendriteService: peripheral:didUpdateValueFor \(peripheral.identifier.uuidString)")
        
        if let err = error {
            MXLog.error("DendriteService: Failed to update value for characteristic: %@", err.localizedDescription)
            return
        }
        
        guard let value = characteristic.value else { return }
        
        let psmvalue = value.reduce(0) { soFar, byte in
            return soFar << 8 | UInt32(byte)
        }
        let key = peripheral.identifier.uuidString
        let psm = CBL2CAPPSM(UInt16(psmvalue))
        
        // guard self.connectingChannels[key] != psm else { return }
        // guard self.connectedChannels[key] == nil else { return }
    
        MXLog.info("DendriteService: Found \(key) PSM \(psm), opening L2CAP channel...")
        self.connectingChannels[key] = psm
        peripheral.openL2CAPChannel(psm)
    }
    
    // MARK: Listen for L2CAP
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            guard !RiotSettings.shared.yggdrasilDisableBluetooth else { return }
            MXLog.info("DendriteService: Publishing L2CAP channel")
            peripheral.publishL2CAPChannel(withEncryption: false)
                
        case .poweredOff, .resetting:
            self.peripherals.stopAdvertising()
            self.peripherals.removeAllServices()
            
        case .unauthorized, .unsupported:
            MXLog.warning("DendriteService: Bluetooth not authorised or not supported in peripheralManagerDidUpdateState")
            
        default:
            MXLog.error("DendriteService: Unexpected Bluetooth state in peripheralManagerDidUpdateState")
        }
    }
    
    // MARK: Accept incoming L2CAP
    
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        guard let channel = channel else { return }
        guard let dendrite = self.dendrite else { return }
        let key = channel.peer.identifier.uuidString
        
        defer {
            self.connecting.removeValue(forKey: key)
            self.connectingChannels.removeValue(forKey: key)
        }
        
        if let err = error {
            MXLog.error("DendriteService: Failed to open outbound L2CAP: %@", err.localizedDescription)
            return
        }
        
        MXLog.info("DendriteService: Outbound L2CAP channel open \(channel.debugDescription)")
        
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
        let key = channel.peer.identifier.uuidString
        
        defer {
            self.connecting.removeValue(forKey: key)
            self.connectingChannels.removeValue(forKey: key)
        }

        if let err = error {
            MXLog.error("DendriteService: Failed to open inbound L2CAP: %@", err.localizedDescription)
            return
        }
    
        MXLog.info("DendriteService: Inbound L2CAP channel open \(channel.debugDescription)")
        
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
        MXLog.info("DendriteService: Starting advertising")
        
        if !RiotSettings.shared.yggdrasilDisableBluetooth {
            peripheral.startAdvertising([
                CBAdvertisementDataServiceUUIDsKey: [DendriteService.serviceUUIDCB]
            ])
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
        MXLog.info("DendriteService: Peripheral manager started publishing PSM \(PSM)")
        
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
            peripheral.removeAllServices()
            peripheral.add(ourService)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didUnpublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
        MXLog.info("DendriteService: Peripheral manager stopped publishing PSM \(PSM)")
    }
    
    // MARK: UI-driven functions
    
    @objc public func baseURL() -> String? {
        guard let dendrite = self.dendrite else { return nil }
        return dendrite.baseURL()
    }
    
    @objc public func start() {
        if self.dendrite == nil {
            guard let storageDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                fatalError("can't get document directory")
            }
            guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                fatalError("can't get caches directory")
            }
            
            self.dendrite = GobindDendriteMonolith()
            self.dendrite?.storageDirectory = storageDirectory.path
            self.dendrite?.cacheDirectory = cachesDirectory.path
            
            MXLog.info("Storage directory: \(storageDirectory)")
            MXLog.info("Cache directory: \(cachesDirectory)")
            
            self.dendrite?.start()
            
            if RiotSettings.shared.yggdrasilEnableStaticPeer {
                self.setStaticPeer(RiotSettings.shared.yggdrasilStaticPeerURI)
            } else {
                self.setStaticPeer("")
            }
            
            self.setBluetoothEnabled(!RiotSettings.shared.yggdrasilDisableBluetooth)
            self.setMulticastEnabled(!RiotSettings.shared.yggdrasilDisableMulticast)
            self.setBonjourEnabled(!RiotSettings.shared.yggdrasilDisableBonjour)
        }
    }
    
    @objc public func stop() {
        if self.dendrite != nil {
            self.setBluetoothEnabled(false)
            self.setMulticastEnabled(false)
            self.setBonjourEnabled(false)
            self.setStaticPeer("")
            
            self.dendrite?.stop()
            self.dendrite = nil
        }
    }
    
    @objc public func setBluetoothEnabled(_ enabled: Bool) {
        if enabled {
            self.connecting = [:]
            self.foundPeripherals = [:]
            self.foundServices = [:]
            self.connectedChannels = [:]
            self.connectedPeerings = [:]
            
            self.centralManagerDidUpdateState(self.central)
            self.peripheralManagerDidUpdateState(self.peripherals)
        } else {
            self.central.stopScan()
            self.peripherals.stopAdvertising()
            
            self.dendrite?.disconnectType(GobindPeerTypeBluetooth)
            
            for (_, peer) in self.connectedPeerings {
                if peer.isOpen() {
                    peer.close()
                }
            }
        }
    }
    
    @objc public func setMulticastEnabled(_ enabled: Bool) {
        guard self.dendrite != nil else { return }
        guard let dendrite = self.dendrite else { return }
        dendrite.setMulticastEnabled(enabled)
    }
    
    @objc public func setBonjourEnabled(_ enabled: Bool) {
        guard let dendrite = self.dendrite else { return }
        
        if enabled {
            self.ourNetListener = try? NWListener(using: self.nwParameters)
            self.ourNetBrowser = NWBrowser(for: .bonjourWithTXTRecord(type: "_pinecone._tcp", domain: nil), using: self.nwParameters)
            self.connectedNetPeerings = [:]
            
            if let listener = self.ourNetListener {
                listener.service = NWListener.Service(name: dendrite.publicKey(), type: "_pinecone._tcp")
                listener.service?.txtRecordObject = NWTXTRecord(["key": dendrite.publicKey()])
                listener.stateUpdateHandler = { newState in
                    // MXLog.info("Network listener state %@", newState)
                }
                listener.newConnectionHandler = { newConnection in
                    if let peering = self.connectedNetPeerings[newConnection.endpoint] {
                        peering.close()
                    }
                    do {
                        self.connectedNetPeerings[newConnection.endpoint] = try DendriteBonjourPeering(dendrite, connection: newConnection, whenStopped: {
                            MXLog.info("Inbound endpoint disconnected: %@", newConnection.endpoint.debugDescription)
                        })
                    } catch {
                        MXLog.error("Failed to create peering: %@", error.localizedDescription)
                        return
                    }
                    MXLog.info("Inbound endpoint connected: %@", newConnection.endpoint.debugDescription)
                }
                listener.start(queue: .main)
            }
            if let browser = self.ourNetBrowser {
                browser.stateUpdateHandler = { newState in
                   // MXLog.info("Network browser state %@", newState)
                }
                browser.browseResultsChangedHandler = { results, changes in
                    for result in results {
                        switch result.metadata {
                        case .bonjour(let record):
                            if record["key"] == dendrite.publicKey() {
                                continue
                            }
                        case .none:
                            continue
                        default:
                            continue
                        }
                        if case NWEndpoint.service = result.endpoint {
                            if self.connectedNetPeerings[result.endpoint] != nil {
                                continue
                            }
                            let newConnection = NWConnection(to: result.endpoint, using: self.nwParameters)
                            do {
                                self.connectedNetPeerings[newConnection.endpoint] = try DendriteBonjourPeering(dendrite, connection: newConnection, whenStopped: {
                                    MXLog.info("Outbound endpoint disconnected: %@", newConnection.endpoint.debugDescription)
                                })
                            } catch {
                                MXLog.error("Failed to create peering: %@", error.localizedDescription)
                                return
                            }
                            MXLog.info("Outbound endpoint connected: %@", newConnection.endpoint.debugDescription)
                        }
                    }
                }
                browser.start(queue: .main)
            }
        } else {
            if let listener = self.ourNetListener {
                if listener.state != .cancelled {
                    listener.cancel()
                }
            }
            if let browser = self.ourNetBrowser {
                if browser.state != .cancelled {
                    browser.cancel()
                }
            }
            for connection in self.connectedNetPeerings {
                connection.value.close()
            }
            
            self.ourNetListener = nil
            self.ourNetBrowser = nil
        }
    }
    
    @objc public func setStaticPeer(_ uri: String) {
        guard self.dendrite != nil else { return }
        guard let dendrite = self.dendrite else { return }
        dendrite.setStaticPeer(uri.trimmingCharacters(in: .whitespaces))
    }
    
    @objc public func setSelfRelayServers(_ uri: String) {
        guard self.dendrite != nil else { return }
        guard let dendrite = self.dendrite else { return }
        dendrite.setRelayServers(dendrite.publicKey(), uris: uri.trimmingCharacters(in: .whitespaces))
    }
    
    @objc public func getSelfRelayServers() -> String {
        guard self.dendrite != nil else { return "" }
        guard let dendrite = self.dendrite else { return "" }
        return dendrite.getRelayServers(dendrite.publicKey())
    }
    
    @objc public func peers() -> String {
        guard let dendrite = self.dendrite else { return "Dendrite is not running" }

        let totalPeerCount = dendrite.peerCount(-1)
        if totalPeerCount == 0 {
            return "No connectivity"
        }
        var text = "\(totalPeerCount) connected peer"
        if totalPeerCount != 1 {
            text += "s"
        }
        return text
    }
    
    // MARK: Timer functions
    
    @objc func fireTimer() {
 
    }
}
