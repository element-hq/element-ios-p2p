/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
*/

import Foundation
import KeychainAccess
import LocalAuthentication
import MatrixSDK

/// Pin code preferences.
@objcMembers
final class PinCodePreferences: NSObject {
    
    // MARK: - Constants
    
    private struct PinConstants {
        static let pinCodeKeychainService: String = BuildSettings.baseBundleIdentifier + ".pin-service"
    }
    
    private struct StoreKeys {
        static let pin: String = "pin"
        static let biometricsEnabled: String = "biometricsEnabled"
        static let canUseBiometricsToUnlock: String = "canUseBiometricsToUnlock"
        static let numberOfPinFailures: String = "numberOfPinFailures"
        static let numberOfBiometricsFailures: String = "numberOfBiometricsFailures"
    }
    
    static let shared = PinCodePreferences()
    
    /// Store. Defaults to `KeychainStore`
    private let store: KeyValueStore
    
    override private init() {
        store = KeychainStore(withKeychain: Keychain(service: PinConstants.pinCodeKeychainService,
                                                     accessGroup: BuildSettings.keychainAccessGroup))
        super.init()
    }
    
    // MARK: - Public
    
    /// Setting to force protection by pin code
    var forcePinProtection: Bool {
        return BuildSettings.forcePinProtection
    }
    
    /// Not allowed pin codes. User won't be able to select one of the pin in the list.
    var notAllowedPINs: [String] {
        return BuildSettings.notAllowedPINs
    }
    
    /// Maximum number of allowed pin failures when unlocking, before force logging out the user
    var maxAllowedNumberOfPinFailures: Int {
        return BuildSettings.maxAllowedNumberOfPinFailures
    }
    
    /// Maximum number of allowed biometrics failures when unlocking, before fallbacking the user to the pin
    var maxAllowedNumberOfBiometricsFailures: Int {
        return BuildSettings.maxAllowedNumberOfBiometricsFailures
    }
    
    var isBiometricsAvailable: Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    /// Allowed number of PIN trials before showing forgot help alert
    let allowedNumberOfTrialsBeforeAlert: Int = 5
    
    /// Max allowed time to continue using the app without prompting PIN
    var graceTimeInSeconds: TimeInterval {
        return BuildSettings.pinCodeGraceTimeInSeconds
    }
    
    /// Number of digits for the PIN
    let numberOfDigits: Int = 4
    
    /// Is user has set a pin
    var isPinSet: Bool {
        return pin != nil
    }
    
    /// Saved user PIN
    var pin: String? {
        get {
            do {
                return try store.string(forKey: StoreKeys.pin)
            } catch let error {
                MXLog.debug("[PinCodePreferences] Error when reading user pin from store: \(error)")
                return nil
            }
        } set {
            do {
                try store.set(newValue, forKey: StoreKeys.pin)
            } catch let error {
                MXLog.debug("[PinCodePreferences] Error when storing user pin to the store: \(error)")
            }
        }
    }
    
    var biometricsEnabled: Bool? {
        get {
            do {
                return try store.bool(forKey: StoreKeys.biometricsEnabled)
            } catch let error {
                MXLog.debug("[PinCodePreferences] Error when reading biometrics enabled from store: \(error)")
                return nil
            }
        } set {
            do {
                try store.set(newValue, forKey: StoreKeys.biometricsEnabled)
            } catch let error {
                MXLog.debug("[PinCodePreferences] Error when storing biometrics enabled to the store: \(error)")
            }
        }
    }
    
    var canUseBiometricsToUnlock: Bool? {
        get {
            guard isBiometricsAvailable == true else {
                return false
            }
            
            do {
                return try store.bool(forKey: StoreKeys.canUseBiometricsToUnlock)
            } catch let error {
                MXLog.debug("[PinCodePreferences] Error when reading canUseBiometricsToUnlock from store: \(error)")
                return nil
            }
        } set {
            do {
                try store.set(newValue, forKey: StoreKeys.canUseBiometricsToUnlock)
            } catch let error {
                MXLog.debug("[PinCodePreferences] Error when storing canUseBiometricsToUnlock to the store: \(error)")
            }
        }
    }
    
    var numberOfPinFailures: Int {
        get {
            do {
                return try store.integer(forKey: StoreKeys.numberOfPinFailures) ?? 0
            } catch let error {
                MXLog.debug("[PinCodePreferences] Error when reading numberOfPinFailures from store: \(error)")
                return 0
            }
        } set {
            do {
                try store.set(newValue, forKey: StoreKeys.numberOfPinFailures)
            } catch let error {
                MXLog.debug("[PinCodePreferences] Error when storing numberOfPinFailures to the store: \(error)")
            }
        }
    }
    
    var numberOfBiometricsFailures: Int {
        get {
            do {
                return try store.integer(forKey: StoreKeys.numberOfBiometricsFailures) ?? 0
            } catch let error {
                MXLog.debug("[PinCodePreferences] Error when reading numberOfBiometricsFailures from store: \(error)")
                return 0
            }
        } set {
            do {
                try store.set(newValue, forKey: StoreKeys.numberOfBiometricsFailures)
            } catch let error {
                MXLog.debug("[PinCodePreferences] Error when storing numberOfBiometricsFailures to the store: \(error)")
            }
        }
    }
    
    var isBiometricsSet: Bool {
        return biometricsEnabled == true && (canUseBiometricsToUnlock ?? true)
    }
    
    func localizedBiometricsName() -> String? {
        if isBiometricsAvailable {
            let context = LAContext()
            //  canEvaluatePolicy should be called for biometryType to be set
            _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            switch context.biometryType {
            case .touchID:
                return VectorL10n.biometricsModeTouchId
            case .faceID:
                return VectorL10n.biometricsModeFaceId
            default:
                return nil
            }
        }
        return nil
    }
    
    func biometricsIcon() -> UIImage? {
        if isBiometricsAvailable {
            let context = LAContext()
            //  canEvaluatePolicy should be called for biometryType to be set
            _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            switch context.biometryType {
            case .touchID:
                return Asset.Images.touchidIcon.image
            case .faceID:
                return Asset.Images.faceidIcon.image
            default:
                return nil
            }
        }
        return nil
    }
    
    /// Resets user PIN
    func reset() {
        pin = nil
        biometricsEnabled = nil
        canUseBiometricsToUnlock = nil
        resetCounters()
    }
    
    /// Reset number of failures for both pin and biometrics
    func resetCounters() {
        numberOfPinFailures = 0
        numberOfBiometricsFailures = 0
    }
}
