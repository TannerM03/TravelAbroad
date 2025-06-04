//
//  ContentView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 5/19/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = CityListViewModel()

    var body: some View {
        
        Text("Hello, world")
    }
}

#Preview {
    ContentView()
}
