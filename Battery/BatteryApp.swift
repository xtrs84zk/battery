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
    var batteryMenu: NSMenu!
    var contextMenu: NSMenu!
    var hostingView: NSHostingView<BatteryPopoverView>!
    var loginMenuItem: NSMenuItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Primary Battery Sheet Menu (Left Click)
        batteryMenu = NSMenu()
        batteryMenu.delegate = self
        
        let batteryMenuItem = NSMenuItem()
        hostingView = NSHostingView(rootView: BatteryPopoverView(state: batteryState))
        hostingView.frame = NSRect(x: 0, y: 0, width: 240, height: 90)
        batteryMenuItem.view = hostingView
        batteryMenu.addItem(batteryMenuItem)
        
        // 2. Secondary Context Menu (Right Click)
        contextMenu = NSMenu()
        contextMenu.delegate = self
        
        loginMenuItem = NSMenuItem(title: "Start at Login", action: #selector(toggleStartAtLogin(_:)), keyEquivalent: "")
        loginMenuItem.target = self
        contextMenu.addItem(loginMenuItem)
        
        contextMenu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit Battery", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        contextMenu.addItem(quitItem)
        
        // 3. Setup Menu Bar Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Draw custom view inside the button
            let iconView = BatteryIconView(state: batteryState)
            let buttonHostingView = ClickThroughHostingView(rootView: iconView)
            
            // Widen the frame slightly to 42 so the animated coffee cup has room without clipping
            buttonHostingView.frame = NSRect(x: 0, y: 0, width: 42, height: 22)
            
            button.addSubview(buttonHostingView)
            button.frame = buttonHostingView.frame
            
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            loginMenuItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
            statusItem.popUpMenu(contextMenu)
        } else {
            let fitting = hostingView.fittingSize
            hostingView.frame = NSRect(x: 0, y: 0, width: 240, height: max(56, fitting.height))
            statusItem.popUpMenu(batteryMenu)
        }
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        if menu == batteryMenu {
            let fitting = hostingView.fittingSize
            hostingView.frame = NSRect(x: 0, y: 0, width: 240, height: max(56, fitting.height))
        } else if menu == contextMenu {
            loginMenuItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        }
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
