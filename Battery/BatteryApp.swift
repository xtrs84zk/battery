import SwiftUI
import AppKit
import ServiceManagement

@main
struct BatteryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class ClickThroughHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    let batteryState = BatteryState()
    var statusMenu: NSMenu!
    var hostingView: NSHostingView<BatteryPopoverView>!
    var loginMenuItem: NSMenuItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup Native Menu (Matching system menu sheets like Image 1)
        statusMenu = NSMenu()
        statusMenu.delegate = self
        
        // Custom View for Battery info
        let batteryMenuItem = NSMenuItem()
        hostingView = NSHostingView(rootView: BatteryPopoverView(state: batteryState))
        hostingView.frame = NSRect(x: 0, y: 0, width: 240, height: 90)
        batteryMenuItem.view = hostingView
        statusMenu.addItem(batteryMenuItem)
        
        statusMenu.addItem(NSMenuItem.separator())
        
        // Start at Login item
        loginMenuItem = NSMenuItem(title: "Start at Login", action: #selector(toggleStartAtLogin(_:)), keyEquivalent: "")
        loginMenuItem.target = self
        statusMenu.addItem(loginMenuItem)
        
        // Quit item
        let quitItem = NSMenuItem(title: "Quit Battery", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusMenu.addItem(quitItem)
        
        // Setup Menu Bar Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.menu = statusMenu
        
        if let button = statusItem.button {
            // Draw custom view inside the button
            let iconView = BatteryIconView(state: batteryState)
            let buttonHostingView = ClickThroughHostingView(rootView: iconView)
            
            // Widen the frame slightly to 42 so the animated coffee cup has room without clipping
            buttonHostingView.frame = NSRect(x: 0, y: 0, width: 42, height: 22)
            
            button.addSubview(buttonHostingView)
            button.frame = buttonHostingView.frame
        }
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        loginMenuItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        
        // Dynamically fit height based on whether "Calculating..." or normal view is shown
        let fitting = hostingView.fittingSize
        hostingView.frame = NSRect(x: 0, y: 0, width: 240, height: max(60, fitting.height))
    }
    
    @objc func toggleStartAtLogin(_ sender: AnyObject?) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
            loginMenuItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        } catch {
            print("Failed to toggle start at login: \(error)")
        }
    }
}
