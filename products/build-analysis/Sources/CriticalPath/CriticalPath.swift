// This source file is part of the Swift.org open source project
//
// Copyright 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

import llbuildSwift

public func findCriticalPath(databasePath: String, clientSchemaVersion: UInt32) throws -> CriticalPath {
    let database = try BuildDB(path: databasePath, clientSchemaVersion: clientSchemaVersion)
    let keys = try database.getKeys()
    let solver = CriticalPathSolver(keys: Array(keys), ruleResultLookup: database.lookupRuleResult(buildKey:))
    return try solver.run()
}
