

import SwiftUI

struct SocialSheet: View {
    @Environment(\.modelContext) var modelContext
    @State var tabBarItems: [tabBarItem] = [
        tabBarItem(title: "notifications"), tabBarItem(title: "people"),
    ]
    @State var separatorIndex: Int = 12

    @Environment(\.dismiss) var dismiss

    @State var tabBarViewIndex = 0
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.pathwayBold(20))
                        .foregroundColor(.primary)
                }
                Spacer()
                Button(action: {
                    tabBarViewIndex = 0
                }) {
                    HStack(spacing: 12) {
                        Text(tabBarItems[0].title).kerning(1)
                            .font(.pathwaySemiBold(18))
                            .foregroundColor(
                                tabBarViewIndex == 0
                                    ? .primary : Color(.systemGray2)
                            )
                            .padding(.horizontal, 2)
                            .overlay(alignment: .topTrailing) {
                                if let badgeCount = tabBarItems[0]
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
                                    tabBarViewIndex = 0
                                }
                            }

                        if separatorIndex == 0 {
                            Rectangle()
                                .fill(Color.taskapeOrange)
                                .frame(width: 3.5, height: 16)
                        }
                    }
                }
                Button(action: {
                    tabBarViewIndex = 1
                }) {
                    HStack(spacing: 12) {
                        Text(tabBarItems[1].title).kerning(1)
                            .font(.pathwaySemiBold(18))
                            .foregroundColor(
                                tabBarViewIndex == 1
                                    ? .primary : Color(.systemGray2)
                            )
                            .padding(.horizontal, 2)
                            .overlay(alignment: .topTrailing) {
                                if let badgeCount = tabBarItems[1]
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
                                    tabBarViewIndex = 1
                                }
                            }

                        if separatorIndex == 1 {
                            Rectangle()
                                .fill(Color.taskapeOrange)
                                .frame(width: 3.5, height: 16)
                        }
                    }
                }
                Spacer()
            }.padding(.top, 12)
                .padding(.bottom, 10).padding(.horizontal, 16)

            switch tabBarViewIndex {
            case 0:
                NotificationView().modelContext(modelContext)
            case 1:
                FriendSearchView().modelContext(modelContext)
            default:
                EmptyView()
            }

            Spacer()
        }

        .toolbar(.hidden).navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SocialSheet()
}
