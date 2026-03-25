import SwiftUI

struct BatteryIconView: View {
    @ObservedObject var state: BatteryState
    
    // Aesthetic constants
    let bodyWidth: CGFloat = 23
    let bodyHeight: CGFloat = 12.5
    let strokeWidth: CGFloat = 1.0
    let cornerRadius: CGFloat = 3.0
    // The gap between the inner fill and the black outline
    let innerGap: CGFloat = 1.0 
    
    private var juiceColor: Color {
        // Red color overrides green when percentage is critically low!
        if state.percentage <= 0.15 {
            return .red
        } else if state.isCharging && state.percentage >= 0.9 {
            return .green
        } else {
            return Color.primary.opacity(0.4)
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            // Plug icon (if plugged in)
            if state.isPlugged {
                PlugIcon()
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round))
                    .frame(width: 7, height: 9)
            }
            
            ZStack(alignment: .leading) {
                // Battery Tip (Right)
                // Locked directly inside the ZStack coordinate space
                Path { path in
                    let tipHeight: CGFloat = 4.0
                    let tipWidth: CGFloat = 1.5
                    path.addRoundedRect(in: CGRect(x: bodyWidth - strokeWidth, y: (bodyHeight - tipHeight) / 2, width: tipWidth + strokeWidth, height: tipHeight),
                                        cornerSize: CGSize(width: 1, height: 1),
                                        style: .continuous)
                }
                .fill(Color.primary)
                
                // Background behind the face
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.clear)
                    .frame(width: bodyWidth, height: bodyHeight)
                
                // Fill representing battery capacity
                let padding = strokeWidth + innerGap
                let maxFillWidth = bodyWidth - padding * 2
                let fillWidth = max(0, maxFillWidth * CGFloat(state.percentage))
                
                if fillWidth > 0 {
                    // Juice is a rounded pill, not a masked rectangle!
                    let innerRadius = max(0.5, cornerRadius - padding)
                    RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                        .fill(juiceColor)
                        .frame(width: fillWidth, height: bodyHeight - padding * 2)
                        .padding(padding)
                }
                
                // Battery Body Outline
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary, lineWidth: strokeWidth)
                    .frame(width: bodyWidth, height: bodyHeight)
                
                // Face
                FaceView(state: state)
                    .frame(width: bodyWidth, height: bodyHeight)
            }
            // ZStack frame matches the body width plus the protruding tip
            .frame(width: bodyWidth + 1.5, height: bodyHeight)
        }
        .padding(.horizontal, 2)
    }
}

enum FaceExpression {
    case happy
    case neutral
    case sad
}

struct FaceView: View {
    var state: BatteryState
    
    var expression: FaceExpression {
        if state.isPlugged && !state.isCharging { return .sad }
        if state.percentage <= 0.20 { return .sad }
        if state.percentage <= 0.35 && !state.isCharging { return .neutral }
        return .happy
    }
    
    var body: some View {
        Canvas { context, size in
            let eyeSize: CGFloat = 1.5
            let eyeY = size.height / 2 - 0.2
            let eyeSpacing: CGFloat = 8.8
            let centerX = size.width / 2
            
            // Draw Left Eye
            let leftEyeRect = CGRect(x: centerX - eyeSpacing/2 - eyeSize/2, y: eyeY, width: eyeSize, height: eyeSize)
            context.fill(Path(ellipseIn: leftEyeRect), with: .color(.primary))
            
            // Draw Right Eye
            let rightEyeRect = CGRect(x: centerX + eyeSpacing/2 - eyeSize/2, y: eyeY, width: eyeSize, height: eyeSize)
            context.fill(Path(ellipseIn: rightEyeRect), with: .color(.primary))
            
            // Draw Mouth
            var mouthPath = Path()
            let mouthY = size.height / 2 + 1.2
            let mouthWidth: CGFloat = 2.8
            let mouthLineWidth: CGFloat = 1.0
            
            switch expression {
            case .sad:
                mouthPath.move(to: CGPoint(x: centerX - mouthWidth/2, y: mouthY + 1.0))
                mouthPath.addQuadCurve(to: CGPoint(x: centerX + mouthWidth/2, y: mouthY + 1.0),
                                       control: CGPoint(x: centerX, y: mouthY - 0.5))
            case .neutral:
                mouthPath.move(to: CGPoint(x: centerX - mouthWidth/2, y: mouthY + 0.5))
                mouthPath.addLine(to: CGPoint(x: centerX + mouthWidth/2, y: mouthY + 0.5))
            case .happy:
                mouthPath.move(to: CGPoint(x: centerX - mouthWidth/2, y: mouthY))
                mouthPath.addQuadCurve(to: CGPoint(x: centerX + mouthWidth/2, y: mouthY),
                                       control: CGPoint(x: centerX, y: mouthY + 1.8))
            }
            
            context.stroke(mouthPath, with: .color(.primary), style: StrokeStyle(lineWidth: mouthLineWidth, lineCap: .round))
        }
    }
}

struct PlugIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cy = rect.midY
        let prongsWidth: CGFloat = rect.width * 0.4
        
        // Top prong
        path.move(to: CGPoint(x: 0, y: cy - 2.0))
        path.addLine(to: CGPoint(x: prongsWidth, y: cy - 2.0))
        
        // Bottom prong
        path.move(to: CGPoint(x: 0, y: cy + 2.0))
        path.addLine(to: CGPoint(x: prongsWidth, y: cy + 2.0))
        
        // Connector block limit
        path.move(to: CGPoint(x: prongsWidth, y: cy - 3.0))
        path.addLine(to: CGPoint(x: prongsWidth, y: cy + 3.0))
        
        // Right connector
        path.move(to: CGPoint(x: prongsWidth, y: cy))
        path.addLine(to: CGPoint(x: rect.width, y: cy))
        
        return path
    }
}

