// This source file is part of the Swift.org open source project
//
// Copyright 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

import Core

public protocol OptionsType {
    init(values: ArgumentsParser.Values)
    static func makeParser() -> ArgumentsParser
}

public struct EmptyOptions: OptionsType {
    public init(values: ArgumentsParser.Values) {}
    public static func makeParser() -> ArgumentsParser {
        ArgumentsParser(options: [])
    }
}

public protocol Runnable: class {
    static var toolName: String { get }
    static var usage: String { get }
    init(args: [String]) throws
    func run() throws
}

public class Tool<O : OptionsType>: Runnable {
    public enum Error: Swift.Error {
        case usage(description: String)
    }
    
    public let options: O
    public class var toolName: String { preconditionFailure("`toolName` needs to be overriden by \(type(of: self)).") }
    public static var usage: String {
        let options = O.makeParser().options
        let optionsUsage = options.map { option -> String in
            let kindUsage: String
            switch option.kind {
            case let .short(short): kindUsage = "-\(short)"
            case let .long(long): kindUsage = "--\(long)"
            case let .both(short, long): kindUsage = "[-\(short)|--\(long)]"
            }
            
            return "\t\(kindUsage) \(option.name) (\(option.type)) \(option.required ? " [required]" : "")"
        }.joined(separator: "\n")
        
        return "\(CommandLine.arguments[0]) \(toolName) [options]\n\nwhere options are:\n\(optionsUsage)"
    }
    
    required public init(args: [String]) throws {
        do {
            let parser = O.makeParser()
            let values = try parser.parse(args: args)
            self.options = O.init(values: values)
        } catch {
            throw Error.usage(description: "Argument parsing failed: \(error)")
        }
    }
    
    public func run() throws {}
}
