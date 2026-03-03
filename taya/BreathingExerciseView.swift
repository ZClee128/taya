import SwiftUI

/// Guided breathing exercise with animated pulsing circle.
/// Cycles automatically: Inhale (4s) → Hold (4s) → Exhale (6s)
struct BreathingExerciseView: View {

    @Environment(\.presentationMode) var presentationMode
    @State private var phase: BreathPhase = .inhale
    @State private var countdown: Int = 4
    @State private var scale: CGFloat = 0.55
    @State private var timer: Timer? = nil
    @State private var totalSeconds: Int = 0

    enum BreathPhase {
        case inhale, hold, exhale

        var label: String {
            switch self {
            case .inhale: return "Inhale"
            case .hold:   return "Hold"
            case .exhale: return "Exhale"
            }
        }

        var duration: Int {
            switch self {
            case .inhale: return 4
            case .hold:   return 4
            case .exhale: return 6
            }
        }

        var next: BreathPhase {
            switch self {
            case .inhale: return .hold
            case .hold:   return .exhale
            case .exhale: return .inhale
            }
        }

        var targetScale: CGFloat {
            switch self {
            case .inhale: return 1.0
            case .hold:   return 1.0
            case .exhale: return 0.55
            }
        }

        var animationDuration: Double { Double(duration) }

        var gradientColors: [Color] {
            switch self {
            case .inhale: return [Color(red: 0.36, green: 0.72, blue: 0.66), Color(red: 0.24, green: 0.55, blue: 0.80)]
            case .hold:   return [Color(red: 0.55, green: 0.45, blue: 0.85), Color(red: 0.36, green: 0.72, blue: 0.66)]
            case .exhale: return [Color(red: 0.24, green: 0.55, blue: 0.80), Color(red: 0.36, green: 0.55, blue: 0.75)]
            }
        }
    }

    private var formattedTime: String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var body: some View {
        ZStack {
            // Gradient background shifts with phase
            LinearGradient(
                gradient: Gradient(colors: phase.gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            .animation(.easeInOut(duration: 1.0), value: phase.label)

            VStack(spacing: 40) {
                // Header
                HStack {
                    Spacer()
                    Button(action: stopAndDismiss) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Session timer
                Text(formattedTime)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))

                // Animated breathing circle
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 2)
                        .frame(width: 260, height: 260)
                        .scaleEffect(scale)

                    // Main pulsing circle
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.35), Color.white.opacity(0.10)]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 130
                            )
                        )
                        .frame(width: 240, height: 240)
                        .scaleEffect(scale)

                    // Inner circle
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 100, height: 100)

                    // Phase label + countdown
                    VStack(spacing: 4) {
                        Text(phase.label)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                        Text("\(countdown)")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                // Instruction text
                Text(instructionText)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                // Tips strip
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("Breathe through your nose. Relax your shoulders.")
                        .font(.caption)
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom, 30)
            }
        }
        .onAppear(perform: startTimer)
        .onDisappear { timer?.invalidate() }
    }

    private var instructionText: String {
        switch phase {
        case .inhale: return "Slowly breathe in, filling your lungs completely."
        case .hold:   return "Gently hold. Keep your body relaxed."
        case .exhale: return "Slowly release all the air. Feel the tension leave."
        }
    }

    private func startTimer() {
        countdown = phase.duration
        animateToCurrentPhase()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            totalSeconds += 1
            if countdown > 1 {
                countdown -= 1
            } else {
                advancePhase()
            }
        }
    }

    private func advancePhase() {
        phase = phase.next
        countdown = phase.duration
        animateToCurrentPhase()
    }

    private func animateToCurrentPhase() {
        withAnimation(.easeInOut(duration: phase.animationDuration)) {
            scale = phase.targetScale
        }
    }

    private func stopAndDismiss() {
        timer?.invalidate()
        presentationMode.wrappedValue.dismiss()
    }
}

struct BreathingExerciseView_Previews: PreviewProvider {
    static var previews: some View {
        BreathingExerciseView()
    }
}
