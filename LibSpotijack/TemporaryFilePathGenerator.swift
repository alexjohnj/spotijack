//
//  TemporaryFilePathGenerator.swift
//  LibSpotijack
//
//  Created by Alex Jackson on 05/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation

struct TemporaryFilePathGenerator {

    private let body: () throws -> URL

    init(_ body: @escaping () throws -> URL ) {
        self.body = body
    }

    func generateFilePath() throws -> URL {
        return try body()
    }
}

extension TemporaryFilePathGenerator {

    static let `default` = TemporaryFilePathGenerator {
        return FileManager.default
            .temporaryDirectory
            .appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: false)
    }

}
