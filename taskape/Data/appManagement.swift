//
//  AppManagement.swift
//  taskape
//
//  Created by shevlfs on 1/7/25.
//
import Foundation
import Combine

class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUserHandle: String?
}
