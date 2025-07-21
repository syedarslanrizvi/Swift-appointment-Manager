import SwiftUI

struct ConfettiView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            ForEach(0..<100) { _ in
                Circle()
                    .fill(Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1)))
                    .frame(width: .random(in: 5...15), height: .random(in: 5...15))
                    .offset(x: .random(in: -200...200), y: .random(in: -400...400))
                    .opacity(isAnimating ? 0 : 1)
                    .animation(
                        Animation.easeOut(duration: .random(in: 1...2))
                        .repeatForever(autoreverses: false)
                        .delay(.random(in: 0...0.5)),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
} 