//
//  ProfileViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/18/25.
//

import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var username: String = ""
}
