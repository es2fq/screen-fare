//
//  FeedbackDetailView.swift
//  Screen Fare
//
//  In-app feedback form for user feedback and bug reports
//

import SwiftUI
import MessageUI

enum FeedbackCategory: String, CaseIterable {
    case bugReport = "Bug"
    case featureRequest = "Idea"
    case general = "Other"

    var fullName: String {
        switch self {
        case .bugReport: return "Bug Report"
        case .featureRequest: return "Feature Request"
        case .general: return "General Feedback"
        }
    }
}

struct FeedbackDetailView: View {
    @Binding var showToast: ToastData?
    @FocusState.Binding var isFeedbackFocused: Bool
    @State private var selectedCategory: FeedbackCategory = .general
    @State private var feedbackText: String = ""
    @State private var showMailComposer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Intro note
            IntroNote(text: "Your feedback helps make Screen Fare better. Tell us what's on your mind!")
                .contentShape(Rectangle())
                .onTapGesture {
                    isFeedbackFocused = false
                }

            // Category section
            SectionTitle(text: "Category")
                .contentShape(Rectangle())
                .onTapGesture {
                    isFeedbackFocused = false
                }

            AppCard(padding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)) {
                HStack(spacing: 6) {
                    ForEach(FeedbackCategory.allCases, id: \.self) { category in
                        CategoryPill(
                            category: category,
                            isSelected: selectedCategory == category,
                            action: {
                                selectedCategory = category
                                HapticManager.shared.impact()
                                isFeedbackFocused = false
                            }
                        )
                    }
                }
            }

            Spacer()
                .frame(height: 18)
                .contentShape(Rectangle())
                .onTapGesture {
                    isFeedbackFocused = false
                }

            // Feedback text section
            SectionTitle(text: "Your feedback")
                .contentShape(Rectangle())
                .onTapGesture {
                    isFeedbackFocused = false
                }

            ZStack(alignment: .topLeading) {
                AppCard(padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) {
                    TextEditor(text: $feedbackText)
                        .font(.inter(15))
                        .foregroundColor(.focusInk)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 200)
                        .padding(16)
                        .background(Color.focusCard)
                        .focused($isFeedbackFocused)
                        .lineSpacing(2)
                        .cornerRadius(18)
                }

                if feedbackText.isEmpty {
                    Text("Describe your \(selectedCategory.fullName.lowercased())...")
                        .font(.inter(15))
                        .foregroundColor(.focusMuted.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .allowsHitTesting(false)
                }
            }

            Spacer()
                .frame(height: 28)
                .contentShape(Rectangle())
                .onTapGesture {
                    isFeedbackFocused = false
                }

            // Submit button
            Button(action: submitFeedback) {
                Text("Send feedback")
                    .font(.inter(16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(feedbackText.isEmpty ? Color.focusInk.opacity(0.25) : Color.focusInk)
                    .cornerRadius(16)
            }
            .disabled(feedbackText.isEmpty)
            .simultaneousGesture(TapGesture().onEnded {
                isFeedbackFocused = false
            })

            Spacer()
                .contentShape(Rectangle())
                .onTapGesture {
                    isFeedbackFocused = false
                }
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposeView(
                subject: "Screen Fare: \(selectedCategory.fullName)",
                body: composeEmailBody(),
                isPresented: $showMailComposer,
                onResult: handleMailResult
            )
        }
        .onDisappear {
            // Dismiss keyboard when navigating away
            isFeedbackFocused = false
        }
    }

    private func submitFeedback() {
        HapticManager.shared.impact()

        // Check if Mail is available
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            // Fallback: copy to clipboard
            let feedbackContent = composeEmailBody()
            UIPasteboard.general.string = feedbackContent
            showToast = ToastData(message: "Feedback copied to clipboard")
        }
    }

    private func composeEmailBody() -> String {
        var body = feedbackText
        body += "\n\n"
        body += "---\n"
        body += "App Version: 1.0.0\n"
        body += "iOS Version: \(UIDevice.current.systemVersion)\n"
        body += "Device: \(UIDevice.current.model)"

        return body
    }

    private func handleMailResult(_ result: Result<MFMailComposeResult, Error>) {
        switch result {
        case .success(let mailResult):
            switch mailResult {
            case .sent:
                showToast = ToastData(message: "Feedback sent! Thank you")
                // Clear form
                feedbackText = ""
                selectedCategory = .general
            case .saved:
                showToast = ToastData(message: "Feedback saved to drafts")
            case .cancelled:
                break
            case .failed:
                showToast = ToastData(message: "Failed to send feedback")
            @unknown default:
                break
            }
        case .failure:
            showToast = ToastData(message: "Failed to send feedback")
        }
    }
}

// MARK: - Category Pill

struct CategoryPill: View {
    let category: FeedbackCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.inter(13, weight: .semibold))
                .foregroundColor(isSelected ? .white : .focusInk.opacity(0.7))
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(isSelected ? Color.focusInk : Color.focusInk.opacity(0.05))
                .cornerRadius(12)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Mail Compose View

struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    @Binding var isPresented: Bool
    var onResult: (Result<MFMailComposeResult, Error>) -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(["support@screenfare.app"])
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView

        init(_ parent: MailComposeView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                parent.onResult(.failure(error))
            } else {
                parent.onResult(.success(result))
            }
            parent.isPresented = false
        }
    }
}
