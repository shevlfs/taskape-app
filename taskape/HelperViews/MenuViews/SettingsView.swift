//
//  SettingsView.swift
//  taskape
//
//  Created by shevlfs on 3/5/25.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var users: [taskapeUser]

    var body: some View {
        VStack {
            Text("settings").font(.pathwayBold(2))
        }
    }
}

#Preview {
    SettingsView()
}
