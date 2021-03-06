//
//  MIT License
//  Copyright (c) 2020-2021 Raycast. All rights reserved.
//

import Foundation
import TSCBasic

extension Toolkit {
  public func setScriptCommandsAsExecutable() throws {
    guard fileSystem.exists(extensionsAbsolutePath) else {
      throw Error.extensionsFolderNotFound(extensionsAbsolutePath.pathString)
    }

    var data = RaycastData()

    try readFolderContent(
      path: extensionsAbsolutePath,
      parentGroups: &data.groups,
      ignoreFilesInDir: true
    )

    var scriptCommands = ScriptCommands()

    data.groups.forEach { group in
      filter(
        for: group,
        leadingPath: group.path,
        scriptCommands: &scriptCommands
      )
    }

    let rawCount = scriptCommands.count
    var newModeCount = 0

    scriptCommands.sorted().forEach { scriptCommand in
      let filePath = extensionsAbsolutePath.appending(RelativePath(scriptCommand.fullPath))

      if let _ = try? fileSystem.chmod(.executable, path: filePath) {
        newModeCount += 1
      }
    }

    let console = Console(noColor: false)

    Toolkit.raycastDescription()

    if newModeCount > 0 {
      console.write("Result:", endLine: false)
      console.writeYellow(" \(newModeCount) ", bold: true, endLine: false)
      console.write("of", endLine: false)
      console.writeGreen(" \(rawCount) ", bold: true, endLine: false)
      console.write("Script Commands was set as \"executable\".")
    } else {
      console.write("✅ Nothing to be done.")
    }
  }
}

private extension Toolkit {
  func filter(for group: Group, leadingPath: String = .empty, scriptCommands: inout ScriptCommands) {
    if group.scriptCommands.isEmpty == false {
      for var scriptCommand in group.scriptCommands {
        scriptCommand.configure(leadingPath: leadingPath)

        if scriptCommand.isExecutable == false {
          scriptCommands.append(scriptCommand)
        }
      }
    }

    if let subGroups = group.subGroups {
      for subGroup in subGroups {
        filter(
          for: subGroup,
          leadingPath: "\(leadingPath)/\(subGroup.path)",
          scriptCommands: &scriptCommands
        )
      }
    }
  }
}
