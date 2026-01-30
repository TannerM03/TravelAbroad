//
//  TermsOfServiceView.swift
//  Vista
//
//  Terms of Service acceptance view for onboarding
//

import SwiftUI

struct TermsOfServiceView: View {
    @State private var hasScrolledToBottom = false
    @State private var hasAgreed = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    let onCompletion: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            headerSection

            VStack(spacing: 20) {
                termsScrollView
                agreementCheckbox
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            continueButton
                .padding(.top, 15)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05), Color.clear]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Terms of Service")
                .font(.title2)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Please read and accept our Terms of Service to continue")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }

    private var termsScrollView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Terms of Service")
                .font(.headline)
                .fontWeight(.semibold)

            ScrollViewReader { _ in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        termsContent

                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: ViewOffsetKey.self,
                                value: geometry.frame(in: .named("scroll")).minY
                            )
                        }
                    )
                }
                .frame(height: 300)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ViewOffsetKey.self) { value in
                    // Consider scrolled to bottom if within 50 points of end
                    if abs(value) < 50 {
                        hasScrolledToBottom = true
                    }
                }
            }

            if !hasScrolledToBottom {
                HStack {
                    Spacer()
                    Text("Scroll to the bottom to continue")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Effective Date: January 2026")
                .font(.caption)
                .foregroundColor(.secondary)

            sectionHeader("1. Acceptance of Terms")
            sectionText("By using SideQuest, you agree to these Terms of Service. If you do not agree, please do not use the app.")

            sectionHeader("2. User Conduct & Content Policy")
            sectionText("You are responsible for all content you post, including comments, reviews, and profile information. You agree to NOT post content that:")
            bulletPoint("Contains harassment, threats, or bullying")
            bulletPoint("Promotes hate speech, violence, or discrimination")
            bulletPoint("Includes sexually explicit or inappropriate imagery")
            bulletPoint("Violates others' privacy or intellectual property rights")
            bulletPoint("Contains spam, scams, or fraudulent information")
            bulletPoint("Promotes illegal activities")

            sectionHeader("3. Zero-Tolerance Policy")
            sectionText("SideQuest maintains a zero-tolerance policy for objectionable content and abusive behavior. We reserve the right to:")
            bulletPoint("Remove any content that violates these Terms")
            bulletPoint("Suspend or terminate accounts without prior notice")
            bulletPoint("Report illegal activity to law enforcement")

            sectionHeader("4. Content Moderation")
            sectionText("We review all reported content within 24 hours. Users can report objectionable content or block abusive users at any time. Blocking a user immediately removes their content from your feed.")

            sectionHeader("5. User Responsibilities")
            sectionText("You agree to:")
            bulletPoint("Provide accurate information")
            bulletPoint("Respect other users and their experiences")
            bulletPoint("Report inappropriate content when you encounter it")
            bulletPoint("Keep your account credentials secure")

            sectionHeader("6. Content Rights")
            sectionText("You retain ownership of your content, but grant SideQuest a license to display, distribute, and moderate it as necessary to operate the service.")

            sectionHeader("7. Account Termination")
            sectionText("We may terminate or suspend your account immediately for violations of these Terms, including posting objectionable content or engaging in abusive behavior.")

            sectionHeader("8. Disclaimer")
            sectionText("SideQuest is provided \"as is\" without warranties. We are not responsible for user-generated content or interactions between users.")

            sectionHeader("9. Changes to Terms")
            sectionText("We may update these Terms at any time. Continued use of the app constitutes acceptance of updated Terms.")

            sectionHeader("10. Contact")
            sectionText("For questions about these Terms or to report violations, contact us through the app's Settings.")

            Divider()
                .padding(.vertical, 8)

            Text("By clicking \"I Agree\" below, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.semibold)
            .padding(.top, 4)
    }

    private func sectionText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.primary)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(.leading, 8)
    }

    private var agreementCheckbox: some View {
        Button {
            hasAgreed.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: hasAgreed ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(hasAgreed ? .blue : .secondary)

                Text("I have read and agree to the Terms of Service")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()
            }
        }
        .buttonStyle(.plain)
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var continueButton: some View {
        Button {
            acceptTermsAndContinue()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(canContinue ? Color.blue : Color.gray.opacity(0.5))
                    .frame(height: 48)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("I Agree & Continue")
                        .foregroundColor(.white)
                        .font(.headline.bold())
                }
            }
        }
        .disabled(!canContinue || isLoading)
        .padding(.horizontal, 4)
    }

    private var canContinue: Bool {
        hasScrolledToBottom && hasAgreed
    }

    private func acceptTermsAndContinue() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                // Record terms acceptance in database
                try await SupabaseManager.shared.recordUserAgreement(
                    agreementType: "terms_of_service",
                    version: "1.0"
                )

                isLoading = false
                onCompletion()

            } catch {
                errorMessage = "Failed to save agreement. Please try again."
                isLoading = false
                print("Error recording terms agreement: \(error)")
            }
        }
    }
}

// Helper for scroll position tracking
struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    TermsOfServiceView {
        print("Terms accepted")
    }
}
