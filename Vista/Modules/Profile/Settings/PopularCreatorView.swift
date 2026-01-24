//
//  PopularCreatorView.swift
//  Vista
//
//  View for becoming a Popular Creator
//

import SwiftUI

struct PopularCreatorView: View {
    @Bindable var profileVm: ProfileViewModel
    @State private var vm = PopularCreatorViewModel()
    @State private var showEmailTemplate = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                if profileVm.isPopular {
                    alreadyPopularSection
                } else {
                    benefitsSection
                    requirementsSection
                    emailApplicationSection
                    disclaimerSection
                }
            }
            .padding()
        }
        .navigationTitle("Popular Creator")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let userId = profileVm.userId {
                await vm.fetchAccountCreationDate(userId: userId)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Become a Popular Creator")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Reach more travelers")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var alreadyPopularSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 8) {
                    Text("You're a Popular Creator!")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Your reviews appear in the Popular Feed for all SideQuest users")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Benefits")
                .font(.headline)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 10) {
                benefitRow(icon: "star.fill", text: "Your reviews appear in the Popular Feed")
                benefitRow(icon: "eye.fill", text: "Increased visibility to all SideQuest users")
                benefitRow(icon: "map.fill", text: "Help more travelers discover great spots")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)

            Spacer()
        }
    }

    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Progress")
                .font(.headline)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                requirementRow(
                    label: "Followers",
                    current: profileVm.followerCount,
                    required: vm.requiredFollowers,
                    isMet: vm.meetsFollowerRequirement(currentFollowers: profileVm.followerCount)
                )

                requirementRow(
                    label: "Spots Rated",
                    current: profileVm.spotsReviewed,
                    required: vm.requiredSpotsRated,
                    isMet: vm.meetsSpotsRatedRequirement(currentSpotsRated: profileVm.spotsReviewed)
                )

                daysActiveRow(
                    label: "Account Active",
                    current: vm.daysActive(),
                    required: vm.requiredDaysActive,
                    isMet: vm.meetsDaysActiveRequirement()
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    private func requirementRow(label: String, current: Int, required: Int, isMet: Bool) -> some View {
        HStack {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(current) / \(required) \(isMet ? "✓" : "")")
                    .font(.caption)
                    .foregroundColor(isMet ? .green : .secondary)
            }

            Spacer()
        }
    }

    private func daysActiveRow(label: String, current: Int, required: Int, isMet: Bool) -> some View {
        HStack {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(current) days / \(required) days \(isMet ? "✓" : "")")
                    .font(.caption)
                    .foregroundColor(isMet ? .green : .secondary)
            }

            Spacer()
        }
    }

    private var emailApplicationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next Step: Email Application")
                .font(.headline)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 16) {
                Text("Once you meet all requirements above, email us to apply:")
                    .font(.subheadline)

                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.purple)

                    Text("sidequest.app.travel@gmail.com")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)

                Button(action: {
                    showEmailTemplate.toggle()
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("View Email Template")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                }

                if showEmailTemplate {
                    emailTemplateView
                }

                if vm.meetsAllRequirements(followers: profileVm.followerCount, spotsRated: profileVm.spotsReviewed) {
                    Button(action: {
                        openEmail()
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Open Email App")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                            Text("Complete all requirements before applying")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }

                        Text("Keep creating quality content! You're on your way.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    private var emailTemplateView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Email Template")
                .font(.subheadline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                templateSection(label: "Subject:", content: "Popular Creator Application - \(profileVm.username)")

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Hi SideQuest Team,")

                    Text("My username is **\(profileVm.username)** and I'd like to apply for Popular Creator status.")

                    Text("**Why I want to be a popular creator:**")
                    Text("[Write 2-3 sentences about your motivation]")
                        .italic()
                        .foregroundColor(.secondary)

                    Text("**What makes my recommendations valuable:**")
                    Text("[Describe your travel expertise - regions you know well, travel style you specialize in, etc.]")
                        .italic()
                        .foregroundColor(.secondary)

                    Text("Thanks for considering my application!")

                    Text("[Your Name]")
                        .italic()
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }

    private func templateSection(label: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
            Text(content)
                .font(.caption)
        }
    }

    private var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)

                Text("Important")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }

            Text("Requirements are subject to change. Only email after meeting all current requirements listed above. Some exceptions made for early users")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }

    private func openEmail() {
        let subject = "Popular Creator Application - \(profileVm.username)"
        let body = """
        Hi SideQuest Team,

        My username is \(profileVm.username) and I'd like to apply for Popular Creator status.

        Why I want to be a popular creator:
        [Write 2-3 sentences about your motivation]

        What makes my recommendations valuable:
        [Describe your travel expertise - regions you know well, travel style you specialize in, etc.]

        My best recommendations:
        1. [City Name] - [Spot Name] - [Brief note]
        2. [City Name] - [Spot Name] - [Brief note]
        3. [City Name] - [Spot Name] - [Brief note]

        Thanks for considering my application!

        [Your Name]
        """

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:sidequest.app.travel@gmail.com?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NavigationStack {
        PopularCreatorView(profileVm: ProfileViewModel())
    }
}
