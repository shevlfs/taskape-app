//
//  AppStateManager.swift
//  taskape
//
//  Created by shevlfs on 3/19/25.
//

import Foundation
import SwiftUI

class AppStateManager: ObservableObject {
    @Published var isLoggedIn: Bool
    
    init() {
        // Initialize based on stored values
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "profileExists") && 
                          UserDefaults.standard.string(forKey: "authToken") != nil
    }
    
    func logout() {
        // Clear authentication data
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        UserDefaults.standard.set(false, forKey: "profileExists")
        
        // Update the published state
        DispatchQueue.main.async {
            self.isLoggedIn = false
        }
    }
    
    func login() {
        DispatchQueue.main.async {
            self.isLoggedIn = true
        }
    }
}
