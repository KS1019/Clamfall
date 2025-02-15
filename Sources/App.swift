import Observation
import SwiftUI
import LaunchAtLogin
import OSLog

@main
struct Clamfall: App {
    // @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @Environment(\.openWindow) var openWindow

    init() {
        Logger(.system).trace("init")
        Logger(.app).trace("observe")
        observe()
    }

    var body: some Scene {
        MenuBarExtra("", systemImage: "gear") {
            Button("設定") {
                openWindow(id: "settings")
//                NSApplication.shared.unhide(self)
//                if let wnd = NSApplication.shared.windows.first {
//                    wnd.makeKeyAndOrderFront(self)
//                    wnd.setIsVisible(true)
//                }
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
    }

    func observe() {
        Task {
            if isLidClosed() {
                Logger(.app).trace("Lid is closed. Trying to sleep machine")
                sleepMachine()
            }
            Logger(.app).trace("Will Task.sleep")
            try await Task.sleep(for: .seconds(2))
            Logger(.app).trace("Recursively call observe")
            observe()
        }
    }

    func isLidClosed() -> Bool {
        // Ref: https://stackoverflow.com/a/59447600
        let pipe = Pipe()
        let process = Process()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", "ioreg -r -k AppleClamshellState -d 4 | grep AppleClamshellState  | head -1"]
        process.standardOutput = pipe
        let fileHandle = pipe.fileHandleForReading
        process.launch()
        if(String(data: fileHandle.readDataToEndOfFile(), encoding: .utf8)?.contains("Yes") ?? false){
            return true
        }
        return false
    }

    func sleepMachine() {
        Logger(.app).debug("Sleeping Machine")

        // Ref: https://stackoverflow.com/a/77070339

        let pipe = Pipe()
        let process = Process()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", "pmset sleepnow"]
        process.standardOutput = pipe
        let fileHandle = pipe.fileHandleForReading
        process.launch()
    }

    var settingsWindow: some Scene {
        @Environment(\.openWindow) var openWindow

        return Window("設定", id: "settings") {
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
}
//
//@Observable
//final class AppDelegate: NSObject, NSApplicationDelegate {
//
//}
