import SwiftUI

struct FollowListView: View {
    @State private var vm: FollowListViewModel

    init(userId: UUID, listType: FollowListViewModel.FollowListType) {
        _vm = State(initialValue: FollowListViewModel(userId: userId, listType: listType))
    }

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = vm.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if vm.users.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: vm.listType == .followers ? "person.2.slash" : "person.slash")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(vm.listType == .followers ? "No followers yet" : "Not following anyone yet")
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(vm.users, id: \.id) { user in
                            NavigationLink {
                                OtherProfileView(selectedUserId: user.id.uuidString)
                            } label: {
                                ProfileCardView(profile: user)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(vm.listType == .followers ? "Followers" : "Following")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.fetchUsers()
        }
    }
}
