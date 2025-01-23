// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Gobind
import CoreBluetooth
import Network
import MatrixSDK

@objc class DendriteService: NSObject, CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate {
   
    // MARK: Setup
    
    private var dendrite: GobindDendriteMonolith?
    
    private var bleCentralQueue = DispatchQueue(label: "ble.central.queue")
    private var blePeripheralQueue = DispatchQueue(label: "ble.peripheral.queue")
    
    private let bleTAG = "Dendrite - BLEService"
    private let bonjourTAG = "Dendrite - BonjourService"
    private let TAG = "DendriteService"
    
    private static let serviceUUID = "a2fda8dd-d250-4a64-8b9a-248f50b93c64"
    private static let serviceUUIDCB = CBUUID(string: serviceUUID)
    
    private static let characteristicUUID = "15d4151b-1008-41c0-85f2-950facf8a3cd"
    private static let characteristicUUIDCB = CBUUID(string: characteristicUUID)
    
    private static let characteristicSize = 20
    private static let characteristicKeySize = characteristicSize - 2
    
    private lazy var centralManager: CBCentralManager = { [unowned self] () -> CBCentralManager in
        CBCentralManager(delegate: self, queue: bleCentralQueue, options: [
            CBCentralManagerOptionShowPowerAlertKey: true
        ])
    }()
    private lazy var peripheralManager: CBPeripheralManager = { [unowned self] () -> CBPeripheralManager in
        CBPeripheralManager(delegate: self, queue: blePeripheralQueue, options: [:])
    }()
    private var bleState: BLEState?
    
    private var tcpOptions: NWProtocolTCP.Options
    private var nwParameters: NWParameters
    private var ourNetListener: NWListener?
    private var ourNetBrowser: NWBrowser?
    
    private var ourService = CBMutableService(type: DendriteService.serviceUUIDCB, primary: true)
    private var ourCharacteristic: CBMutableCharacteristic?
    private var ourPSM: CBL2CAPPSM?
    
    private var bleLastConnectionAttempt: [DeviceUUID: TimeInterval] = [:]
    private var connectedNetPeerings: [NWEndpoint: BonjourPineconePeer] = [:]
    
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
    
    // MARK: UI-driven functions
    
    @objc public func baseURL() -> String? {
        guard let dendrite = self.dendrite else { return nil }
        return dendrite.baseURL()
    }
    
    @objc public func start() {
        if self.dendrite == nil {
            MXLog.info("\(TAG): Starting")
            guard let storageDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                fatalError("can't get document directory")
            }
            guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                fatalError("can't get caches directory")
            }
            
            self.dendrite = GobindDendriteMonolith()
            self.dendrite?.storageDirectory = storageDirectory.path
            self.dendrite?.cacheDirectory = cachesDirectory.path
            
            MXLog.info("\(TAG): Storage directory: \(storageDirectory)")
            MXLog.info("\(TAG): Cache directory: \(cachesDirectory)")
            
            self.dendrite?.start()
            
            if RiotSettings.shared.yggdrasilEnableStaticPeer {
                self.setStaticPeer(RiotSettings.shared.yggdrasilStaticPeerURI)
            } else {
                self.setStaticPeer("")
            }
            
            self.setRelayingEnabled(RiotSettings.shared.yggdrasilEnableRelaying)
            
            self.setBluetoothEnabled(!RiotSettings.shared.yggdrasilDisableBluetooth)
            self.setMulticastEnabled(!RiotSettings.shared.yggdrasilDisableMulticast)
            self.setBonjourEnabled(!RiotSettings.shared.yggdrasilDisableBonjour)
        }
    }
    
    @objc public func stop() {
        if self.dendrite != nil {
            MXLog.info("\(TAG): Stopping")
            self.setBluetoothEnabled(false)
            self.setMulticastEnabled(false)
            self.setBonjourEnabled(false)
            self.setStaticPeer("")
            self.setRelayingEnabled(false)
            
            self.dendrite?.stop()
            self.dendrite = nil
        }
    }
    
    @objc public func setBluetoothEnabled(_ enabled: Bool) {
        if enabled {
            MXLog.info("\(TAG): Enabling bluetooth")
            self.bleState = BLEState(self.centralManager)
            self.centralManagerDidUpdateState(self.centralManager)
            self.peripheralManagerDidUpdateState(self.peripheralManager)
        } else {
            MXLog.info("\(TAG): Disabling bluetooth")
            self.resetBleState()
            self.bleState = nil
            self.dendrite?.disconnectType(GobindPeerTypeBluetooth)
        }
    }
    
    @objc public func setMulticastEnabled(_ enabled: Bool) {
        guard self.dendrite != nil else { return }
        guard let dendrite = self.dendrite else { return }
        if enabled {
            MXLog.info("\(self.TAG): Enabling Multicast")
        } else {
            MXLog.info("\(self.TAG): Disabling Multicast")
        }
        dendrite.setMulticastEnabled(enabled)
    }
    
    @objc public func setBonjourEnabled(_ enabled: Bool) {
        guard let dendrite = self.dendrite else { return }
        
        if enabled {
            MXLog.info("\(self.TAG): Enabling Bonjour")
            self.ourNetListener = try? NWListener(using: self.nwParameters)
            self.ourNetBrowser = NWBrowser(for: .bonjourWithTXTRecord(type: "_pinecone._tcp", domain: nil), using: self.nwParameters)
            self.connectedNetPeerings = [:]
            
            if let listener = self.ourNetListener {
                listener.service = NWListener.Service(name: dendrite.publicKey(), type: "_pinecone._tcp")
                listener.service?.txtRecordObject = NWTXTRecord(["key": dendrite.publicKey()])
                listener.stateUpdateHandler = { newState in
                    // MXLog.info("Network listener state \(newState)")
                }
                listener.newConnectionHandler = { newConnection in
                    if let peering = self.connectedNetPeerings[newConnection.endpoint] {
                        peering.close()
                    }
                    do {
                        self.connectedNetPeerings[newConnection.endpoint] = try BonjourPineconePeer(dendrite, connection: newConnection, whenStopped: {
                            MXLog.info("\(self.bonjourTAG): Inbound endpoint disconnected: \(newConnection.endpoint.debugDescription.string)")
                        })
                    } catch {
                        MXLog.warning("\(self.bonjourTAG): Failed to create peering: \(error.localizedDescription)")
                        return
                    }
                    MXLog.info("\(self.bonjourTAG): Inbound endpoint connected: \(newConnection.endpoint.debugDescription.string)")
                }
                listener.start(queue: .main)
            }
            if let browser = self.ourNetBrowser {
                browser.stateUpdateHandler = { newState in
                   // MXLog.info("Network browser state \(newState)")
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
                                self.connectedNetPeerings[newConnection.endpoint] = try BonjourPineconePeer(dendrite, connection: newConnection, whenStopped: {
                                    MXLog.info("\(self.bonjourTAG): Outbound endpoint disconnected: \(newConnection.endpoint.debugDescription.string)")
                                })
                            } catch {
                                MXLog.warning("\(self.bonjourTAG): Failed to create peering: \(error.localizedDescription.string)")
                                return
                            }
                            MXLog.info("\(self.bonjourTAG): Outbound endpoint connected: \(newConnection.endpoint.debugDescription.string)")
                        }
                    }
                }
                browser.start(queue: .main)
            }
        } else {
            MXLog.info("\(self.TAG): Disabling Bonjour")
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
    
    @objc public func setRelayingEnabled(_ enabled: Bool) {
        guard self.dendrite != nil else { return }
        guard let dendrite = self.dendrite else { return }
        if enabled {
            MXLog.info("\(self.TAG): Enabling Relaying")
        } else {
            MXLog.info("\(self.TAG): Disabling Relaying")
        }
        dendrite.setRelayingEnabled(enabled)
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
    
    @objc public func setRelayServers(_ userID: String, _ uri: String) {
        guard self.dendrite != nil else { return }
        guard let dendrite = self.dendrite else { return }
        dendrite.setRelayServers(userID.trimmingCharacters(in: .whitespaces), uris: uri.trimmingCharacters(in: .whitespaces))
    }
    
    @objc public func getRelayServers(_ userID: String) -> String {
        guard self.dendrite != nil else { return "" }
        guard let dendrite = self.dendrite else { return "" }
        return dendrite.getRelayServers(userID.trimmingCharacters(in: .whitespaces))
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
    
    // MARK: BLE State
    
    private func resetPeripheralState(device: DeviceUUID) {
        bleState?.clearAllDeviceState(device)
    }
    
    func resetBleState() {
        stopBleScan()
        self.peripheralManager.stopAdvertising()
        self.peripheralManager.removeAllServices()
        bleState?.clear()
    }
    
    // MARK: BLE Client

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            guard !RiotSettings.shared.yggdrasilDisableBluetooth else { return }
            MXLog.info("\(self.bleTAG): Bluetooth powered on")
            self.startBleScan()
                
        case .poweredOff, .resetting:
            MXLog.info("\(self.bleTAG): Bluetooth powered off")
            self.resetBleState()
                
        case .unauthorized, .unsupported:
            MXLog.warning("\(self.bleTAG): Bluetooth not authorised or not supported in centralManagerDidUpdateState")
                
        default:
            MXLog.warning("\(self.bleTAG): Unexpected Bluetooth state in centralManagerDidUpdateState")
        }
    }
    
    // MARK: BLE Scanning
    
    private func startBleScan() {
        if self.centralManager.isScanning { return }
        switch self.centralManager.state {
        case .poweredOn:
            MXLog.info("\(self.bleTAG): Starting BLE scan")
            self.centralManager.scanForPeripherals(
                withServices: [DendriteService.serviceUUIDCB],
                options: [
                    CBCentralManagerScanOptionSolicitedServiceUUIDsKey: [DendriteService.serviceUUIDCB],
                    CBCentralManagerScanOptionAllowDuplicatesKey: true
                ]
            )
        default:
            return
        }
    }
    
    private func stopBleScan() {
        MXLog.info("\(self.bleTAG): Stopping BLE scan")
        self.centralManager.stopScan()
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // TODO: new BLEClient class to handle this delegate
        peripheral.delegate = self
        let uuid = peripheral.identifier.uuidString
        guard !(bleState?.isConnectingOrConnected(uuid, shouldLog: false) ?? true) else { return }
        
        
        if let lastAttempt = self.bleLastConnectionAttempt[uuid] {
            if NSDate().timeIntervalSince1970 - lastAttempt < 2 {
                return
            }
        }
        
        MXLog.debug("\(self.bleTAG): centralManager:didDiscover \(peripheral.identifier.uuidString)")
        
        let lastAttempt = NSDate().timeIntervalSince1970
        MXLog.debug("\(self.bleTAG): set last connection attempt to \(lastAttempt)")
        self.bleLastConnectionAttempt[uuid] = lastAttempt
        
        bleState?.addFoundPeripheral(uuid, peripheral)
        
        central.connect(peripheral, options: nil)
    }
    
    // MARK: BLE GATT Connect
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let uuid = peripheral.identifier.uuidString
        guard !(bleState?.isConnectedDevice(uuid) ?? true) else { return }
        
        MXLog.debug("\(self.bleTAG): centralManager:didConnect \(uuid)")
        peripheral.discoverServices([DendriteService.serviceUUIDCB])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        MXLog.warning("\(self.bleTAG): Failed to connect to \(peripheral.identifier.debugDescription): \(error?.localizedDescription ?? "unknown error")")
            
        let uuid = peripheral.identifier.uuidString
        bleState?.clearAllDeviceState(uuid)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        MXLog.info("\(self.bleTAG): Disconnected from \(peripheral.identifier): \(String(describing: error?.localizedDescription))")

        let uuid = peripheral.identifier.uuidString
        bleState?.clearAllDeviceState(uuid)
    }
    
    // MARK: BLE Discover services
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let uuid = peripheral.identifier.uuidString
        if let err = error {
            MXLog.warning("\(self.bleTAG): Failed to discover services: \(err.localizedDescription)")
            bleState?.clearAllDeviceState(uuid)
            return
        }
        guard !(bleState?.isConnectedDevice(uuid) ?? true) else { return }
        guard let services = peripheral.services else {
            bleState?.clearAllDeviceState(uuid)
            return
        }
        
        MXLog.debug("\(self.bleTAG): peripheral:didDiscoverServices \(uuid)")
        
        for service in services {
            if service.uuid != DendriteService.serviceUUIDCB {
                continue
            }
            peripheral.discoverCharacteristics([DendriteService.characteristicUUIDCB], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        MXLog.debug("\(self.bleTAG): peripheral:didModifyServices \(peripheral.identifier.uuidString)")
    }
    
    // MARK: BLE Discover characteristics
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let uuid = peripheral.identifier.uuidString
        if let err = error {
            MXLog.warning("\(self.bleTAG): Failed to discover characteristics: \(err.localizedDescription)")
            bleState?.clearAllDeviceState(uuid)
            return
        }
        
        guard !(bleState?.isConnectedDevice(uuid) ?? true) else { return }
        guard let characteristics = service.characteristics else {
            bleState?.clearAllDeviceState(uuid)
            return
        }
        
        MXLog.debug("\(self.bleTAG): centralManager:didDiscoverCharacteristicsFor \(peripheral.identifier.uuidString)")
        
        for characteristic in characteristics {
            if characteristic.uuid != DendriteService.characteristicUUIDCB {
                continue
            }
            MXLog.debug("\(self.bleTAG): Found psm characteristic, reading... \(peripheral.identifier.uuidString)")
            peripheral.readValue(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        MXLog.debug("\(self.bleTAG): peripheral:didUpdateValueFor \(peripheral.identifier.uuidString)")
            
        let uuid = peripheral.identifier.uuidString
        guard !(bleState?.isConnectedDevice(uuid) ?? true) else { return }
        if let err = error {
            MXLog.warning("\(self.bleTAG): Failed to update value for characteristic: \(err.localizedDescription.string)")
            bleState?.clearAllDeviceState(uuid)
            return
        }
            
        guard let value = characteristic.value else {
            MXLog.warning("\(self.bleTAG): Characteristic value is invalid")
            bleState?.clearAllDeviceState(uuid)
            return
        }
        if characteristic.value?.count != DendriteService.characteristicSize {
            MXLog.warning("\(self.bleTAG): Received the wrong number of bytes during characteristic read")
            bleState?.clearAllDeviceState(uuid)
            return
        }
            
        let psmBytes = value.subdata(in: 0..<2)
        let psmvalue = psmBytes.reduce(0) { soFar, byte in
            return soFar << 8 | UInt32(byte)
        }
        let psm = CBL2CAPPSM(UInt16(psmvalue))
        
        let keyBytes = value.subdata(in: 2..<DendriteService.characteristicSize)
        let remoteKey = keyBytes.hex
        
        MXLog.info("\(self.bleTAG): Got public key \(remoteKey) with PSM \(psm)")
        if remoteKey.uppercased() <= dendrite!.publicKey().uppercased() {
            MXLog.warning("\(self.bleTAG): Not connecting to device with lower public key \(remoteKey)")
            // NOTE: Don't clear device state here so future discoveries are ignored.
            bleState?.stopTimer(uuid)
            return
        }
            
        guard psm > 0 else {
            MXLog.warning("\(self.bleTAG): Abandoning outbound L2CAP. PSM needs to be > 0...")
            bleState?.clearAllDeviceState(uuid)
            return
        }
        
        if bleState?.isConnectedKey(remoteKey) ?? false {
            MXLog.info("\(self.bleTAG): Already connected to device with this key \(remoteKey)")
            bleState?.registerDevice(uuid, remoteKey)
            bleState?.clearDeviceConnectingState(uuid)
            return
        }
            
        MXLog.info("\(self.bleTAG): Opening outbound L2CAP channel to \(remoteKey)")
        bleState?.registerDevice(uuid, remoteKey)
        bleState?.addConnectingChannel(uuid, psm)
        peripheral.openL2CAPChannel(psm)
    }
    
    // MARK: BLE Connect outbound L2CAP
    
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        let uuid = peripheral.identifier.uuidString
        guard let channel = channel else {
            if let err = error {
                MXLog.warning("\(self.bleTAG): Guard - Invalid outbound L2CAP: \(err.localizedDescription.string)")
            } else {
                MXLog.warning("\(self.bleTAG): Guard - Invalid outbound L2CAP")
            }
            bleState?.clearAllDeviceState(uuid)
            return
        }
        guard !(bleState?.isConnectedDevice(uuid) ?? true) else { return }
        guard let dendrite = self.dendrite else {
            bleState?.clearAllDeviceState(uuid)
            return
        }
        
        if let err = error {
            MXLog.warning("\(self.bleTAG): Failed to open outbound L2CAP: \(err.localizedDescription.string)")
            bleState?.clearAllDeviceState(uuid)
            return
        }
        
        MXLog.info("\(self.bleTAG): Outbound L2CAP channel open \(channel.debugDescription)")
        
        do {
            let peer = try BLEPineconePeer(dendrite, channel: channel, whenStopped: {
                self.bleState?.clearAllDeviceState(uuid)
            })
            bleState?.addPineconePeer(uuid, peer)
        } catch {
            MXLog.warning("\(self.bleTAG): Failed creating new outbound dendrite peering with \(uuid)")
            bleState?.clearAllDeviceState(uuid)
        }
    }
    
    // MARK: BLE Server
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            guard !RiotSettings.shared.yggdrasilDisableBluetooth else { return }
            startAdvertising()
            MXLog.info("\(self.bleTAG): Publishing L2CAP channel")
            peripheral.publishL2CAPChannel(withEncryption: false)
                
        case .poweredOff, .resetting:
            self.peripheralManager.stopAdvertising()
            self.peripheralManager.removeAllServices()
            bleState?.clear()
                
        case .unauthorized, .unsupported:
            MXLog.warning("\(self.bleTAG): Bluetooth not authorised or not supported in peripheralManagerDidUpdateState")
                
        default:
            MXLog.warning("\(self.bleTAG): Unexpected Bluetooth state in peripheralManagerDidUpdateState")
        }
    }
    
    // MARK: BLE Advertise services
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
        MXLog.info("\(self.bleTAG): Peripheral manager started publishing PSM \(PSM)")
        MXLog.info("\(self.bleTAG): Our public key \(dendrite?.publicKey() ?? "nil")")
            
        ourPSM = PSM
        if let ourPublicKey = dendrite?.publicKey() {
            let keyBytes = ourPublicKey.hexBytes[0..<DendriteService.characteristicKeySize]
            if let psm = ourPSM {
                var dataArray = [UInt8(psm >> 8 & 0x00ff), UInt8(psm & 0x00ff)]
                dataArray.append(contentsOf: keyBytes)
                let characteristic = CBMutableCharacteristic(
                    type: DendriteService.characteristicUUIDCB,
                    properties: [.read],
                    value: Data(dataArray),
                    permissions: [.readable]
                )
                        
                ourCharacteristic = characteristic
                ourService.characteristics = [characteristic]
                        
                // peripheral.delegate = self
                peripheral.removeAllServices()
                peripheral.add(ourService)
            }
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        MXLog.info("\(self.bleTAG): Added service")
        startAdvertising()
    }
    
    private func startAdvertising() {
        if !peripheralManager.isAdvertising {
            MXLog.info("\(self.bleTAG): Starting advertising")
            if !RiotSettings.shared.yggdrasilDisableBluetooth {
                peripheralManager.startAdvertising([
                    CBAdvertisementDataServiceUUIDsKey: [DendriteService.serviceUUIDCB]
                ])
            }
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didUnpublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
        MXLog.info("\(self.bleTAG): Peripheral manager stopped publishing PSM \(PSM)")
    }
    
    // MARK: BLE Accept incoming L2CAP
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
        guard let channel = channel else {
            if let err = error {
                MXLog.warning("\(self.bleTAG): Guard - Invalid inbound L2CAP: \(err.localizedDescription.string)")
            } else {
                MXLog.warning("\(self.bleTAG): Guard - Invalid inbound L2CAP")
            }
            return
        }
        let uuid = channel.peer.identifier.uuidString
        guard !(bleState?.isConnectedDevice(uuid) ?? true) else { return }
        guard let dendrite = self.dendrite else {
            bleState?.clearAllDeviceState(uuid)
            return
        }
            
        if let err = error {
            MXLog.warning("\(self.bleTAG): Failed to open inbound L2CAP: \(err.localizedDescription.string)")
            bleState?.clearAllDeviceState(uuid)
            return
        }
            
        MXLog.info("\(self.bleTAG): Inbound L2CAP channel open \(channel.debugDescription)")
            
        do {
            let peer = try BLEPineconePeer(dendrite, channel: channel, whenStopped: {
                self.bleState?.clearAllDeviceState(uuid)
            })
            bleState?.addPineconePeer(uuid, peer)
        } catch {
            MXLog.warning("\(self.bleTAG): Failed creating new inbound dendrite peering with \(uuid)")
            bleState?.clearAllDeviceState(uuid)
        }
    }
}

extension StringProtocol {
    var hexData: Data { .init(hex) }
    var hexBytes: [UInt8] { .init(hex) }
    private var hex: UnfoldSequence<UInt8, Index> {
        sequence(state: startIndex) { startIndex in
            guard startIndex < self.endIndex else { return nil }
            let endIndex = self.index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            defer { startIndex = endIndex }
            return UInt8(self[startIndex..<endIndex], radix: 16)
        }
    }
}

extension DataProtocol {
    var data: Data { .init(self) }
    var hex: String { map { .init(format: "%02x", $0) }.joined() }
}
