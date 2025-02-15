//
//  ProfileCreationBioInputView.swift
//  taskape
//
//  Created by shevlfs on 1/28/25.
//

import SwiftUI

struct taskapeBioField: View {
    @Binding var bio: String
    @FocusState var isFocused: Bool
    @State var viewBio = "tell us a bit about yourself..."
    @State var foregroundColor: Color = Color(UIColor.systemGray2)

    func bioFormatter(input: String) -> String {
        return String(input.prefix(60))
    }

    var body: some View {
        TextEditor(text: $viewBio).focused($isFocused).onChange(of: isFocused) {
            if !isFocused && viewBio.isEmpty {
                viewBio = "tell us a bit about yourself..."
                foregroundColor = Color(UIColor.systemGray2)
            } else {
                viewBio = ""
                foregroundColor = Color.primary
            }
        }
        .onChange(
            of: viewBio
        ) {
            viewBio = self.bioFormatter(input: viewBio)
            if viewBio != "tell us a bit about yourself..." {
                bio = viewBio
            }
        }.padding(15).multilineTextAlignment(.center).foregroundColor(
            foregroundColor
        )
        .accentColor(.taskapeOrange).scrollContentBackground(.hidden)
        .autocorrectionDisabled()
        .autocapitalization(.none).padding(.horizontal, 30)
        .font(.pathwayBlack(20))
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(.regularMaterial)
                .stroke(.thinMaterial, lineWidth: 1)
        ).frame(maxWidth: 360, maxHeight: 150)
    }
}

struct ProfileCreationBioInputView: View {
    @Binding var bio: String
    @Binding var path: NavigationPath
    @Binding var progress: Float
    var body: some View {
        VStack {
            ProfileCreationProgressBar(progress: $progress)
            Text("anything special about you?")
                .multilineTextAlignment(.center)
                .font(.pathway(30))
                .padding()

            Spacer()

            taskapeBioField(bio: $bio)

            Spacer()

            Button(
                action: {
                    if addUserBioSuccess(bio: bio) {
                        path.append("color_selection")
                        progress += 1 / 5
                    }
                }) {
                    taskapeContinueButton()
                }.buttonStyle(PlainButtonStyle())

            Text("of course, you can be mysterious\n and keep this to yourself")
                .multilineTextAlignment(
                    .center
                )
                .font(.pathwayItalic(16))
                .padding()

        }
    }
}

#Preview {
    @Previewable @State var bio: String = ""
    @Previewable @State var path = NavigationPath()
    ProfileCreationBioInputView(
        bio: $bio,
        path: $path, progress: .constant(0.3)
    )
}
