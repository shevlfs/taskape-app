







import SwiftUI
import Lottie

struct AnimatedLogoView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {

            LottieView(
                animation: .named(
                    colorScheme == .dark
                        ? "loadingblack" : "loadingwhite")
            ).configuration(
                LottieConfiguration(
                    renderingEngine: .automatic
                )
            ).looping().backgroundBehavior(.pauseAndRestore).ignoresSafeArea(.all).edgesIgnoringSafeArea(.all).frame(maxWidth:.infinity, maxHeight:.infinity).scaledToFill()

    }
}

#Preview{
    AnimatedLogoView()
}
