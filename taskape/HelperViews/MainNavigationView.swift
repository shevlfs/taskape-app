//
//  MainNavigationView.swift
//  taskape
//
//  Created by shevlfs on 2/5/25.
//

import SwiftUI

struct selfProfileView: View {
    @Binding var username: String
    @Binding var image: Data?
    var body: some View {
        HStack {

            Image(systemName: "star").font(.system(size: 25)).padding([.leading]
            )

            HStack {
                Text("ooga-booga,").font(.pathway(16))
                Text("\(username)").font(.pathwayBlack(16))
            }.padding(.leading, 15)
            Spacer()
        }.padding(.top)
    }
}

struct MainNavigationView: View {
    @State var selectedTabIndex: Int = 1
    @State var tabBarItems: [tabBarItem] = [
        tabBarItem(title: "settings"),
        tabBarItem(title: "main"),
    ]

    @State var user: taskapeUser  // before this precompute this value so that we just get updates on this view, also make this a binding !!!!!!

    var body: some View {
        VStack {
            selfProfileView(
                username: $user.handle,
                image: $user.profileImageData
            )
            TabBarView(
                tabBarItems: $tabBarItems, tabBarViewIndex: $selectedTabIndex
            )
            Spacer()
            Text("dsgfs")
        }
    }
}

#Preview {
    var user: taskapeUser = taskapeUser(
        id: UUID().uuidString,
        handle: "shevlfs",
        bio: "i am shevlfs",
        profileColor: "blue"
    )
    MainNavigationView(user: user)
}
