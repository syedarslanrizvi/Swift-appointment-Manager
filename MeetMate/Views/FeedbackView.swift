import SwiftUI
import MessageUI

struct FeedbackView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentation
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var presentation: PresentationMode
        
        init(presentation: Binding<PresentationMode>) {
            _presentation = presentation
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            $presentation.wrappedValue.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(presentation: presentation)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<FeedbackView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(["feedback@meetmate.com"])
        vc.setSubject("MeetMate Feedback")
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: UIViewControllerRepresentableContext<FeedbackView>) {
    }
} 