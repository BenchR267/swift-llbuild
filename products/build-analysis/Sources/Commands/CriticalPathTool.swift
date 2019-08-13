// This source file is part of the Swift.org open source project
//
// Copyright 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

import Core
import CriticalPath

public final class CriticalPathTool: Tool<CriticalPathTool.Options> {
    public struct Options: OptionsType {
        let databasePath: String
        
        private enum O {
            static let pathOption = ArgumentsParser.Option(name: "databasePath", required: true, kind: .both(short: "p", long: "path"), type: String.self)
        }
        
        public static func makeParser() -> ArgumentsParser {
            ArgumentsParser(options: [
                O.pathOption
            ])
        }
        
        public init(values: ArgumentsParser.Values) {
            self.databasePath = values[O.pathOption]
        }
    }
    
    override public class var toolName: String { "critical-path" }
    
    public override func run() throws {
        let path = try findCriticalPath(databasePath: options.databasePath, clientSchemaVersion: 9)
        print("Critical Path:\n", path)
    }
}
