// This source file is part of the Swift.org open source project
//
// Copyright 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

// The Swift package has llbuildSwift as module
#if SWIFT_PACKAGE
import llbuild
import llbuildSwift
#else
import llbuild
#endif

public final class CriticalBuildPathSolver {
    public struct Path {
        public struct Element {
            public let key: BuildKey
            public let result: RuleResult
        }
        public let duration: Double
        public let elements: [Element]
    }
    
    private let keyLookup: IdentifierFactory<BuildKey>
    private let rules: (BuildKey) -> RuleResult
    private let elements: [CriticalPath.Element]
    
    public init<C: Collection>(keys: C, ruleLookup: @escaping (BuildKey) -> RuleResult) where C.Element == BuildKey {
        let lookup = IdentifierFactory(keys)
        self.keyLookup = lookup
        let rules = memoize(ruleLookup)
        self.rules = rules
        self.elements = keys.map { key -> CriticalPath.Element in
            let identifier = lookup.identifier(element: key)
            let rule = rules(key)
            return .init(identifier: identifier,
                         weight: rule.duration,
                         dependencies: rule.dependencies.map(lookup.identifier(element:)))
        }
    }
    
    public func solve() -> Path {
        let path = calculateCriticalPath(self.elements)
        let elements = path.elements.map { element -> Path.Element in
            let key = self.keyLookup.element(id: element.identifier)
            return Path.Element(key: key, result: self.rules(key))
        }
        return Path(duration: path.weight, elements: elements)
    }
    
}
