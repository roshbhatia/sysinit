import AppKit
import CoreServices
import Foundation
import UniformTypeIdentifiers

let bundleIdentifier = "@BUNDLE_ID@"
let extensions = "@EXTENSIONS@".split(separator: " ").map(String.init)

if CommandLine.arguments.contains("--set-defaults") {
  for ext in extensions {
    guard let type = UTType(filenameExtension: ext) else {
      fputs("sysinit file opener: no content type for .\(ext)\n", stderr)
      continue
    }
    let status = LSSetDefaultRoleHandlerForContentType(
      type.identifier as CFString,
      LSRolesMask.editor,
      bundleIdentifier as CFString
    )
    guard status == noErr else {
      fputs("sysinit file opener: failed to set .\(ext): \(status)\n", stderr)
      exit(1)
    }
  }

  for ext in ["xcodeproj", "xcworkspace", "swift"] {
    guard let type = UTType(filenameExtension: ext) else { continue }
    let status = LSSetDefaultRoleHandlerForContentType(
      type.identifier as CFString,
      LSRolesMask.editor,
      "com.apple.dt.xcode" as CFString
    )
    guard status == noErr else {
      fputs("sysinit file opener: failed to set .\(ext) to Xcode: \(status)\n", stderr)
      exit(1)
    }
  }

  if let goType = UTType(filenameExtension: "go") {
    let completed = DispatchSemaphore(value: 0)
    NSWorkspace.shared.setDefaultApplication(at: Bundle.main.bundleURL, toOpen: goType) { error in
      if let error {
        fputs("sysinit file opener: failed to set .go: \(error.localizedDescription)\n", stderr)
        exit(1)
      }
      completed.signal()
    }
    let deadline = Date().addingTimeInterval(30)
    while completed.wait(timeout: .now()) == .timedOut {
      guard Date() < deadline else {
        fputs("sysinit file opener: timed out setting .go handler\n", stderr)
        exit(1)
      }
      RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }
  }

  let mailtoStatus = LSSetDefaultHandlerForURLScheme(
    "mailto" as CFString,
    "org.mozilla.firefox" as CFString
  )
  guard mailtoStatus == noErr else {
    fputs("sysinit file opener: failed to set mailto to Firefox: \(mailtoStatus)\n", stderr)
    exit(1)
  }

  let mailClientStatus = LSSetDefaultRoleHandlerForContentType(
    "com.apple.default-app.mail-client" as CFString,
    LSRolesMask.all,
    "org.mozilla.firefox" as CFString
  )
  guard mailClientStatus == noErr else {
    fputs("sysinit file opener: failed to set the default mail client: \(mailClientStatus)\n", stderr)
    exit(1)
  }

  exit(0)
}

final class AppDelegate: NSObject, NSApplicationDelegate {
  func application(_ sender: NSApplication, openFiles filenames: [String]) {
    guard let first = filenames.first else {
      sender.reply(toOpenOrPrint: .failure)
      sender.terminate(nil)
      return
    }

    let workingDirectory = URL(fileURLWithPath: first).deletingLastPathComponent().path
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "@WEZTERM@")
    process.arguments = [
      "start",
      "--new-tab",
      "--cwd",
      workingDirectory,
      "--",
      "@NVIM@",
      "--",
    ] + filenames

    do {
      try process.run()
      sender.reply(toOpenOrPrint: .success)
    } catch {
      fputs("sysinit file opener: \(error.localizedDescription)\n", stderr)
      sender.reply(toOpenOrPrint: .failure)
    }
    sender.terminate(nil)
  }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.accessory)
application.run()
