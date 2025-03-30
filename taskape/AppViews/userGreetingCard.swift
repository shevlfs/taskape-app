struct userGreetingCard: View {
    @Environment(\.modelContext) private var modelContext
    @State private var user: taskapeUser?

    var body: some View {
        HStack {
            if let user = user {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 60, height: 60)
                    .background(
                        CachedAsyncImage(url: URL(string: user.profileImageURL))
                        {
                            phase in
                            switch phase {
                            case .failure:
                                Image(systemName: "photo")
                            case .success(let image):
                                image.resizable()
                            default:
                                ProgressView()
                            }
                        }
                    )
                    .cornerRadius(106.50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 106.50)
                            .inset(by: 0.50)
                            .stroke(
                                Color(red: 0.46, green: 0.46, blue: 0.50)
                                    .opacity(
                                        0.12), lineWidth: 0.50
                            )
                    ).padding(.leading)

                HStack {
                    Text("ooga-booga,").font(.pathway(16))
                    Text("\(user.handle)").font(.pathwayBlack(16))
                }
            } else {
                EmptyView()
            }
            Spacer()
        }
        .onAppear {
            user = UserManager.shared.getCurrentUser(context: modelContext)
        }
    }
}