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

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let batteryState = BatteryState()
    var popover: NSPopover!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup Popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 240, height: 120)
        popover.behavior = .transient
        // Using NSHostingController to wrap the popover view
        popover.contentViewController = NSHostingController(rootView: BatteryPopoverView(state: batteryState))
        
        // Setup Menu Bar Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Draw custom view inside the button
            let iconView = BatteryIconView(state: batteryState)
            let hostingView = ClickThroughHostingView(rootView: iconView)
            
            // Widen the frame slightly to 42 so the animated coffee cup has room without clipping
            hostingView.frame = NSRect(x: 0, y: 0, width: 42, height: 22)
            
            button.addSubview(hostingView)
            button.frame = hostingView.frame
            
            // Define click action
            button.action = #selector(togglePopover(_:))
            button.target = self
            
            // Allow both normal left clicks and right clicks (for context menu)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc func toggleStartAtLogin(_ sender: AnyObject?) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("Failed to toggle start at login: \(error)")
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            let menu = NSMenu()
            
            // Start at login toggle
            let loginItem = NSMenuItem(title: "Start at Login", action: #selector(toggleStartAtLogin(_:)), keyEquivalent: "")
            loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
            menu.addItem(loginItem)
            
            menu.addItem(NSMenuItem.separator())
            
            // Quit
            menu.addItem(NSMenuItem(title: "Quit Battery", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            // Immediately clear the menu so the next left-click goes back to native Action triggers
            statusItem.menu = nil
            return
        }
        
        // Handle normal left click
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
}
