// 
// Copyright 2022 New Vector Ltd
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
import MatrixSDK

struct AuthenticationState {
    // var serverType: ServerType = .unknown
    var flow: AuthenticationFlow
    
    /// Information about the currently selected homeserver.
    var homeserver: Homeserver
    var isForceLoginFallbackEnabled = false
    
    init(flow: AuthenticationFlow, homeserverAddress: String) {
        self.flow = flow
        self.homeserver = Homeserver(address: homeserverAddress)
    }
    
    init(flow: AuthenticationFlow, homeserver: Homeserver) {
        self.flow = flow
        self.homeserver = homeserver
    }
    
    struct Homeserver {
        /// The homeserver address as returned by the server.
        var address: String
        /// The homeserver address as input by the user (it can differ to the well-known request).
        var addressFromUser: String?
        /// The homeserver's address formatted to be displayed to the user in labels, text fields etc.
        var displayableAddress: String {
            let address = addressFromUser ?? address
            return address.replacingOccurrences(of: "https://", with: "") // Only remove https. Leave http to indicate the server doesn't use SSL.
        }
        
        /// The preferred login mode for the server
        var preferredLoginMode: LoginMode = .unknown
        
        /// The response returned when querying the homeserver for registration flows.
        var registrationFlow: RegistrationResult?
        
        /// Whether or not the homeserver is for matrix.org.
        var isMatrixDotOrg: Bool {
            guard let url = URL(string: address) else { return false }
            return url.host == "matrix.org" || url.host == "matrix-client.matrix.org"
        }
        
        var viewData: AuthenticationHomeserverViewData {
            AuthenticationHomeserverViewData(address: displayableAddress,
                                             isMatrixDotOrg: isMatrixDotOrg,
                                             showLoginForm: preferredLoginMode.supportsPasswordFlow,
                                             showRegistrationForm: registrationFlow != nil,
                                             ssoIdentityProviders: preferredLoginMode.ssoIdentityProviders ?? [])
        }
    }
}
