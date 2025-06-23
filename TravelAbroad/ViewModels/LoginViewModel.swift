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
    
}
