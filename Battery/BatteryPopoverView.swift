import SwiftUI

struct BatteryPopoverView: View {
    @ObservedObject var state: BatteryState
    
    var timeString: String {
        if state.timeRemaining > 0 {
            let hours = state.timeRemaining / 60
            let minutes = state.timeRemaining % 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        } else {
            // macOS sometimes reports 0 when fully charged or calculating
            return state.percentage >= 1.0 ? "Fully Charged" : "Calculating..."
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Battery")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(String(format: "%.0f%%", state.percentage * 100))
                        .font(.system(size: 24, weight: .bold))
                }
                Spacer()
                BatteryIconView(state: state)
                    .scaleEffect(1.5, anchor: .topTrailing)
                    .frame(width: 48, height: 24)
            }
            
            Divider()
            
            HStack {
                Text(state.isCharging ? "Time to Full:" : "Time Remaining:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(timeString)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(16)
        .frame(width: 240)
    }
}
