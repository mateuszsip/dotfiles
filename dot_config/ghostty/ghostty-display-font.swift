// Writes the Ghostty font-size drop-in (~/.config/ghostty/display.conf) for the
// current monitor setup: 14pt on the built-in panel alone, 16pt when an
// external monitor is connected. macOS counterpart to
// hypr/scripts/ghostty-font-{monitor,size}.sh on Linux.
//
// Runs as a KeepAlive LaunchAgent (see
// run_onchange_after_install-ghostty-display-font.sh.tmpl) and reacts to
// CoreGraphics display reconfiguration events, so no polling. New Ghostty
// windows pick the drop-in up automatically; already-open ones refresh with
// cmd+shift+, (reload_config).
//
// Compiled with swiftc at chezmoi-apply time — no third-party dependencies.

import CoreGraphics
import Foundation

let internalPt = 14  // built-in Retina panel
let externalPt = 16  // external monitor (typically 1x, so 14pt renders tiny)
let dropIn = ("~/.config/ghostty/display.conf" as NSString).expandingTildeInPath

func desiredFontSize() -> Int {
    var count: UInt32 = 0
    guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else {
        return internalPt
    }
    var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
    guard CGGetActiveDisplayList(count, &ids, &count) == .success else {
        return internalPt
    }
    let hasExternal = ids.prefix(Int(count)).contains { CGDisplayIsBuiltin($0) == 0 }
    return hasExternal ? externalPt : internalPt
}

func apply() {
    let line = "font-size = \(desiredFontSize())\n"
    if let current = try? String(contentsOfFile: dropIn, encoding: .utf8), current == line {
        return
    }
    let dir = (dropIn as NSString).deletingLastPathComponent
    try? FileManager.default.createDirectory(
        atPath: dir, withIntermediateDirectories: true)
    try? line.write(toFile: dropIn, atomically: true, encoding: .utf8)
}

// A single plug/unplug fires several callbacks (one per affected display, plus
// begin/complete pairs); coalesce them into one write.
var pending: DispatchWorkItem?

func scheduleApply() {
    pending?.cancel()
    let item = DispatchWorkItem(block: apply)
    pending = item
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: item)
}

apply()

CGDisplayRegisterReconfigurationCallback(
    { _, flags, _ in
        // The begin phase reports the pre-change layout; wait for the result.
        if flags.contains(.beginConfigurationFlag) { return }
        scheduleApply()
    }, nil)

CFRunLoopRun()
