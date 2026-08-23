import SwiftUI

struct LaunchAnimationView: View {
    let onFinished: () -> Void

    @State private var capsuleWidth: CGFloat = 0
    @State private var dotScale: CGFloat = 0.001
    @State private var glyphOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 14
    @State private var fadeOut = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.49, green: 0.60, blue: 0.97),
                    Color(red: 0.37, green: 0.25, blue: 0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                GlassEffectContainer(spacing: 10) {
                    HStack(spacing: 10) {
                        Capsule()
                            .fill(Color.clear)
                            .frame(width: capsuleWidth, height: 34)
                            .glassEffect(.regular.tint(.white.opacity(0.9)).interactive(), in: Capsule())

                        Circle()
                            .fill(Color.clear)
                            .frame(width: 34, height: 34)
                            .glassEffect(.regular.tint(.white.opacity(0.9)).interactive(), in: Circle())
                            .scaleEffect(dotScale)
                    }
                }
                .opacity(glyphOpacity)

                Text("Island")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
            }
        }
        .opacity(fadeOut ? 0 : 1)
        .task { await runSequence() }
    }

    private func runSequence() async {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.68)) {
            glyphOpacity = 1
            capsuleWidth = 96
        }
        try? await Task.sleep(for: .milliseconds(280))

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            dotScale = 1
        }
        try? await Task.sleep(for: .milliseconds(200))

        withAnimation(.easeOut(duration: 0.4)) {
            titleOpacity = 1
            titleOffset = 0
        }
        try? await Task.sleep(for: .milliseconds(700))

        withAnimation(.easeInOut(duration: 0.35)) {
            fadeOut = true
        }
        try? await Task.sleep(for: .milliseconds(380))

        onFinished()
    }
}

#Preview {
    LaunchAnimationView(onFinished: {})
}
