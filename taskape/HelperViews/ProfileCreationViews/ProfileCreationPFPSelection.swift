import PhotosUI
import SwiftData
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
    @Environment(\.modelContext) private var modelContext
    @Binding var imageurl: String
    @State var image: UIImage?
    @Binding var path: NavigationPath
    @Binding var progress: Float
    @State private var isUploading = false
    @State private var showError = false

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

            Button(action: {
                handleImageUpload()
            }) {
                taskapeContinueButton()
            }.overlay(
                ProgressView()
                    .progressViewStyle(
                        CircularProgressViewStyle()
                    ).opacity(isUploading ? 1 : 0).offset(y: -50),
                alignment: .top
            )
            .buttonStyle(PlainButtonStyle())
            .disabled(image == nil || isUploading)

            Text("this will help others recognize you\n in the community")
                .multilineTextAlignment(.center)
                .font(.pathwayItalic(16))
                .padding()
        }
        .alert("Upload Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Failed to upload your profile picture. Please try again.")
        }
    }

    private func handleImageUpload() {
        isUploading = true

        Task {
            do {
                print("upload image called")
                let url = try await uploadImage(image!)

                await MainActor.run {
                    isUploading = false

                    if !url.isEmpty {
                        UserDefaults.standard.set(
                            url, forKey: "profile_picture_url")
                    } else {
                        showError = true
                    }
                }

                let response = try await registerProfile(
                    handle: UserDefaults.standard
                        .string(forKey: "handle") ?? "",
                    bio: UserDefaults.standard.string(forKey: "bio") ?? "",
                    color: UserDefaults.standard.string(forKey: "color") ?? "",
                    profilePictureURL: url,
                    phone: UserDefaults.standard.string(forKey: "phone") ?? ""
                )
                imageurl = url

                await MainActor.run {
                    isUploading = false
                    if response.success {
                        let userId = String(response.id)
                        UserDefaults.standard.set(
                            userId, forKey: "user_id")
                        print("Set user_id to: \(userId)")
                        path.append(
                            "task_addition"
                        )
                        progress += 1 / 5
                    } else {
                        showError = true
                    }
                }

            } catch {
                await MainActor.run {
                    isUploading = false
                    showError = true
                }
            }
        }
    }
}

//#Preview {
//    @Previewable @State var image: UIImage? = nil
//    @Previewable @State var path = NavigationPath()
////    ProfileCreationPFPSelectionView(
////        image: $image,
////        path: $path,
////        progress: .constant(0.3)
////    )
//}
