import SwiftUI
import UIKit

struct ContentView: View {
    @AppStorage("totalMerit") private var totalMerit = 0
    @State private var isStriking = false
    @State private var feedbackItems: [MeritFeedback] = []
    @State private var strikeTask: Task<Void, Never>?

    private let backgroundGreen = Color(red: 0.08, green: 0.65, blue: 0.29)
    private let restingMalletAngle = Angle.degrees(75)
    private let strikingMalletAngle = Angle.degrees(30)

    var body: some View {
        ZStack {
            backgroundGreen.ignoresSafeArea()

            VStack(spacing: 0) {
                totalMeritHeader
                    .padding(.top, 18)

                Spacer()

                woodenFishButton

                Text("点击木鱼 · 积攒功德")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))
                    .padding(.top, 26)

                Spacer()
                    .frame(height: 82)
            }
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(.light)
    }

    private var totalMeritHeader: some View {
        VStack(spacing: 5) {
            Text("总功德")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.82))

            Text(totalMerit.formatted())
                .font(.system(size: 44, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .animation(.spring(response: 0.28, dampingFraction: 0.72), value: totalMerit)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("总功德，\(totalMerit)")
    }

    private var woodenFishButton: some View {
        Button(action: strike) {
            ZStack {
                Image("WoodenFish")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 330)
                    .scaleEffect(isStriking ? 0.975 : 1)

                Image("WoodenMallet")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 205)
                    // Rest above the fish, aimed toward 10 o'clock. On impact the
                    // head travels down and left toward the 9–8 o'clock direction.
                    .rotationEffect(
                        isStriking ? strikingMalletAngle : restingMalletAngle
                    )
                    .offset(
                        x: isStriking ? -30 : 5,
                        y: isStriking ? -25 : -160
                    )
                    .animation(
                        isStriking
                            ? .easeIn(duration: 0.10)
                            : .spring(response: 0.28, dampingFraction: 0.48),
                        value: isStriking
                    )

                ForEach(feedbackItems) { item in
                    MeritPlusOneView()
                        .id(item.id)
                        .offset(x: -8, y: -190)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.65).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            )
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("敲击木鱼")
        .accessibilityHint("每次敲击增加一点功德")
    }

    private func strike() {
        totalMerit += 1
        SoundManager.shared.playWoodblock()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.75)

        let feedback = MeritFeedback()
        withAnimation(.spring(response: 0.22, dampingFraction: 0.66)) {
            feedbackItems.append(feedback)
        }

        strikeTask?.cancel()
        isStriking = true
        strikeTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(95))
            guard !Task.isCancelled else { return }
            isStriking = false
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(520))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.28)) {
                feedbackItems.removeAll { $0.id == feedback.id }
            }
        }
    }
}

private struct MeritFeedback: Identifiable {
    let id = UUID()
}

private struct MeritPlusOneView: View {
    var body: some View {
        Text("功德 +1")
            .font(.system(size: 26, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(.black.opacity(0.26), in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .allowsHitTesting(false)
    }
}

#Preview {
    ContentView()
}
