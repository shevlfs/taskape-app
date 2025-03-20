import SwiftUI

struct FriendInvitationButtons: View {
    var onApeTap: () -> Void
    var onNewFriendTap: () -> Void

    var body: some View {
        HStack(spacing: 15) {
            // Left button - "ape-ify your friends' lives today!"
            Button(action: onApeTap) {
                ZStack(alignment: .leading) {
                    MenuItem(
                        mainColor: Color(hex: "#FF7AAD"),
                        widthProportion: 0.56,
                        heightProportion: 0.16
                    )

                    HStack(alignment: .center, spacing: 10) {
                        // Emojis on the left
                        VStack {
                            Text("🐒")
                                .font(.system(size: 50))
                        }.padding(.leading, 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("ape-ify")
                                .font(.pathwayBlack(21))
                            Text("your friends'\nlives today!")
                                .font(.pathwaySemiBold(19))

                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Right button - "new friend?"
            Button(action: onNewFriendTap) {
                ZStack {
                    // Background using MenuItem component
                    MenuItem(
                        mainColor: Color(hex: "#E97451"),
                        widthProportion: 0.32,
                        heightProportion: 0.16
                    )

                    VStack(alignment: .center, spacing: 6) {

                        Image(systemName: "plus.circle")
                            .font(.system(size: 45, weight: .medium))
                            .foregroundColor(.primary)

                        Text("new\nfriend?")
                            .font(.pathwaySemiBold(19))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack {
        Spacer()
        FriendInvitationButtons(
            onApeTap: {
                print("Ape-ify tapped!")
                // Add your action here
            },
            onNewFriendTap: {
                print("New friend tapped!")
                // Add your action here
            }
        )
        Spacer()
    }
    .background(Color(UIColor.systemBackground))
}
