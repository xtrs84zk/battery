import Foundation
import IOKit.ps
import Combine

class BatteryState: ObservableObject {
    @Published var percentage: Double = 1.0
    @Published var isCharging: Bool = false
    @Published var isPlugged: Bool = false
    @Published var timeRemaining: Int = 0 // in minutes
    @Published var adapterWatts: Int = 0 // wattage of the connected charger
    @Published var isLowPowerMode: Bool = false
    
    private var runLoopSource: CFRunLoopSource?
    
    init() {
        self.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        NotificationCenter.default.addObserver(forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
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
            
            if let isPluggedState = info[kIOPSPowerSourceStateKey] as? String {
                DispatchQueue.main.async {
                    self.isPlugged = (isPluggedState == kIOPSACPowerValue)
                }
            }
            
            // Time remaining in minutes
            if let timeEmpty = info[kIOPSTimeToEmptyKey] as? Int, timeEmpty > 0 {
                DispatchQueue.main.async {
                    self.timeRemaining = timeEmpty
                }
            } else if let timeFull = info[kIOPSTimeToFullChargeKey] as? Int, timeFull > 0 {
                DispatchQueue.main.async {
                    self.timeRemaining = timeFull
                }
            } else {
                DispatchQueue.main.async {
                    self.timeRemaining = 0 // Unknown or calculating
                }
            }
            
            if let adapterDetails = IOPSCopyExternalPowerAdapterDetails()?.takeUnretainedValue() as? [String: Any],
               let watts = adapterDetails[kIOPSPowerAdapterWattsKey] as? Int {
                DispatchQueue.main.async { self.adapterWatts = watts }
            } else {
                DispatchQueue.main.async { self.adapterWatts = 0 }
            }
        }
    }
}
