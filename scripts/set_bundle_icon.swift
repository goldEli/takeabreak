#!/usr/bin/swift

import AppKit
import Foundation

let arguments = CommandLine.arguments

guard arguments.count == 3 else {
    fputs("Usage: set_bundle_icon.swift <app-bundle-path> <icon-png-path>\n", stderr)
    exit(1)
}

let bundlePath = arguments[1]
let iconPath = arguments[2]

guard let image = NSImage(contentsOfFile: iconPath) else {
    fputs("Failed to load icon image at \(iconPath)\n", stderr)
    exit(1)
}

let success = NSWorkspace.shared.setIcon(image, forFile: bundlePath, options: [])
if !success {
    fputs("Failed to apply bundle icon to \(bundlePath)\n", stderr)
    exit(1)
}
