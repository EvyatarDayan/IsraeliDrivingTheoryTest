//
//  ContentView.swift
//  IsraeliDrivingTheoryTest
//
//  Created by EVYATAR DAYAN on 06/04/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var showLanguageSelection = false
    
    var body: some View {
        Group {
            if showLanguageSelection {
                NavigationStack {
                    WelcomeView()
                        .navigationBarHidden(true)
                }
            } else {
                LogoView {
                    showLanguageSelection = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
