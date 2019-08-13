// This source file is part of the Swift.org open source project
//
// Copyright 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

import llbuildSwift
import class Foundation.NumberFormatter

public final class CriticalPath: CustomStringConvertible {
    public let key: BuildKey
    public let result: RuleResult
    public let cost: Double
    public let next: CriticalPath?
    private let end: Double
    
    fileprivate init(key: BuildKey, result: RuleResult, cost: Double, next: CriticalPath?) {
        self.key = key
        self.result = result
        self.cost = cost
        self.end = next?.end ?? result.end
        self.next = next
    }
    
    fileprivate func adding(cost: Double = 0, end: CriticalPath? = nil) -> CriticalPath {
        let next = end.flatMap { self.next?.adding(end: $0) } ?? end
        return CriticalPath(key: key, result: result, cost: cost + self.cost, next: next)
    }
    
    public var description: String {
        let cost = String(format: "%.3f", self.cost)
        return "Path (cost: \(cost)sec):\n" + map({ "\t\($0.key)" }).joined(separator: " → \n")
    }
}

extension CriticalPath: Sequence {
    public func makeIterator() -> AnyIterator<(key: BuildKey, result: RuleResult)> {
        var current: CriticalPath? = self
        return AnyIterator {
            defer { current = current?.next }
            return current.map { ($0.key, $0.result) }
        }
    }
}

public final class CriticalPathSolver {
    public enum Error: Swift.Error {
        case noResultGiven(key: BuildKey)
    }
    
    public let keys: [BuildKey]
    let ruleResultLookup: (BuildKey) throws -> RuleResult?
    private var resultCache: [BuildKey: RuleResult]
    private var pathCache: [BuildKey: CriticalPath]
    
    public init(keys: [BuildKey], ruleResultLookup: @escaping (BuildKey) throws -> RuleResult?) {
        self.keys = keys
        self.ruleResultLookup = ruleResultLookup
        self.resultCache = .init(minimumCapacity: keys.count)
        self.pathCache = .init(minimumCapacity: keys.count)
    }
    
    private func result(for key: BuildKey) throws -> RuleResult {
        if let cached = self.resultCache[key] { return cached }
        guard let lookup = try self.ruleResultLookup(key) else {
            throw Error.noResultGiven(key: key)
        }
        self.resultCache[key] = lookup
        return lookup
    }
    
    private func path(for key: BuildKey) throws -> CriticalPath {
        if let cached = self.pathCache[key] {
            return cached
        }
        
        func calculatePath(key: BuildKey, end: CriticalPath? = nil, cost: Double = 0) throws -> CriticalPath {
            if let cached = self.pathCache[key] {
                return cached.adding(cost: cost, end: end)
            }
            let result = try self.result(for: key)
            let deps = Set(result.dependencies)
            let path = CriticalPath(key: key, result: result, cost: cost + result.duration, next: end)
            if deps.isEmpty {
                self.pathCache[key] = path
                return path
            }
            
            assert(!deps.contains(key))
            
            let maxPath = try deps
                .lazy
                .map { try calculatePath(key: $0, end: path, cost: path.cost) }
                .max(by: { $0.cost < $1.cost })!
            let newPath = maxPath
            self.pathCache[key] = newPath
            return newPath
        }
        
        return try calculatePath(key: key)
    }
    
    public func run() throws -> CriticalPath {
        let paths = try keys.map(self.path(for:))
        return paths.max(by: { $0.cost < $1.cost })!
    }
}
