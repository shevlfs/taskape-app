//
//  ProfileCreationRoot.swift
//  taskape
//
//  Created by shevlfs on 1/27/25.
//

import SwiftUI

struct ProfileCreationProgressBar: View {
    @Binding var progress: Float
    var body: some View {
        ProgressView(value: progress)
            .accentColor(Color.taskapeOrange)
            .padding().shadow(radius: 1.5).animation(
                .bouncy(duration: 0.35), value: progress)
    }
}

struct taskapeHandleField: View {
    @Binding var handle: String

    func handleFormatter(input: String) -> String {
        let alphanumerics = CharacterSet.alphanumerics
        let filtered = input.unicodeScalars.filter {
            alphanumerics.contains($0)
        }.map(String.init).joined()
        return "@" + filtered.prefix(18)
    }

    var body: some View {
        TextField("handle goes here", text: $handle).onChange(of: handle) {
            handle = self.handleFormatter(input: handle)
        }.padding(15)
            .accentColor(.taskapeOrange)
            .autocorrectionDisabled()
            .autocapitalization(.none)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 270)
            .font(.pathwayBlack(20))
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(.regularMaterial)
                    .stroke(.thinMaterial, lineWidth: 1)
            )
    }
}

struct ProfileCreationHandleInputView: View {
    @Binding var handle: String
    @Binding var path: NavigationPath
    @Binding var progress: Float

    @State var displayError: Bool = false

    var body: some View {

        VStack {
            Text("so, what should your @ be?")
                .multilineTextAlignment(.center)
                .font(.pathway(30))
                .padding()

            Spacer()

            taskapeHandleField(handle: $handle).overlay(
                Text("such username already exists")
                    .font(.pathway(15))
                    .offset(y: 80)
                    .foregroundColor(Color.taskapeOrange).opacity(
                        displayError ? 1 : 0))

            Spacer()

            Button(
                action: {
                    if addUserHandleSuccess(handle: handle) {
                        path.append("bio_input")
                        progress += 1 / 3
                    } else {
                        displayError = true
                    }
                }) {
                    taskapeContinueButton()
                }.buttonStyle(.plain).disabled(Bool(handle.count < 4))

            Text("P.S. they are unique to each profile").multilineTextAlignment(
                .center
            )
            .font(.pathwayItalic(16))
            .padding()
        }.navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    @Previewable @State var handle: String = ""
    @Previewable @State var path = NavigationPath()
    @Previewable @State var progress: Float = 0
    ProfileCreationHandleInputView(
        handle: .constant(handle), path: .constant(path),
        progress: .constant(progress))
}
