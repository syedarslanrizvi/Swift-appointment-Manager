import SwiftUI

struct MotivationalQuoteView: View {
    let quote: String
    
    var body: some View {
        VStack {
            Text(quote)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }
} 