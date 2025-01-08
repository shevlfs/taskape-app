//
//  RollBar.swift
//  taskape
//
//  Created by shevlfs on 1/7/25.
//
import SwiftUI

struct tabBarItem {
    let title: String
    var badgeCount: Int? = nil

    init(title: String) {
        self.title = title
    }

    init(title: String, badgeCount: Int) {
        self.title = title
        self.badgeCount = badgeCount
    }
}

struct TabBarView: View {
    @Binding var tabBarItems: [tabBarItem]
    @State var tabBarViewIndex: Int = 0
    var separatorIndex: Int = 1

    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(tabBarItems.indices, id: \.self) { index in
                        HStack(spacing: 12) {
                            Text(tabBarItems[index].title).kerning(1)
                                .font(.pathwaySemiBold(18))
                                .foregroundColor(
                                    tabBarViewIndex == index
                                        ? .black : Color(.systemGray2)
                                )
                                .padding(.horizontal, 2)
                                .overlay(alignment: .topTrailing) {
                                    if let badgeCount = tabBarItems[index]
                                        .badgeCount
                                    {
                                        NotificationBadge(
                                            badgeCount: .constant(badgeCount)
                                        )
                                        .offset(x: 10, y: -10)
                                    }
                                }
                                .padding(.vertical, 2)
                                .onTapGesture {
                                    withAnimation(.easeInOut) {
                                        tabBarViewIndex = index
                                    }
                                }

                            if index == separatorIndex {
                                Rectangle()
                                    .fill(Color.taskapeOrange)
                                    .frame(width: 3.5, height: 16)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }.onChange(
                of: tabBarViewIndex
            ) { oldValue, newValue in
                withAnimation {
                    scrollView.scrollTo(newValue, anchor: .center)
                }
            }

        }
    }
}

#Preview {
    TabBarView(
        tabBarItems: .constant([
            tabBarItem(title: "settings"),
            tabBarItem(title: "main"),
            tabBarItem(title: "group1"),
            tabBarItem(title: "group2", badgeCount: 2),
            tabBarItem(title: "group3", badgeCount: 100),
        ])
    )
}
