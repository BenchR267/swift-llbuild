// This source file is part of the Swift.org open source project
//
// Copyright 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

import Commands

func run(using commands: [Runnable.Type]) -> Int32 {
    var args = Array(CommandLine.arguments.dropFirst())
    guard let toolName = args.first else {
        print("No command found.")
        printUsage()
        return -1
    }
    args.removeFirst()
    
    guard let command = command(for: toolName) else {
        print("Unknown command: \(toolName)")
        printUsage()
        return -1
    }
    
    let tool: Runnable
    do {
        tool = try command.init(args: args)
    } catch {
        printUsage(command: command)
        return -1
    }
    
    do {
        try tool.run()
    } catch {
        print("error: ", error)
        return -1
    }
    
    return 0
}

private func command(for toolName: String) -> Runnable.Type? {
    commands.first(where: { $0.toolName == toolName })
}

private func printUsage(command: Runnable.Type? = nil) {
    if let command = command {
        print(command.usage)
        return
    }
    print("""
        \(CommandLine.arguments[0]) [command] options
        
        where command can be one of [\(commands.map({ $0.toolName }).joined(separator: ", "))]
        """)
}
