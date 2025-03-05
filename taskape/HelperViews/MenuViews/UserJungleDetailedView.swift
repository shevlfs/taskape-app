//
//  UserJungleDetailedView.swift
//  taskape
//
//  Created by shevlfs on 3/5/25.
//

import SwiftData
import SwiftUI

struct UserJungleDetailedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var users: [taskapeUser]
    @Query var tasks: [taskapeTask]

    var body: some View {
        ScrollView {
            LazyVStack {

            }
        }
    }
}

#Preview {
    UserJungleDetailedView()
}
