import SwiftUI
import Combine

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
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.0f%%", state.percentage * 100))
                        .font(.system(size: 24, weight: .bold))
                    if timeString == "Calculating..." && (state.isPlugged || state.isCharging){
                        Text(state.isCharging ? "Charging" : "Plugged-in")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                }
                Spacer()
                AnimatedPopoverBatteryIcon(state: state)
                    .scaleEffect(1.5, anchor: .trailing)
                    .frame(width: 48, height: 24)
            }
            
            if timeString != "Calculating..."{
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
        }
        .padding(16)
        .frame(width: 240)
    }
}

struct WaveShape: Shape {
    var phase: CGFloat
    var percentage: CGFloat
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, percentage) }
        set {
            phase = newValue.first
            percentage = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Fills from bottom-to-top because it's liquid!
        let fillHeight = height * percentage
        let baseline = height - fillHeight
        
        // Amplitude is lower when completely full or empty
        let normalizedAmp = sin(percentage * .pi) 
        let amplitude = (percentage > 0.02 && percentage < 0.98) ? height * 0.12 * normalizedAmp : 0
        let wavelength = width
        
        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: baseline))
        
        // Draw the wavy surface across the top
        for x in stride(from: 0, through: width, by: 1) { 
            let relativeX = x / wavelength
            let y = baseline + sin(relativeX * .pi * 2 + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        return path
    }
}


enum PopoverBatteryStatePreset {
    case standardCalm
    case sad
    case concerned
    case zenMaster
    case chargingPour
    case chargingSip
    case pluggedInSideEye
}

struct PopoverFaceView: View {
    let preset: PopoverBatteryStatePreset
    @State private var zzzPhase: CGFloat = 0.0
    
    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let eyeY = size.height / 2 - 0.2
            let eyeSpacing: CGFloat = 8.8
            let mouthY = size.height / 2 + 1.2
            let primary = context.resolve(GraphicsContext.Shading.color(.primary))
            
            func drawEye(x: CGFloat, y: CGFloat, isClosed: Bool, isSad: Bool) {
                if isBlinking {
                    var p = Path()
                    // Draw a flat horizontal line for a blink
                    p.move(to: CGPoint(x: x - 1.5, y: y + 0.5))
                    p.addLine(to: CGPoint(x: x + 1.5, y: y + 0.5))
                    context.stroke(p, with: primary, style: StrokeStyle(lineWidth: 1.0, lineCap: .round))
                    return
                }
                
                if isClosed {
                    var p = Path()
                    let r: CGFloat = 1.5
                    p.move(to: CGPoint(x: x - r, y: y))
                    p.addQuadCurve(to: CGPoint(x: x + r, y: y), control: CGPoint(x: x, y: y + 2.0))
                    context.stroke(p, with: primary, style: StrokeStyle(lineWidth: 1.0, lineCap: .round))
                } else if isSad {
                    // Sad droopy eye (small flat curve)
                    var p = Path()
                    let r: CGFloat = 1.2
                    p.move(to: CGPoint(x: x - r, y: y - 0.5))
                    p.addQuadCurve(to: CGPoint(x: x + r, y: y + 0.5), control: CGPoint(x: x, y: y - 0.8))
                    context.stroke(p, with: primary, style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                } else {
                    let eyeRect = CGRect(x: x - 1.0, y: y - 1.0, width: 2.0, height: 2.0)
                    context.fill(Path(ellipseIn: eyeRect), with: primary)
                }
            }
            
            // Draw eyes
            let lx = centerX - eyeSpacing/2
            let rx = centerX + eyeSpacing/2
            
            switch preset {
            case .zenMaster, .chargingSip:
                drawEye(x: lx, y: eyeY, isClosed: true, isSad: false)
                drawEye(x: rx, y: eyeY, isClosed: true, isSad: false)
            case .sad:
                drawEye(x: lx, y: eyeY, isClosed: false, isSad: true)
                drawEye(x: rx, y: eyeY, isClosed: false, isSad: true)
            case .concerned:
                drawEye(x: lx, y: eyeY, isClosed: false, isSad: false)
                // Concerned right eye slightly raised
                var concernedEye = Path()
                concernedEye.move(to: CGPoint(x: rx - 1.2, y: eyeY - 2.0))
                concernedEye.addQuadCurve(to: CGPoint(x: rx + 1.0, y: eyeY - 1.5), control: CGPoint(x: rx, y: eyeY - 2.5))
                context.stroke(concernedEye, with: primary, style: StrokeStyle(lineWidth: 1.0, lineCap: .round))
                context.fill(Path(ellipseIn: CGRect(x: rx - 1.0, y: eyeY - 0.5, width: 2.0, height: 2.0)), with: primary)
            case .chargingPour:
                drawEye(x: lx, y: eyeY - 1.0, isClosed: true, isSad: false)
                drawEye(x: rx, y: eyeY - 1.0, isClosed: true, isSad: false)
            case .pluggedInSideEye:
                // Shift eyes based on state to create the looking back and forth
                let shift: CGFloat = isLookingLeft ? 1.5 : 0.0
                drawEye(x: lx - shift, y: eyeY, isClosed: false, isSad: false)
                drawEye(x: rx - shift, y: eyeY, isClosed: false, isSad: false)
            case .standardCalm:
                drawEye(x: lx, y: eyeY, isClosed: false, isSad: false)
                drawEye(x: rx, y: eyeY, isClosed: false, isSad: false)
            }
            
            // Draw Mouth
            var mouthPath = Path()
            let mouthWidth: CGFloat = 2.8
            
            switch preset {
            case .standardCalm:
                mouthPath.move(to: CGPoint(x: centerX - mouthWidth/2, y: mouthY))
                mouthPath.addQuadCurve(to: CGPoint(x: centerX + mouthWidth/2, y: mouthY), control: CGPoint(x: centerX, y: mouthY + 2.0))
            case .sad:
                mouthPath.move(to: CGPoint(x: centerX - mouthWidth*0.8, y: mouthY + 1.5))
                mouthPath.addQuadCurve(to: CGPoint(x: centerX + mouthWidth*0.8, y: mouthY + 1.5), control: CGPoint(x: centerX, y: mouthY - 0.5))
            case .concerned:
                mouthPath.move(to: CGPoint(x: centerX - mouthWidth/2, y: mouthY + 1.0))
                mouthPath.addLine(to: CGPoint(x: centerX + mouthWidth/2, y: mouthY + 0.5))
            case .zenMaster:
                mouthPath.move(to: CGPoint(x: centerX - mouthWidth/2, y: mouthY))
                mouthPath.addQuadCurve(to: CGPoint(x: centerX + mouthWidth/2, y: mouthY), control: CGPoint(x: centerX, y: mouthY + 1.0))
            case .chargingSip:
                mouthPath.move(to: CGPoint(x: centerX - 1.0, y: mouthY))
                mouthPath.addQuadCurve(to: CGPoint(x: centerX + 1.0, y: mouthY), control: CGPoint(x: centerX, y: mouthY + 1.5))
            case .chargingPour:
                // Big open smile mouth for pouring!
                var mouthFull = Path()
                mouthFull.move(to: CGPoint(x: centerX - 2.5, y: mouthY))
                mouthFull.addQuadCurve(to: CGPoint(x: centerX + 2.5, y: mouthY), control: CGPoint(x: centerX, y: mouthY + 3.5))
                mouthFull.closeSubpath()
                context.fill(mouthFull, with: primary)
            case .pluggedInSideEye:
                // Waiting patiently flat mouth
                mouthPath.move(to: CGPoint(x: centerX - mouthWidth/2, y: mouthY + 0.5))
                mouthPath.addLine(to: CGPoint(x: centerX + mouthWidth/2, y: mouthY + 0.5))
            }
            
            if preset != .chargingPour {
                context.stroke(mouthPath, with: primary, style: StrokeStyle(lineWidth: 1.0, lineCap: .round))
            }
            
        }
        .overlay(
            ZStack {
                if preset == .zenMaster {
                    // "Z" particles
                    Text("Z")
                        .font(.system(size: 6, weight: .bold))
                        .offset(x: 4, y: -6 - zzzPhase * 4)
                        .opacity(1.0 - zzzPhase)
                    Text("Z")
                        .font(.system(size: 8, weight: .bold))
                        .offset(x: 8, y: -8 - zzzPhase * 6)
                        .opacity(1.0 - zzzPhase)
                }
            }
        )
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                zzzPhase = 1.0
            }
        }
        .onReceive(Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()) { _ in
            if preset == .pluggedInSideEye {
                isLookingLeft = false // Glance forward
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    isLookingLeft = true // Glance back at coffee
                }
            } else if preset == .standardCalm || preset == .concerned || preset == .sad {
                isBlinking = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isBlinking = false
                }
            }
        }
    }
    
    @State private var isLookingLeft = true
    @State private var isBlinking = false
}

// Represents the towel on the Zen Master battery
struct TowelShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: CGRect(x: 4, y: -2, width: 10, height: 4), cornerSize: CGSize(width: 1, height: 1))
        return path
    }
}

// Arc pour when pouring from above
struct ArcPourShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX - 2, y: rect.minY - 2))
        path.addQuadCurve(to: CGPoint(x: rect.midX + 2, y: rect.midY), control: CGPoint(x: rect.minX + 4, y: rect.minY - 4))
        return path
    }
}

struct AnimatedPopoverBatteryIcon: View {
    @ObservedObject var state: BatteryState
    @State private var phase: CGFloat = 0.0
    @State private var flowPhase: CGFloat = 0.0
    
    let bodyWidth: CGFloat = 23
    let bodyHeight: CGFloat = 12.5
    let strokeWidth: CGFloat = 1.0
    let cornerRadius: CGFloat = 3.0
    let innerGap: CGFloat = 1.0 
    
    var preset: PopoverBatteryStatePreset {
        if state.isCharging {
            return .chargingSip
        } else if state.isPlugged {
            return .pluggedInSideEye
        } else if state.isLowPowerMode {
            return .zenMaster
        } else if state.percentage <= 0.20 {
            return .sad
        } else if state.percentage <= 0.40 {
            return .concerned
        } else {
            return .standardCalm
        }
    }
    
    private var juiceColor: Color {
        if preset == .sad {
            return .red
        } else {
            return Color.primary.opacity(0.4)
        }
    }
    
    var body: some View {
        HStack(spacing: 1) {
            
            if state.isPlugged {
                if preset == .chargingPour {
                    // Keep spacing intact so the view doesn't jump
                    Color.clear
                        .frame(width: 7, height: 9)
                } else {
                    AnimatedCoffeeCup(isCharging: state.isCharging)
                        .frame(width: 7, height: 9)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            ZStack(alignment: .leading) {
                // Background behind the liquid
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.clear)
                    .frame(width: bodyWidth, height: bodyHeight)
                
                let padding = strokeWidth + innerGap
                let innerRadius = max(0.5, cornerRadius - padding)
                
                // Active Slosh!
                WaveShape(phase: phase, percentage: CGFloat(state.percentage))
                    .fill(juiceColor)
                    .clipShape(RoundedRectangle(cornerRadius: innerRadius, style: .continuous))
                    .frame(width: bodyWidth - padding * 2, height: bodyHeight - padding * 2)
                    .padding(padding)
                
                // Battery Shell
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary, lineWidth: strokeWidth)
                    .frame(width: bodyWidth, height: bodyHeight)
                    .mask(
                        ZStack(alignment: .topLeading) {
                            Color.white
                            if preset == .zenMaster {
                                Rectangle()
                                    .fill(Color.black)
                                    .blendMode(.destinationOut)
                                    .frame(width: 9.5, height: 4)
                                    .offset(x: 4.25, y: -2)
                            }
                        }
                        .compositingGroup()
                    )
                
                // Positive Tip
                Path { path in
                    let tipHeight: CGFloat = 4.0
                    let tipWidth: CGFloat = 1.5
                    path.addRoundedRect(in: CGRect(x: bodyWidth - strokeWidth, y: (bodyHeight - tipHeight) / 2, width: tipWidth + strokeWidth, height: tipHeight),
                                        cornerSize: CGSize(width: 1, height: 1),
                                        style: .continuous)
                }
                .fill(Color.primary)
                
                // Face
                PopoverFaceView(preset: preset)
                    .frame(width: bodyWidth, height: bodyHeight)
                
                // Towel for Zen Master
                if preset == .zenMaster {
                    TowelShape()
                        .stroke(Color.primary, style: StrokeStyle(lineWidth: 1.0, lineCap: .round, dash: [0.5, 0.5]))
                        .background(TowelShape().fill(Color.primary.opacity(0.1)))
                }
                
                // Arc flow overlay for the pour!
                if preset == .chargingPour {
                    // 1. Arc pouring into mouth
                    Path { path in
                        // Start high and left (near the lifted cup)
                        path.move(to: CGPoint(x: -1.0, y: -8.0))
                        // Curve downwards perfectly into the battery's smiling mouth
                        path.addQuadCurve(to: CGPoint(x: 10.0, y: 6.5), control: CGPoint(x: 3.0, y: -6.0))
                    }
                    .stroke(Color(red: 0.25, green: 0.15, blue: 0.10), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [3.0, 3.0], dashPhase: flowPhase))
                    
                    // 2. Elevated Pouring Cup (drawn over the arc)
                    ZStack {
                        PlugIcon().fill(Color.primary.opacity(0.4))
                        PlugIcon().stroke(Color.primary, style: StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round))
                    }
                    .frame(width: 7, height: 9)
                    .rotationEffect(.degrees(-55)) // Deep tilt pour!
                    .offset(x: -8, y: -10)          // Lifted up and shifted to the left
                }
            }
            .frame(width: bodyWidth + 1.5, height: bodyHeight)
            // If pouring, the main battery body tilts slightly back to catch the coffee!
            .rotationEffect(.degrees(preset == .chargingPour ? -10 : 0), anchor: .bottomLeading)
        }
        .padding(.horizontal, 2)
        .padding(.top, preset == .chargingPour ? 8 : 0) // extra padding to avoid clipping the high cup
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: state.isPlugged)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: preset)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
            withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                flowPhase = -6.0 // pouring fast!
            }
        }
    }
}

struct StrawFlowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let cupHeight: CGFloat = 5.0
        let lidHeight: CGFloat = 1.0
        let baseY = rect.maxY + 2.5
        let topY = baseY - cupHeight
        
        // Start from cup
        let strawStart = CGPoint(x: cx, y: topY - lidHeight + 0.5)
        let strawBend = CGPoint(x: cx, y: topY - lidHeight - 0.5)
        
        // Extend straw perfectly into the smiling mouth center
        let strawEnd = CGPoint(x: cx + 18.0, y: topY - lidHeight + 1.5) 
        
        path.move(to: strawStart)
        path.addLine(to: strawBend)
        path.addLine(to: strawEnd)
        
        return path
    }
}

// Draw the extended straw container
struct StrawShellShape: Shape {
    func path(in rect: CGRect) -> Path {
        return StrawFlowShape().path(in: rect)
    }
}

struct AnimatedCoffeeCup: View {
    var isCharging: Bool
    @State private var flowPhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            if !isCharging {
                PlugIcon().fill(Color.primary.opacity(0.4))
                PlugIcon().stroke(Color.primary, style: StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round))
            } else {
                // Charging Sip State!
                // 1. Draw standard cup base (without built-in short straw)
                Path { path in
                    let cx = 3.5
                    let baseY: CGFloat = 11.5
                    let topY: CGFloat = 6.5
                    path.move(to: CGPoint(x: cx - 1.5, y: baseY))
                    path.addLine(to: CGPoint(x: cx + 1.5, y: baseY))
                    path.addLine(to: CGPoint(x: cx + 2.5, y: topY))
                    path.addLine(to: CGPoint(x: cx - 2.5, y: topY))
                    path.closeSubpath()
                    path.move(to: CGPoint(x: cx - 2.5, y: topY))
                    path.addQuadCurve(to: CGPoint(x: cx + 2.5, y: topY), control: CGPoint(x: cx, y: topY - 2.0))
                }
                .stroke(Color.primary, style: StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round))
                
                // 2. Draw elongated straw outline
                StrawShellShape()
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round))
                
                // 3. Flowing liquid within the elongated straw
                StrawFlowShape()
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round, dash: [1.5, 1.5], dashPhase: flowPhase))
                    .onAppear {
                        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                            flowPhase = -3.0 // Creates flowing motion!
                        }
                    }
            }
        }
    }
}
