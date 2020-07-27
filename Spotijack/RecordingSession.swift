//
//  ManagedMusicApplication.swift
//  Spotijack
//
//  Created by Alex Jackson on 27/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
import LibSpotijack
import AVFoundation

/// A `RecordingSession` manages launching a music application and its associated `SessionCoordinator`.
final class RecordingSession {

    struct Components {
        let musicApplication: MusicApplication
        let sessionCoordinator: SessionCoordinator
    }

    private var components: Components?

    func launch(_ applicationType: MusicApplication.Type) -> Command<Result<Components, Error>> {
        return Command.future { resolve in
            if let components = self.components {
                resolve(.success(components))
            } else {
                applicationType.launch { result in
                    switch result {
                    case .success(let app):
                        let sessionCoordinator = SessionCoordinator(musicApp: app)
                        let components = Components(musicApplication: app, sessionCoordinator: sessionCoordinator)
                        self.components = components
                        resolve(.success(components))
                    case .failure(let error):
                        resolve(.failure(error))
                    }
                }
            }
        }
    }

    func toggleRecording(using device: AVCaptureDevice) -> Command<Result<(), Error>> {
        guard let session = components?.sessionCoordinator else {
            return .none
        }

        switch session.state {
        case .startingRecording,
             .recording:
            return Command.fireAndForget {
                session.stopRecording()
            }

        case .endingRecording,
             .notRecording:
            return Command.catching {
                try session.startRecording(from: device)
            }
        }
    }

    func stopRecording() -> Command<Never> {
        guard let session = components?.sessionCoordinator else {
            return .none
        }

        return Command.fireAndForget {
            session.stopRecording()
        }
    }
}
