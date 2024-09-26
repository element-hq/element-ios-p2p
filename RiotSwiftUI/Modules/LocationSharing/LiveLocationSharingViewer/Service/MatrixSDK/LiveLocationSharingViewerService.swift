// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import CoreLocation
import MatrixSDK

class LiveLocationSharingViewerService: LiveLocationSharingViewerServiceProtocol {
    
    // MARK: - Properties
    
    private(set) var usersLiveLocation: [UserLiveLocation] = []
    private let roomId: String
    private var beaconInfoSummaryListener: Any?
    
    // MARK: Private
    
    private let session: MXSession
    
    // MARK: Public
    
    var didUpdateUsersLiveLocation: (([UserLiveLocation]) -> Void)?
    
    // MARK: - Setup
    
    init(session: MXSession, roomId: String) {
        self.session = session
        self.roomId = roomId
        
        self.updateUsersLiveLocation(notifyUpdate: false)
    }
    
    // MARK: - Public
    
    func isCurrentUserId(_ userId: String) -> Bool {
        return self.session.myUserId == userId
    }
    
    func startListeningLiveLocationUpdates() {
        self.beaconInfoSummaryListener = self.session.aggregations.beaconAggregations.listenToBeaconInfoSummaryUpdateInRoom(withId: self.roomId) { [weak self] _ in

            self?.updateUsersLiveLocation(notifyUpdate: true)
        }
    }
    
    func stopListeningLiveLocationUpdates() {
        if let listener = beaconInfoSummaryListener {
            self.session.aggregations.removeListener(listener)
            self.beaconInfoSummaryListener = nil
        }
    }
    
    func stopUserLiveLocationSharing(completion: @escaping (Result<Void, Error>) -> Void) {
        self.session.locationService.stopUserLocationSharing(inRoomWithId: roomId) { response in
            
            switch response {
            case .success:
                completion(.success(Void()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Private
    
    private func updateUsersLiveLocation(notifyUpdate: Bool) {
        let beaconInfoSummaries = self.session.locationService.getDisplayableBeaconInfoSummaries(inRoomWithId: roomId)
        self.usersLiveLocation = Self.usersLiveLocation(fromBeaconInfoSummaries: beaconInfoSummaries, session: session)
        
        if notifyUpdate {
            self.didUpdateUsersLiveLocation?(self.usersLiveLocation)
        }
    }
    
    class private func usersLiveLocation(fromBeaconInfoSummaries beaconInfoSummaries: [MXBeaconInfoSummaryProtocol], session: MXSession) -> [UserLiveLocation] {
        
        return beaconInfoSummaries.compactMap { beaconInfoSummary in
            
            let beaconInfo = beaconInfoSummary.beaconInfo
            
            guard let lastBeacon = beaconInfoSummary.lastBeacon else {
                return nil
            }
            
            let avatarData = session.avatarInput(for: beaconInfoSummary.userId)
            
            let timestamp = TimeInterval(beaconInfo.timestamp/1000)
            let timeout = TimeInterval(beaconInfo.timeout/1000)
            let lastUpdate = TimeInterval(lastBeacon.timestamp/1000)
            
            let coordinate = CLLocationCoordinate2D(latitude: lastBeacon.location.latitude, longitude: lastBeacon.location.longitude)
            
            return UserLiveLocation(avatarData: avatarData,
                                    timestamp: timestamp,
                                    timeout: timeout,
                                    lastUpdate: lastUpdate,
                                    coordinate: coordinate)
        }
    }
}
