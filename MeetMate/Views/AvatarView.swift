import SwiftUI

struct AvatarView: View {
    let name: String
    
    var body: some View {
        Text(String(name.first ?? "A"))
            .font(.headline)
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(Color.gray)
            .clipShape(Circle())
    }
} 