// 
// Copyright 2023 New Vector Ltd
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
import CoreBluetooth

typealias DeviceUUID = String

class BLEState {
    private var centralManager: CBCentralManager
    private var queue = DispatchQueue(label: "ble.state.queue")
    private var clearCalled = false
    
    private var peripherals: [DeviceUUID: CBPeripheral] = [:]
    
    private var connecting: [DeviceUUID: Bool] = [:]
    private var connectingChannels: [DeviceUUID: CBL2CAPPSM] = [:]
    private var pineconePeers: [DeviceUUID: BLEPineconePeer] = [:]
    
    private var peripheralTimeouts: [DeviceUUID: Task<(), Never>] = [:]
    private let peripheralTimeoutMS: UInt64 = 10000
    
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
            clearCalled = false
        }
    }
    
    func clearDeviceState(_ device: DeviceUUID) {
        if clearCalled {
            MXLog.info("\(TAG): Already clearing state, ignoring call for \(device)")
            return
        }
        
        queue.sync {
            MXLog.info("\(TAG): Clearing state for \(device)")
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
        }
    }
    
    func isConnectingOrConnected(_ device: DeviceUUID, shouldLog: Bool = true) -> Bool {
        queue.sync {
            let connecting = connecting[device] != nil
            let connectingChannel = connectingChannels[device] != nil
            let peered = pineconePeers[device] != nil
            let connectingOrConnected = connecting || connectingChannel || peered
            
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
    
    func isConnected(_ device: DeviceUUID) -> Bool {
        queue.sync {
            let peered = pineconePeers[device] != nil
            let isConnected = peered
            
            MXLog.info("\(TAG): Is connected? \(device): \(isConnected)")
            return isConnected
        }
    }
    
    func addFoundPeripheral(_ device: DeviceUUID, _ peripheral: CBPeripheral) {
        queue.sync {
            MXLog.info("\(TAG): Adding peripheral for \(device)")
            peripherals[device] = peripheral
            connecting[device] = true
            restartTimer(device)
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
    
    private func restartTimer(_ device: DeviceUUID) {
        MXLog.info("\(TAG): Restarting timer for \(device)")
        if let timer = peripheralTimeouts[device] {
            timer.cancel()
        }
        peripheralTimeouts[device] = Task {
            do {
                // Task.sleep throws CancellationError if the task is cancelled
                try await Task.sleep(nanoseconds: self.peripheralTimeoutMS * 1000000)
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
        self.clearDeviceState(device)
    }
}
