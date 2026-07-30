//
//  ContentView.swift
//  Huhgry?
//
//  Hackathon frontend shell — mock data only, no backend.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                TinderSwipe()
            } else {
                OnboardingView {
                    withAnimation(.smooth(duration: 0.4)) {
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
        .animation(.smooth(duration: 0.4), value: hasCompletedOnboarding)
    }
}

#Preview {
    ContentView()
}
