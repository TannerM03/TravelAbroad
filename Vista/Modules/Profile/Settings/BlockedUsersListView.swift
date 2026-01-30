//
//  BlockedUsersListView.swift
//  Vista
//
//  View for managing blocked users
//

import SwiftUI

struct BlockedUsersListView: View {
    @Binding var blockedUsers: [(id: UUID, username: String)]
    @State private var showUnblockConfirmation = false
    @State private var userToUnblock: (id: UUID, username: String)?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            if blockedUsers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "hand.raised.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No Blocked Users")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Users you block will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .listRowBackground(Color.clear)
            } else {
                ForEach(blockedUsers, id: \.id) { user in
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 24)

                        Text("@\(user.username)")
                            .font(.subheadline)

                        Spacer()

                        Button {
                            userToUnblock = user
                            showUnblockConfirmation = true
                        } label: {
                            Text("Unblock")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Unblock User?",
            isPresented: $showUnblockConfirmation,
            titleVisibility: .visible
        ) {
            Button("Unblock") {
                if let user = userToUnblock {
                    Task {
                        await unblockUser(user)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let user = userToUnblock {
                Text("You will see content from @\(user.username) again.")
            }
        }
    }

    private func unblockUser(_ user: (id: UUID, username: String)) async {
        do {
            try await BlockListManager.shared.unblockUser(user.id)

            await MainActor.run {
                blockedUsers.removeAll { $0.id == user.id }
                userToUnblock = nil
            }
        } catch {
            print("Error unblocking user: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        BlockedUsersListView(blockedUsers: .constant([
            (id: UUID(), username: "testuser1"),
            (id: UUID(), username: "testuser2"),
        ]))
    }
}
