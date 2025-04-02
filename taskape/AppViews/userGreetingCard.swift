import CachedAsyncImage
import SwiftData
import SwiftUI

struct UserGreetingCard: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var friendManager = FriendManager.shared
    @Binding var user: taskapeUser?
    @Namespace var namespace

    var body: some View {
        HStack(spacing: 0) {
            // Profile image section
            if let user = user {
                NavigationLink(destination: {
                    UserSelfProfileView(userId: user.id)
                        .toolbar(.hidden).modelContext(modelContext)
                        .navigationTransition(
                            .zoom(sourceID: "selfProfile", in: namespace))
                }) {
                    HStack {
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(width: 80, height: 80)
                            .background(
                                CachedAsyncImage(
                                    url: URL(string: user.profileImageURL)
                                ) { phase in
                                    switch phase {
                                    case .failure:
                                        Image(systemName: "photo")
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    default:
                                        ProgressView()
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .inset(by: 0.50)
                                    .stroke(
                                        Color(uiColor: UIColor.systemBackground)
                                    )
                            )

                        // Greeting text
                        HStack(spacing: 4) {
                            Text("whats up, ")
                                .font(.pathway(18))
                                .foregroundColor(.primary).lineLimit(1)
                                .minimumScaleFactor(0.01)

                            Text("\(user.handle)?")
                                .font(.pathwayBlack(24)).lineLimit(1)
                                .foregroundColor(.primary).minimumScaleFactor(
                                    0.01)
                        }.padding(.vertical)
                            .padding(.leading, 10)

                    }.matchedTransitionSource(id: "selfProfile", in: namespace)
                }
                Spacer()
                NavigationLink(
                    destination: {
                        FriendSearchView()
                            .modelContext(modelContext)
                            .toolbar(.hidden)
                            .navigationTransition(
                                .zoom(sourceID: "friendSearch", in: namespace))
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "person.3.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48 / 1.15, height: 32 / 1.15)
                                .foregroundColor(.black)
                                .padding().matchedTransitionSource(
                                    id: "friendSearch", in: namespace)

                            if friendManager.incomingRequests.count > 0 {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 24 - 4, height: 24 - 4)

                                    Text(
                                        "\(friendManager.incomingRequests.count)"
                                    )
                                    .font(.system(size: 14 - 2, weight: .bold))
                                    .foregroundColor(.white)
                                }
                                .offset(x: 2, y: -2)
                            }
                        }.padding(.top, 5)
                            .padding(.trailing, 16)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                    }

            } else {
                Text("Loading user...")
                    .padding()
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onAppear {
            user = UserManager.shared.getCurrentUser(context: modelContext)
        }
    }
}

//#Preview {
//    let config = ModelConfiguration(isStoredInMemoryOnly: true)
//    let container = try! ModelContainer(for: taskapeUser.self, configurations: config)
//
//    // Create and insert a mock user
//    let mockUser = taskapeUser(
//        id: "preview-user-id",
//        handle: "johndoe",
//        bio: "hello, world!",
//        profileImage: "https://picsum.photos/200",
//        profileColor: "#FF9500"
//    )
//
//    container.mainContext.insert(mockUser)
//    try! container.mainContext.save()
//
//    // Set the current user ID in UserManager
//    UserManager.shared.setCurrentUser(userId: mockUser.id)
//
//    return UserGreetingCard()
//        .modelContainer(container)
//}
