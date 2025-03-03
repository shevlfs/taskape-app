//
//  MainNavigationView.swift
//  taskape
//
//  Created by shevlfs on 2/5/25.
//

import SwiftData
import SwiftUI
import CachedAsyncImage

struct selfProfileView: View {
    @State var user: taskapeUser?
    var body: some View {
        HStack {
            CachedAsyncImage(url: URL(string: user!.profileImageURL)) { phase in
                        switch phase {
                        case .failure:
                            Image(systemName: "photo")
                                .font(.largeTitle)
                        case .success(let image):
                            image
                                .resizable()
                        default:
                            ProgressView()
                        }
                    }
                    .frame(width: 256, height: 256)
            HStack {
                Text("ooga-booga,").font(.pathway(16))
                Text("\(user!.handle)").font(.pathwayBlack(16))
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

    @Environment(\.modelContext) private var modelContext
    @Query var currentUser: [taskapeUser]

    var body: some View {
        VStack {
            selfProfileView(
                user: currentUser.first!
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
        profileImage: "https://static.wikia.nocookie.net/character-stats-and-profiles/images/c/c7/DZuvg1d.png/revision/latest?cb=20181120135131",
        profileColor: "blue"
    )
}
