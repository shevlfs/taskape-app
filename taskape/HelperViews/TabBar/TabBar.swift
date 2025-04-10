import SwiftUI

struct tabBarItem {
    let title: String
    var badgeCount: Int?
    var color: Color?

    init(title: String) {
        self.title = title
    }

    init(title: String, color: String) {
        self.title = title
        self.color = Color(hex: color)
    }

    init(title: String, badgeCount: Int, color: Color) {
        self.title = title
        self.color = color
        self.badgeCount = badgeCount
    }

    init(title: String, badgeCount: Int) {
        self.title = title
        self.badgeCount = badgeCount
    }
}

struct tabBarItemView: View {
    @Binding var title: String
    var body: some View {
        Text(title).kerning(1)
            .font(.pathwaySemiBold(18))
    }
}

struct TabBarView: View {
    @Binding var tabBarItems: [tabBarItem]
    @Binding var tabBarViewIndex: Int
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
                                        ? .primary : Color(.systemGray2)
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
            }.onChange(
                of: tabBarViewIndex
            ) { _, newValue in
                withAnimation {
                    scrollView.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
}

extension View {
    func fadeOutSides(fadeLength: CGFloat = 50) -> some View {
        mask(
            HStack(spacing: 0) {
                LinearGradient(
                    gradient: Gradient(
                        colors: [Color.black.opacity(0), Color.black]),
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(height: fadeLength)

                Rectangle().fill(Color.black)

                LinearGradient(
                    gradient: Gradient(
                        colors: [Color.black, Color.black.opacity(0)]),
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: fadeLength)
            }
        )
    }
}

struct MainMenuTabBarView: View {
    @Binding var tabBarItems: [tabBarItem]
    @Binding var tabBarViewIndex: Int
    @State var inviteCount = 0
    var separatorIndex: Int = 1
    @Binding var showGroupSheet: Bool

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
                                        ? .primary : Color(.systemGray2)
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

                    Button(action: {
                        showGroupSheet = true
                    }) {
                        HStack(spacing: 12) {
                            Text("\(Image(systemName: "plus"))")
                                .foregroundColor(.primary)
                                .font(.system(size: 18, weight: .bold))
                                .padding(.horizontal, 2)
                                .overlay(alignment: .topTrailing) {
                                    if inviteCount > 0 {
                                        NotificationBadge(
                                            badgeCount: $inviteCount
                                        )
                                        .offset(x: 10, y: -10)
                                    }
                                }
                                .padding(.vertical, 2)
                        }
                    }.buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)

            }.onChange(
                of: tabBarViewIndex
            ) { _, newValue in
                withAnimation {
                    scrollView.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
}
