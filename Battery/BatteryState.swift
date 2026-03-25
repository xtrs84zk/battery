import Foundation
import IOKit.ps
import Combine

class BatteryState: ObservableObject {
    @Published var percentage: Double = 1.0
    @Published var isCharging: Bool = false
    @Published var isPlugged: Bool = false
    
    private var runLoopSource: CFRunLoopSource?
    
    init() {
        setupObserver()
        updateBatteryState()
    }
    
    private func setupObserver() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        runLoopSource = IOPSNotificationCreateRunLoopSource({ context in
            guard let context = context else { return }
            let state = Unmanaged<BatteryState>.fromOpaque(context).takeUnretainedValue()
            state.updateBatteryState()
        }, context).takeRetainedValue()
        
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
        }
    }
    
    deinit {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
        }
    }
    
    private func updateBatteryState() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        for source in sources {
            let info = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as! [String: Any]
            
            if let capacity = info[kIOPSCurrentCapacityKey] as? Double,
               let maxCapacity = info[kIOPSMaxCapacityKey] as? Double {
                DispatchQueue.main.async {
                    self.percentage = capacity / maxCapacity
                }
            }
            
            if let isCharging = info[kIOPSIsChargingKey] as? Bool {
                DispatchQueue.main.async {
                    self.isCharging = isCharging
                }
            }
            
            if let psState = info[kIOPSPowerSourceStateKey] as? String {
                DispatchQueue.main.async {
                    self.isPlugged = (psState == kIOPSACPowerValue)
                }
            }
        }
    }
}
