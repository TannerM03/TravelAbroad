//
//  LoginViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/22/25.
//

import Foundation
import Supabase

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isSignUp: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var username: String = ""

    func authAction() async -> Bool {
        errorMessage = nil
        isLoading = true
        do {
            if isSignUp {
                try await SupabaseManager.shared.supabase.auth.signUp(email: email, password: password)
                try await SupabaseManager.shared.insertUsername(username: username)
            } else {
                try await SupabaseManager.shared.supabase.auth.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
        isLoading = false
        return true
    }
}
