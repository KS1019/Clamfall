import SwiftUI
import LaunchAtLogin
import OSLog
import Observation

@main
struct Clamfall: App {
    @Environment(\.openWindow) var openWindow
    @State var isMachineAwake = true

    init() {
        Logger(.system).trace("init")
        Logger(.app).trace("observe")
        observe()
    }

    var body: some Scene {
        MenuBarExtra("", systemImage: "gear") {
            Button("設定") {
                openWindow(id: "settings")
            }
            Divider()
            Button("再起動") {
                let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
                let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                task.arguments = [path]
                try! task.run()
                NSApplication.shared.terminate(self)
            }
            Button("終了") {
                NSApplication.shared.terminate(nil)
            }
        }
        settingsWindow
        licensesWindow
    }

    func observe() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        let willSleepNotification = notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { _ in
            isMachineAwake = false
        }
        let didWakeNotification = notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in
            isMachineAwake = true
        }

        defer {
            notificationCenter.removeObserver(willSleepNotification)
            notificationCenter.removeObserver(didWakeNotification)
        }

        Task {
            while true {
                if isMachineAwake {
                    if isLidClosed() {
                        Logger(.app).trace("Lid is closed. Trying to sleep machine")
                        sleepMachine()
                        try await Task.sleep(for: .seconds(60))
                    }
                    Logger(.app).trace("Will Task.sleep")
                    try await Task.sleep(for: .seconds(2))
                    Logger(.app).trace("Recursively call observe")
                } else {
                    Logger(.system).debug("Machine is not awake")
                }
            }
        }
    }

    func isLidClosed() -> Bool {
        // Ref: https://stackoverflow.com/a/59447600
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "ioreg -r -k AppleClamshellState -d 4 | grep AppleClamshellState  | head -1"]
        process.standardOutput = pipe
        let fileHandle = pipe.fileHandleForReading
        do {
            try process.run()
            if String(data: fileHandle.readDataToEndOfFile(), encoding: .utf8)?.contains("Yes") ?? false {
                return true
            }
        } catch {
            Logger(.system).error("ioreg failed. Reason: \(error, privacy: .public)")
        }

        return false
    }

    func sleepMachine() {
        Logger(.app).debug("==============================\nSleeping Machine")
        do {
            // Ref: https://stackoverflow.com/a/77070339
            try Process.run(URL(fileURLWithPath: "/usr/bin/pmset"), arguments: ["sleepnow"])
        } catch {
            Logger(.system).error("pmset failed. Reason: \(error, privacy: .public)")
        }
        Logger(.app).debug("==============================")
    }

    var settingsWindow: some Scene {
        Window("設定", id: "settings") {
            @Environment(\.openWindow) var openWindow
            Form {
                Section("設定") {
                    HStack {
                        LaunchAtLogin.Toggle("ログイン時に起動")
                            .toggleStyle(.switch)
                    }
                    HStack {
                        Text("Ver ") + Text((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "?.?.?")
                    }
                    HStack {
                        Link("Webサイト", destination: URL(string: "https://github.com/KS1019/Clamfall")!)
                    }
                    HStack {
                        Button("ライセンス") {
                            openWindow(id: "licenses")
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .frame(width: 250, height: 250, alignment: .center)
            .toolbarBackground(Color.clear)
            .scrollDisabled(true)
        }
        .windowResizability(.contentSize)
    }

    var licensesWindow: some Scene {
        Window("ライセンス", id: "licenses") {
            Form {
                Section("LaunchAtLogin-Modern") {
                    Text("""
                    MIT License

                    Copyright (c) Sindre Sorhus <sindresorhus@gmail.com> (https://sindresorhus.com)

                    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

                    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

                    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                    """)
                }
            }
            .formStyle(.grouped)
            .padding()
            .toolbarBackground(Color.clear)
        }
    }
}
