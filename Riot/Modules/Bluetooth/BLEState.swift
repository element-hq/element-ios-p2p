// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import CoreBluetooth

typealias DeviceUUID = String
typealias PublicKey = String

class BLEState {
    private var centralManager: CBCentralManager
    private var queue = DispatchQueue(label: "ble.state.queue")
    private var clearCalled = false
    
    private var peripherals: [DeviceUUID: CBPeripheral] = [:]
    
    private var connecting: [DeviceUUID: Bool] = [:]
    private var connectingChannels: [DeviceUUID: CBL2CAPPSM] = [:]
    private var pineconePeers: [DeviceUUID: BLEPineconePeer] = [:]
    
    private var devicesForKey: [PublicKey: [DeviceUUID]] = [:]
    private var devicePublicKey: [DeviceUUID: PublicKey] = [:]
    
    private var peripheralTimeouts: [DeviceUUID: Task<(), Never>] = [:]
    private static let peripheralTimeoutMS: UInt64 = 10000
    private static let connectTimeoutMS: UInt64 = 15000
    
    private let TAG = "Dendrite - BLEState"
    
    init(_ centralManager: CBCentralManager) {
        self.centralManager = centralManager
    }
    
    func clear() {
        queue.sync {
            clearCalled = true
            MXLog.info("\(TAG): Clearing all state")
            peripheralTimeouts.forEach { (device, timer) in
                timer.cancel()
            }
            pineconePeers.forEach { (device, peer) in
                if peer.isOpen() {
                    peer.close()
                }
            }
            peripherals.forEach { (device, peripheral) in
                if centralManager.state == .poweredOn {
                    centralManager.cancelPeripheralConnection(peripheral)
                }
            }
            
            peripherals.removeAll()
            peripheralTimeouts.removeAll()
            connecting.removeAll()
            connectingChannels.removeAll()
            pineconePeers.removeAll()
            devicesForKey.removeAll()
            devicePublicKey.removeAll()
            clearCalled = false
        }
    }
    
    func clearAllDeviceState(_ device: DeviceUUID) {
        if clearCalled {
            MXLog.info("\(TAG): Already clearing state, ignoring call for \(device)")
            return
        }
        
        queue.sync {
            MXLog.info("\(TAG): Clearing all state for \(device)")
            if let timer = peripheralTimeouts[device] {
                timer.cancel()
            }
            if let peer = pineconePeers[device] {
                if peer.isOpen() {
                    peer.close()
                }
            }
            if let peripheral = peripherals[device] {
                if centralManager.state == .poweredOn {
                    centralManager.cancelPeripheralConnection(peripheral)
                }
            }
            
            peripherals.removeValue(forKey: device)
            peripheralTimeouts.removeValue(forKey: device)
            connecting.removeValue(forKey: device)
            connectingChannels.removeValue(forKey: device)
            pineconePeers.removeValue(forKey: device)
            if let key = devicePublicKey[device] {
                devicesForKey.removeValue(forKey: key)
            }
            devicePublicKey.removeValue(forKey: device)
        }
    }
    
    // Used after detecting a new UUID for an already connected public key.
    func clearDeviceConnectingState(_ device: DeviceUUID) {
        queue.sync {
            MXLog.info("\(TAG): Clearing connecting state for \(device)")
            if let timer = peripheralTimeouts[device] {
                timer.cancel()
            }
            
            peripherals.removeValue(forKey: device)
            peripheralTimeouts.removeValue(forKey: device)
            connecting.removeValue(forKey: device)
            connectingChannels.removeValue(forKey: device)
        }
    }
    
    func isConnectingOrConnected(_ device: DeviceUUID, shouldLog: Bool = true) -> Bool {
        queue.sync {
            let connecting = connecting[device] != nil
            let connectingChannel = connectingChannels[device] != nil
            let peered = pineconePeers[device] != nil
            let knownDevice = devicePublicKey[device] != nil
            let connectingOrConnected = connecting || connectingChannel || peered || knownDevice
            
            if shouldLog {
                MXLog.info("\(TAG): Is connecting or connected? \(device): \(connectingOrConnected)")
            }
            return connectingOrConnected
        }
    }
    
    func isConnecting(_ device: DeviceUUID) -> Bool {
        queue.sync {
            let connecting = connecting[device] != nil
            let connectingChannel = connectingChannels[device] != nil
            let isConnecting = connecting || connectingChannel
            
            MXLog.info("\(TAG): Is connecting? \(device): \(isConnecting)")
            return isConnecting
        }
    }
    
    func isConnectedDevice(_ device: DeviceUUID) -> Bool {
        queue.sync {
            let peered = pineconePeers[device] != nil
            let isConnected = peered
            
            MXLog.info("\(TAG): Is connected device? \(device): \(isConnected)")
            return isConnected
        }
    }
    
    func isConnectedKey(_ key: PublicKey) -> Bool {
        queue.sync {
            let isConnected = devicesForKey[key] != nil
            
            MXLog.info("\(TAG): Is connected key? \(key): \(isConnected)")
            return isConnected
        }
    }
    
    func registerDevice(_ device: DeviceUUID, _ key: PublicKey) {
        queue.sync {
            MXLog.info("\(TAG): Registering key for device \(device): \(key)")
            
            devicePublicKey[device] = key
            if devicesForKey[key] == nil {
                devicesForKey[key] = []
            }
            devicesForKey[key]?.append(device)
        }
    }
    
    func addFoundPeripheral(_ device: DeviceUUID, _ peripheral: CBPeripheral) {
        queue.sync {
            MXLog.info("\(TAG): Adding peripheral for \(device)")
            peripherals[device] = peripheral
            connecting[device] = true
            restartTimer(device, timeoutMS: BLEState.connectTimeoutMS)
        }
    }
    
    func addConnectingChannel(_ device: DeviceUUID, _ psm: CBL2CAPPSM) {
        queue.sync {
            MXLog.info("\(TAG): Adding connecting channel for \(device): \(psm)")
            connectingChannels[device] = psm
            restartTimer(device)
        }
    }
    
    func addPineconePeer(_ device: DeviceUUID, _ peer: BLEPineconePeer) {
        queue.sync {
            MXLog.info("\(TAG): Adding pinecone peer for \(device)")
            pineconePeers[device] = peer
            stopTimer(device)
        }
    }
    
    func stopTimer(_ device: DeviceUUID) {
        MXLog.info("\(TAG): Stopping timer for \(device)")
        if let timer = peripheralTimeouts[device] {
            timer.cancel()
        }
        peripheralTimeouts.removeValue(forKey: device)
    }
    
    private func restartTimer(_ device: DeviceUUID, timeoutMS: UInt64 = BLEState.peripheralTimeoutMS) {
        MXLog.info("\(TAG): Restarting timer for \(device)")
        if let timer = peripheralTimeouts[device] {
            timer.cancel()
        }
        peripheralTimeouts[device] = Task {
            do {
                // Task.sleep throws CancellationError if the task is cancelled
                try await Task.sleep(nanoseconds: timeoutMS * 1000000)
            } catch {}
            if Task.isCancelled {
                MXLog.info("\(TAG): Timer stopped for \(device)")
                return
            }
            self.handlePeripheralTimeout(device)
        }
    }
    
    private func handlePeripheralTimeout(_ device: DeviceUUID) {
        MXLog.warning("\(TAG): Peripheral connection timed out \(device)")
        self.clearAllDeviceState(device)
    }
}
