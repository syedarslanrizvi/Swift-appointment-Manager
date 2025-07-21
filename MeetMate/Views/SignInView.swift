import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isSignedIn: Bool

    var body: some View {
        VStack {
            Text("Welcome to MeetMate")
                .font(.largeTitle)
                .padding()

            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        print("Authentication successful: \(authResults)")
                        // Handle successful authentication
                        isSignedIn = true
                    case .failure(let error):
                        print("Authentication failed: \(error.localizedDescription)")
                        // Handle failed authentication
                    }
                }
            )
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(width: 280, height: 60)
            .padding()
        }
    }
} 