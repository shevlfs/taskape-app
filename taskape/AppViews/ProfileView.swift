//
//  ProfileView.swift
//  taskape
//
//  Created by shevlfs on 3/25/25.
//

import CachedAsyncImage
import SwiftData
import SwiftUI

struct SelfProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var user: taskapeUser

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with colored background
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .foregroundColor(Color(hex: user.profileColor))
                        .frame(maxWidth: .infinity, maxHeight: 250)

                    // Profile content on the colored background
                    VStack(alignment: .center, spacing: 16) {
                        // Profile picture
                        if !user.profileImageURL.isEmpty {
                            CachedAsyncImage(
                                url: URL(string: user.profileImageURL)
                            ) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    Color(
                                                        hex: user
                                                            .profileColor
                                                    )
                                                    .contrastingTextColor(
                                                        in: colorScheme),
                                                    lineWidth: 1
                                                )
                                                .shadow(radius: 3)
                                        )
                                case .failure:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.white.opacity(0.8))
                                default:
                                    ProgressView()
                                        .frame(width: 100, height: 100)
                                }
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .foregroundColor(.white.opacity(0.8))
                        }

                        // Username with contrasting color
                        Text("\(user.handle)")
                            .font(.pathwayBlack(25))
                            .foregroundColor(
                                Color(hex: user.profileColor)
                                    .contrastingTextColor(in: colorScheme))
                    }
                    .padding(.vertical, 30)
                }

                ZStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("about me:")
                            .font(.pathwayBold(18))
                            .foregroundColor(.white)
                            .padding(.top, 30)
                            .padding(.leading, 16)

                        Text(
                            user.bio
                        )
                        .font(.pathway(16))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        // Use a shape with only bottom corners rounded
                        CustomRoundedRectangle(
                            topLeadingRadius: 0, topTrailingRadius: 0,
                            bottomLeadingRadius: 16, bottomTrailingRadius: 16
                        )
                        .fill(Color.clear)
                        .overlay(
                            // Very subtle inner glow instead of a distinct outline
                            CustomRoundedRectangle(
                                topLeadingRadius: 0, topTrailingRadius: 0,
                                bottomLeadingRadius: 16,
                                bottomTrailingRadius: 16
                            )
                            .stroke(
                                Color(hex: user.profileColor),
                                lineWidth: 1
                            )
                            .blur(radius: 0.5)
                        )
                    )
                }
                .offset(y: -16)

                //                if !user.bio.isEmpty {
                //                    Group {
                //                        VStack(alignment: .leading, spacing: 8) {
                //                            Text("about me:")
                //                                .font(.pathwayBold(18))
                //                                .padding(.top, 20)
                //
                //                            Text(user.bio)
                //                                .font(.pathway(16))
                //                                .multilineTextAlignment(.center)
                //                                .fixedSize(horizontal: false, vertical: true)
                //                        }
                //                        .frame(maxWidth: .infinity, alignment: .leading)
                //                        .padding(.horizontal)
                //                    }.background(
                //                        RoundedRectangle(cornerRadius: 9).stroke(
                //                            Color.white, lineWidth: 2
                //                        ).foregroundColor(
                //                            Color.clear
                //                        ))
                //                }

                // Stats or task summary
                VStack(alignment: .leading, spacing: 16) {

                    HStack {
                        StatItem(
                            title: "tasks", value: "\(user.tasks.count)",
                            userColor: Color(hex: user.profileColor)
                        )
                        .padding(.horizontal)
                        Spacer()
                        StatItem(
                            title: "completed",
                            value:
                                "\(user.tasks.filter { $0.completion.isCompleted }.count)",
                            userColor: Color(hex: user.profileColor)
                        ).padding(.horizontal)
                        Spacer()
                        StatItem(
                            title: "pending",
                            value:
                                "\(user.tasks.filter { !$0.completion.isCompleted }.count)",
                            userColor: Color(hex: user.profileColor)
                        ).padding(.horizontal)
                    }
                    .padding(.vertical, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
        }
        .edgesIgnoringSafeArea(.top)
    }
}

// Helper view for stats items
struct StatItem: View {
    var title: String
    var value: String
    @State var userColor: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.pathwayBlack(20))
                .foregroundColor(userColor)

            Text(title)
                .font(.pathway(14))
                .foregroundColor(.secondary)
        }
    }
}

struct ProfileView: View {
    @Query private var users: [taskapeUser]
    @State var userID: Int = 0

    var body: some View {
        Group {
            if userID == 0 {
                SelfProfileView(user: users[userID])
            } else {
                Text("looking at a profile")
            }
        }
    }
}

struct CustomRoundedRectangle: Shape {
    var topLeadingRadius: CGFloat
    var topTrailingRadius: CGFloat
    var bottomLeadingRadius: CGFloat
    var bottomTrailingRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let topLeading = CGPoint(x: rect.minX, y: rect.minY + topLeadingRadius)
        let topTrailing = CGPoint(
            x: rect.maxX, y: rect.minY + topTrailingRadius)
        let bottomTrailing = CGPoint(
            x: rect.maxX, y: rect.maxY - bottomTrailingRadius)
        let bottomLeading = CGPoint(
            x: rect.minX, y: rect.maxY - bottomLeadingRadius)

        // Start from top-left
        path.move(to: topLeading)

        // Top edge (straight line if topLeadingRadius is 0)
        if topLeadingRadius > 0 {
            path.addArc(
                center: CGPoint(
                    x: rect.minX + topLeadingRadius,
                    y: rect.minY + topLeadingRadius),
                radius: topLeadingRadius,
                startAngle: Angle(degrees: 180),
                endAngle: Angle(degrees: 270),
                clockwise: false)
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        }

        // Top-right corner
        if topTrailingRadius > 0 {
            path.addLine(
                to: CGPoint(x: rect.maxX - topTrailingRadius, y: rect.minY))
            path.addArc(
                center: CGPoint(
                    x: rect.maxX - topTrailingRadius,
                    y: rect.minY + topTrailingRadius),
                radius: topTrailingRadius,
                startAngle: Angle(degrees: 270),
                endAngle: Angle(degrees: 0),
                clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }

        // Bottom-right corner
        if bottomTrailingRadius > 0 {
            path.addLine(
                to: CGPoint(x: rect.maxX, y: rect.maxY - bottomTrailingRadius))
            path.addArc(
                center: CGPoint(
                    x: rect.maxX - bottomTrailingRadius,
                    y: rect.maxY - bottomTrailingRadius),
                radius: bottomTrailingRadius,
                startAngle: Angle(degrees: 0),
                endAngle: Angle(degrees: 90),
                clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }

        // Bottom-left corner
        if bottomLeadingRadius > 0 {
            path.addLine(
                to: CGPoint(x: rect.minX + bottomLeadingRadius, y: rect.maxY))
            path.addArc(
                center: CGPoint(
                    x: rect.minX + bottomLeadingRadius,
                    y: rect.maxY - bottomLeadingRadius),
                radius: bottomLeadingRadius,
                startAngle: Angle(degrees: 90),
                endAngle: Angle(degrees: 180),
                clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }

        path.closeSubpath()
        return path
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: taskapeUser.self, taskapeTask.self, configurations: config)

        let user = taskapeUser(
            id: UUID().uuidString,
            handle: "shevlfs",
            bio:
                "i am shelfisi am shelfisi am shelfisi am shelfisi am shelfisi am shelfisi am shelfisi am shelfis",
            profileImage:
                "https://upload.wikimedia.org/wikipedia/en/5/5f/Original_Doge_meme.jpg",
            profileColor: "#7A57FE"
        )

        container.mainContext.insert(user)
        try container.mainContext.save()

        return Text("lol").sheet(isPresented: .constant(true)) {
            ProfileView(userID: 0).modelContainer(container)
        }
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}

extension Color {
    func contrastingTextColor(in colorScheme: ColorScheme? = nil) -> Color {
        #if canImport(UIKit)
            let uiColor = UIColor(self)
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0

            uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

            let luminance = 0.299 * r + 0.587 * g + 0.114 * b

            let isBlueish = b > 0.6 && b > r * 1.5 && b > g * 1.2

            var threshold = 0.5

            if colorScheme == .light && isBlueish {
                threshold = 0.65
            }

            else if colorScheme == .dark {
                threshold = 0.4
            }

            return luminance > threshold ? Color.black : Color.white
        #else
            return .white
        #endif
    }
}
