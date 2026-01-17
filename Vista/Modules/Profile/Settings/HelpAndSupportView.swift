//
//  HelpAndSupportView.swift
//  Vista
//
//  Created by Tanner Macpherson on 1/17/26.
//

import SwiftUI

struct HelpAndSupportView: View {
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("sidequest.app.travel@gmail.com")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: {
                        UIPasteboard.general.string = "sidequest.app.travel@gmail.com"
                    }) {
                        Text("Copy")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            } header: {
                Text("Contact Email Address")
            } footer: {
                Text("Vista is run by a college student. Please be patient and expect responses within 2 business days. I'll do my best to accommodate your requests and resolve any issues as quickly as possible. Thank you for your understanding!")
                    .font(.caption)
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    private func openEmail(subject: String, body: String) {
        let email = "sidequest.app.travel@gmail.com"
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:\(email)?subject=\(subjectEncoded)&body=\(bodyEncoded)") {
            UIApplication.shared.open(url)
        }
    }
}
