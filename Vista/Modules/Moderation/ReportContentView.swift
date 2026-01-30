//
//  ReportContentView.swift
//  Vista
//
//  View for reporting objectionable content
//

import SwiftUI

struct ReportContentView: View {
    @Environment(\.dismiss) var dismiss

    let reportedUserId: UUID
    let contentType: String // "comment", "profile", "recommendation"
    let contentId: UUID
    let contentPreview: String? // Optional preview text for context

    @State private var selectedReason: ReportReason = .spam
    @State private var additionalDetails: String = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let preview = contentPreview {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reporting:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(preview)
                                .font(.subheadline)
                                .lineLimit(3)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                }

                Section {
                    Picker("Reason", selection: $selectedReason) {
                        ForEach(ReportReason.allCases) { reason in
                            Text(reason.rawValue)
                                .tag(reason)
                        }
                    }
                    .pickerStyle(.menu)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedReason.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Reason for Report")
                }

                Section {
                    TextField("Additional details (optional)", text: $additionalDetails, axis: .vertical)
                        .lineLimit(3 ... 6)
                } header: {
                    Text("Additional Information")
                } footer: {
                    Text("Help us understand the issue by providing more context.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Reports are reviewed within 24 hours", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Label("You will not see content from reported users", systemImage: "eye.slash")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Label("False reports may result in action against your account", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Report Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        submitReport()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Submit")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
            .alert("Report Submitted", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for helping keep Vista safe. We'll review this report within 24 hours.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func submitReport() {
        Task {
            isSubmitting = true

            do {
                let details = additionalDetails.isEmpty ? nil : additionalDetails

                try await SupabaseManager.shared.reportContent(
                    reportedUserId: reportedUserId,
                    contentType: contentType,
                    contentId: contentId,
                    reason: selectedReason.rawValue,
                    details: details
                )

                isSubmitting = false
                showSuccess = true

            } catch {
                isSubmitting = false
                errorMessage = "Failed to submit report. Please try again."
                showError = true
                print("Error submitting report: \(error)")
            }
        }
    }
}

#Preview {
    ReportContentView(
        reportedUserId: UUID(),
        contentType: "comment",
        contentId: UUID(),
        contentPreview: "This is a sample comment that contains objectionable content."
    )
}
