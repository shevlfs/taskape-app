import PhotosUI
import SwiftUI

struct taskapeImagePicker: View {
    @Binding var selectedImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 20) {
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(radius: 2)
            } else {
                Circle()
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: 200, height: 200)
                    .overlay(
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(radius: 2)
            }

            PhotosPicker(
                selection: $photosPickerItem,
                matching: .images
            ) {
                Text("choose from library")
                    .font(.pathway(18))
                    .padding(.vertical, 15)
                    .padding(.horizontal, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.regularMaterial)
                            .stroke(.thinMaterial, lineWidth: 1)
                    )
            }.buttonStyle(.plain)
        }
        .onChange(of: photosPickerItem) { _, newValue in
            Task {
                if let imageData = try? await newValue?.loadTransferable(
                    type: Data.self),
                    let image = UIImage(data: imageData)
                {
                    selectedImage = image
                }
            }
        }
    }
}

struct ProfileCreationPFPSelectionView: View {
    @Binding var image: UIImage?
    @Binding var path: NavigationPath
    @Binding var progress: Float

    var body: some View {
        VStack {
            ProfileCreationProgressBar(progress: $progress)
            Text("what do you look like?")
                .multilineTextAlignment(.center)
                .font(.pathway(30))
                .padding()

            Spacer()

            taskapeImagePicker(selectedImage: $image)

            Spacer()

            Button(
                action: {
                    if addUserPFPSuccess(image: image) {
                        path.append("completion")
                        progress += 1 / 3
                    }
                }) {
                    taskapeContinueButton()
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(image == nil)

            Text("this will help others recognize you\n in the community")
                .multilineTextAlignment(.center)
                .font(.pathwayItalic(16))
                .padding()
        }
    }
}

#Preview {
    @Previewable @State var image: UIImage? = nil
    @Previewable @State var path = NavigationPath()
    ProfileCreationPFPSelectionView(
        image: $image,
        path: $path,
        progress: .constant(0.3)
    )
}
