

import PhotosUI
import SwiftData
import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let userId: String
    @State private var handle: String = ""
    @State private var bio: String = ""
    @State private var profileColor: String = ""
    @State private var profileImageURL: String = ""

    @State private var isLoading: Bool = false
    @State private var isSaving: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var selectedImage: UIImage?
    @State private var showColorPicker: Bool = false
    @State private var selectedColor: Color = .taskapeOrange
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false

    func handleFormatter(input: String) -> String {
        let alphanumerics = CharacterSet.alphanumerics
        let filtered = input.unicodeScalars.filter {
            alphanumerics.contains($0)
        }.map(String.init).joined()
        return String(filtered.prefix(18))
    }

    func bioFormatter(input: String) -> String {
        String(input.prefix(60))
    }

    private let colorOptions: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink,
        .mint, .cyan, .indigo, .teal, .brown,
    ]

    var originalHandle: String = ""
    var originalBio: String = ""
    var originalColor: String = ""

    init(user: taskapeUser) {
        userId = user.id
        _handle = State(initialValue: user.handle)
        _bio = State(initialValue: user.bio)
        _profileColor = State(initialValue: user.profileColor)
        _profileImageURL = State(initialValue: user.profileImageURL)
        _selectedColor = State(initialValue: Color(hex: user.profileColor))

        originalHandle = user.handle
        originalBio = user.bio
        originalColor = user.profileColor
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    ZStack(alignment: .bottomTrailing) {
                        if let selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .background(
                                    Circle()
                                        .stroke(
                                            Color(hex: profileColor),
                                            lineWidth: 3
                                        )
                                )
                        } else {
                            ProfileImageView(
                                imageUrl: profileImageURL,
                                color: profileColor,
                                size: 120
                            )
                        }

                        Button(action: {
                            showImagePicker = true
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color(hex: profileColor))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top, 20)

                    Text("tap to change profile picture")
                        .font(.pathwayItalic(14))
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("username")
                        .font(.pathway(14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    TextField("@\(handle)", text: $handle)
                        .font(.pathwayBlack(18))
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .padding(.horizontal)
                        .onChange(of: handle) { _, newValue in
                            if newValue.first == "@" {
                                handle = String(newValue.dropFirst())
                            }
                            handle = handleFormatter(input: handle)
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("bio")
                        .font(.pathway(14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    TextEditor(text: $bio)
                        .font(.pathway(16))
                        .scrollContentBackground(.hidden)
                        .padding()
                        .frame(height: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .padding(.horizontal).onChange(of: bio) {
                            bio = bioFormatter(input: bio)
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("profile color")
                        .font(.pathway(14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    Button(action: {
                        showColorPicker = true
                    }) {
                        HStack {
                            Circle()
                                .fill(selectedColor)
                                .frame(width: 24, height: 24)

                            Text("change profile color")
                                .font(.pathway(16))

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .sheet(isPresented: $showColorPicker) {
                        ColorPickerSheet(
                            selectedColor: $selectedColor,
                            onColorSelected: { color in
                                selectedColor = color
                                profileColor = color.toHex()
                            }
                        )
                        .presentationDetents([.fraction(1 / 3 + 1 / 18)])
                    }
                }

                Spacer()

                Button(action: {
                    Task {
                        if await checkHandleAvailability(handle: handle) {
                            saveProfile()
                        } else {
                            errorMessage = "handle already in use"
                            showError = true
                        }
                    }
                }) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(.white)
                    } else {
                        Text("save changes")
                            .font(.pathway(18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(hasChanges() ? Color.taskapeOrange : Color.gray)
                )
                .padding(.horizontal)
                .disabled(isSaving || !hasChanges() || handle == "")
                .padding(.top, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("edit profile")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                selectedImage = image
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
        .alert("error", isPresented: $showError) {
            Button("ok", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "an error occurred")
        }
        .onAppear {
            loadUserData()
        }
    }

    private func hasChanges() -> Bool {
        handle != originalHandle || bio != originalBio
            || profileColor != originalColor || selectedImage != nil
    }

    private func loadUserData() {
        if handle.isEmpty, bio.isEmpty, profileColor.isEmpty {
            isLoading = true

            Task {
                if let user = await fetchUser(userId: userId) {
                    await MainActor.run {
                        handle = user.handle
                        bio = user.bio
                        profileColor = user.profileColor
                        profileImageURL = user.profileImageURL
                        selectedColor = Color(hex: user.profileColor)

                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "couldn't load profile data"
                        showError = true
                        isLoading = false
                    }
                }
            }
        }
    }

    private func saveProfile() {
        isSaving = true

        Task {
            var imageURL = profileImageURL

            if let image = selectedImage {
                do {
                    let uploadedURL = try await uploadImage(image)
                    imageURL = uploadedURL
                } catch {
                    await MainActor.run {
                        errorMessage = "failed to upload profile image"
                        showError = true
                        isSaving = false
                    }
                    return
                }
            }

            let success = await editUserProfile(
                userId: userId,
                handle: handle,
                bio: bio,
                color: profileColor,
                profilePictureURL: imageURL
            )

            await MainActor.run {
                isSaving = false

                if success {
                    if let user = UserManager.shared.getCurrentUser(
                        context: modelContext)
                    {
                        user.handle = handle
                        user.bio = bio
                        user.profileColor = profileColor
                        user.profileImageURL = imageURL

                        do {
                            try modelContext.save()
                            dismiss()
                        } catch {
                            errorMessage = "failed to save profile locally"
                            showError = true
                        }
                    } else {
                        dismiss()
                    }
                } else {
                    errorMessage = "failed to update profile"
                    showError = true
                }
            }
        }
    }
}

struct ColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedColor: Color

    var onColorSelected: (Color) -> Void

    private let customColors: [Color] = [
        Color(hex: "#FF6B6B"), Color(hex: "#FF9F43"),
        Color(hex: "#FECA57"), Color(hex: "#4CD97B"),
        Color(hex: "#2E86DE"), Color(hex: "#9B5DE5"),
        Color(hex: "#F15BB5"), Color(hex: "#FF8B94"),
        Color(hex: "#4ECDC4"), Color(hex: "#45B7D1"),
        Color(hex: "#96CEB4"),
    ]

    @State private var customColor: Color = .taskapeOrange

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("taskape colors")
                    .font(.pathway(17))
                    .padding(.horizontal)

                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: 16), count: 6
                    ),
                    spacing: 16
                ) {
                    ForEach(customColors, id: \.self) { color in
                        ColorCircle(
                            color: color,
                            isSelected: selectedColor.toHex() == color.toHex(),
                            onTap: {
                                selectedColor = color
                            }
                        )
                    }

                    ColorPicker("", selection: $customColor)
                        .labelsHidden()
                        .frame(width: 54)
                }
                .padding(.horizontal)
            }.padding(.top, 30)

            Button(action: {
                onColorSelected(selectedColor)
                dismiss()
            }) {
                Text("done")
                    .font(.pathway(18))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.taskapeOrange)
                    )
            }
            .padding()

            Spacer()
        }
        .padding(.top)
    }
}

struct ColorCircle: View {
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 44, height: 44)

                if isSelected {
                    Circle()
                        .fill(color)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(
                                    Color.white,
                                    lineWidth: 3
                                )
                        )
                        .shadow(radius: 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileImageView: View {
    let imageUrl: String
    let color: String
    let size: CGFloat

    var body: some View {
        ZStack {
            if !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        Circle()
                            .fill(Color(hex: color))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: size * 0.4))
                                    .foregroundColor(.primary)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color(hex: color))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: size * 0.4))
                            .foregroundColor(.primary)
                    )
            }
        }
    }
}

struct ProfileEditView_Previews: PreviewProvider {
    static var previews: some View {
        let user = taskapeUser(
            id: "user1",
            handle: "shevlfs",
            bio: "i am shevlfs and this is my bio",
            profileImage: "",
            profileColor: "FF9500"
        )

        return ProfileEditView(user: user)
    }
}
