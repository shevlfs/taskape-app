

import Lottie
import SwiftUI

struct LoadingView: View {
    @Binding var path: NavigationPath
    @State var isLoading: Bool = true
    @State var showBar: Bool = true
    var body: some View {
        VStack {
            if showBar {
                ProfileCreationProgressBar(progress: .constant(1.0))
            }
            Spacer()
            Text("you are almost there").font(.pathway(25)).padding()
            LottieView(
                animation: .named(
                    "loadingwhite")
            ).configuration(
                LottieConfiguration(
                    renderingEngine: .automatic
                )
            ).looping().animationSpeed(0.75).frame(
                maxWidth: 200, maxHeight: 200
            )
            Spacer()
        }.onAppear(perform: load)
    }

    func load() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            path.append("task_addition")
        }
    }
}

#Preview {
    LoadingView(path: .constant(.init()), isLoading: true)
}
