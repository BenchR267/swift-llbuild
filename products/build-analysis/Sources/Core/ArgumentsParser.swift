// This source file is part of the Swift.org open source project
//
// Copyright 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

enum ParseError: Swift.Error {
    case cantParse(description: String)
    case cantFindOption(option: ArgumentsParser.Option, args: [String])
    case tooManyArguments(rest: [String])
}

public protocol OptionParseable {
    static func construct(from raw: String) throws -> Self
}

extension Int: OptionParseable {
    public static func construct(from raw: String) throws -> Int {
        guard let value = Int(raw) else { throw ParseError.cantParse(description: "Can't construct integer value from \(raw).") }
        return value
    }
}

extension String: OptionParseable {
    public static func construct(from raw: String) throws -> String { raw }
}

public final class ArgumentsParser {
    
    public struct Option {
        public enum Kind {
            case short(short: String)
            case long(long: String)
            case both(short: String, long: String)
        }
        
        public let name: String
        public let required: Bool
        public let kind: Kind
        public let type: OptionParseable.Type
        
        public init(name: String, required: Bool = false, kind: Kind, type: OptionParseable.Type) {
            self.name = name
            self.required = required
            self.kind = kind
            self.type = type
        }
    }
    
    public struct Values {
        private var storage: [String: Any] = [:]
        
        fileprivate mutating func insert(value: Any, for option: Option) {
            storage[option.name] = value
        }
        
        public subscript<T: OptionParseable>(_ option: Option) -> T {
            storage[option.name] as! T
        }
        
        public subscript<T: OptionParseable>(_ option: Option) -> T? {
            if option.required {
                return (storage[option.name] as! T)
            } else {
                return storage[option.name] as? T
            }
        }
    }
    
    public let options: [Option]
    
    public init(options: [Option]) {
        self.options = options
    }
    
    public func parse(args: [String]) throws -> Values {
        var argsCopy = args
        var results = Values()
        for option in options {
            let tryToFind: (inout [String], Option) throws -> Any? = { args, option in
                guard
                    let index = args.firstIndex(of: option.kind),
                    args.count > index + 1 else { return nil }
                let rawValue = args[index + 1]
                args.remove(at: index)
                args.remove(at: index)
                return try option.type.construct(from: rawValue)
            }
            
            if option.required {
                guard let value = try tryToFind(&argsCopy, option) else {
                    throw ParseError.cantFindOption(option: option, args: argsCopy)
                }
                results.insert(value: value, for: option)
            } else {
                if let value = try tryToFind(&argsCopy, option) {
                    results.insert(value: value, for: option)
                }
            }
        }
        guard argsCopy.isEmpty else {
            throw ParseError.tooManyArguments(rest: argsCopy)
        }
        return results
    }
}

private extension BidirectionalCollection where Element == String {
    func firstIndex(of kind: ArgumentsParser.Option.Kind) -> Self.Index? {
        switch kind {
        case let .short(short): return self.firstIndex(of: "-\(short)")
        case let .long(long): return self.firstIndex(of: "-\(long)")
        case let .both(short, long): return self.firstIndex(of: "-\(short)") ?? self.firstIndex(of: "--\(long)")
        }
    }
}
