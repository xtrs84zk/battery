import SwiftUI
import AppKit

@main
struct BatteryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let batteryState = BatteryState()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            let iconView = BatteryIconView(state: batteryState)
            let hostingView = NSHostingView(rootView: iconView)
            
            // Adjust to proper size
            hostingView.frame = NSRect(x: 0, y: 0, width: 44, height: 22)
            button.addSubview(hostingView)
            
            // Allow the button to be clicked, but since we have a hosting view on top, we'll need to handle it or pass hits. Let's just set the frame.
            button.frame = hostingView.frame
        }
    }
}
