import Foundation
import Observation

@MainActor
@Observable
class FollowListViewModel {
    var users: [OtherProfile] = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    let userId: UUID
    let listType: FollowListType
    
    enum FollowListType {
        case followers
        case following
    }
    
    init(userId: UUID, listType: FollowListType) {
        self.userId = userId
        self.listType = listType
    }
    
    func fetchUsers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            switch listType {
            case .followers:
                users = try await SupabaseManager.shared.fetchFollowersList(userId: userId)
            case .following:
                users = try await SupabaseManager.shared.fetchFollowingList(userId: userId)
            }
        } catch {
            errorMessage = "Failed to load users: \(error.localizedDescription)"
            print("Error fetching follow list: \(error)")
        }
        
        isLoading = false
    }
}