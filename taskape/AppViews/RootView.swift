//
//  RootView.swift
//  taskape
//
//  Created by shevlfs on 1/7/25.
//

import SwiftUI

struct RootView: View {
    @StateObject private var appState = AppState()
    var body: some View {
        if appState.isAuthenticated {
            MainView()
                .environmentObject(appState)
        } else {
            AuthenticationView()
                .onAppear {
                    Task {
                        await serverHandShake()
                    }
                }
                .environmentObject(appState)
        }
    }
}

#Preview {
    RootView()
}
