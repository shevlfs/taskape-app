import AVFoundation
import ImagePickerModule
import Photos
import PhotosUI
import SwiftUI

struct ProofSubmissionView: View {
    @Bindable var task: taskapeTask
    @Binding var isPresented: Bool
    @State private var selectedImage: UIImage?
    @State private var proofDescription: String = ""
    @State private var isUploading: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var photoPickerItem: PhotosPickerItem?
    @Environment(\.modelContext) var modelContext
    @State var mediaAccessDenied: Bool = false

    // Permission states
    @State private var photoPermissionStatus: PHAuthorizationStatus =
        .notDetermined
    @State private var cameraPermissionStatus: AVAuthorizationStatus =
        .notDetermined
    @State private var showPermissionAlert: Bool = false
    @State private var permissionChecked: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header section
                Text("proof required")
                    .font(.pathwayBlack(22))
                    .padding(.top)

                Text(
                    task.proofDescription
                        ?? "please provide proof for this task"
                )
                .font(.pathway(16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

                // Image selection
                VStack(spacing: 15) {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(20)
                            .padding(.horizontal)
                    } else {
                        Rectangle()
                            .fill(Color(UIColor.secondarySystemBackground))
                            .frame(height: 200)
                            .cornerRadius(20)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "camera")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)

                                    Text("tap to add photo")
                                        .font(.pathway(16))
                                        .foregroundColor(.secondary)
                                }
                            )
                            .padding(.horizontal)
                    }

                    if mediaAccessDenied {
                        VStack(spacing: 10) {
                            Text("Camera and photo access are required")
                                .font(.pathway(16))
                                .foregroundColor(.red)

                            Button(action: {
                                if let url = URL(
                                    string: UIApplication.openSettingsURLString)
                                {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("open settings")
                                    .font(.pathway(16))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 24)
                                    .background(Color.taskapeOrange)
                                    .cornerRadius(30)
                            }
                        }
                        .padding(.vertical, 10)
                    } else {
                        Button(action: {
                            if hasRequiredPermissions() {
                                showImagePicker.toggle()
                            } else {
                                requestRequiredPermissions()
                            }
                        }) {
                            Text(
                                selectedImage == nil
                                    ? "select image" : "change image"
                            )
                            .font(.pathway(16))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.taskapeOrange)
                            .cornerRadius(30)
                        }.sheet(isPresented: $showImagePicker) {
                            ImagePicker(
                                sourceType: .camera,
                                onImagePicked: {
                                    image in selectedImage = image
                                }
                            )
                        }
                    }
                }

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("description")
                        .font(.pathway(16))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    TextEditor(text: $proofDescription)
                        .scrollContentBackground(.hidden).font(.pathway(16))
                        .padding()
                        .frame(height: 100)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(20)
                        .padding(.horizontal)
                }

                Spacer()

                // Action buttons
                HStack(spacing: 15) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("cancel")
                            .font(.pathway(16))
                            .foregroundColor(.red)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }

                    Button(action: {
                        submitProof()
                    }) {
                        if isUploading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.white)
                        } else {
                            Text("submit proof")
                                .font(.pathway(16))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                selectedImage == nil
                                    ? Color.gray : Color.taskapeOrange)
                    )
                    .disabled(selectedImage == nil || isUploading)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
            )
            .onAppear {
                // Only check permissions once
                if !permissionChecked {
                    checkPermissions()
                    permissionChecked = true
                }
            }
            .alert(isPresented: $showPermissionAlert) {
                Alert(
                    title: Text("Camera & Photo Access Required"),
                    message: Text(
                        "To submit proof of your task completion, we need access to your camera and photo library."
                    ),
                    primaryButton: .default(Text("Allow Access")) {
                        requestRequiredPermissions()
                    },
                    secondaryButton: .cancel(Text("Not Now")) {
                        mediaAccessDenied = true
                    }
                )
            }
        }
    }

    // Check if we have all required permissions
    func hasRequiredPermissions() -> Bool {
        return
            (photoPermissionStatus == .authorized
            || photoPermissionStatus == .limited)
            && cameraPermissionStatus == .authorized
    }

    // Check both camera and photo library permissions
    func checkPermissions() {
        // Check photo library permission
        photoPermissionStatus = PHPhotoLibrary.authorizationStatus(
            for: .readWrite)

        // Check camera permission
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(
            for: .video)

        // If permissions are denied, set the flag
        if photoPermissionStatus == .denied
            || photoPermissionStatus == .restricted
            || cameraPermissionStatus == .denied
            || cameraPermissionStatus == .restricted
        {
            mediaAccessDenied = true
        } else if photoPermissionStatus == .notDetermined
            || cameraPermissionStatus == .notDetermined
        {
            // Show the permission alert if either permission is not determined
            showPermissionAlert = true
        }
    }

    // Request all required permissions
    func requestRequiredPermissions() {
        requestCameraPermission()
        requestPhotoPermission()
    }

    // Request camera permission
    func requestCameraPermission() {
        if cameraPermissionStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionStatus =
                        granted ? .authorized : .denied
                    self.updateMediaAccessState()
                }
            }
        }
    }

    // Request photo library permission
    func requestPhotoPermission() {
        if photoPermissionStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    self.photoPermissionStatus = status
                    self.updateMediaAccessState()
                }
            }
        }
    }

    // Update the media access denied state and open picker if all permissions are granted
    func updateMediaAccessState() {
        if hasRequiredPermissions() {
            mediaAccessDenied = false
            // Open picker if we have all permissions
            showImagePicker = true
        } else if photoPermissionStatus == .denied
            || photoPermissionStatus == .restricted
            || cameraPermissionStatus == .denied
            || cameraPermissionStatus == .restricted
        {
            mediaAccessDenied = true
        }
    }

    private func submitProof() {
        guard let image = selectedImage else { return }

        isUploading = true

        Task {
            do {
                // Upload the image
                let imageUrl = try await uploadImage(image)

                await MainActor.run {
                    // Update the task with proof
                    task.completion.proofURL = imageUrl
                    task.completion.isCompleted = true

                    // Save changes to model context
                    do {
                        try modelContext.save()

                        // Sync with server
                        Task {
                            await syncTaskChanges(task: task)
                        }

                        // Close the sheet
                        isPresented = false
                    } catch {
                        print("Error saving proof to task: \(error)")
                    }
                }
            } catch {
                print("Error uploading proof image: \(error)")
                await MainActor.run {
                    isUploading = false
                }
            }
        }
    }
}

// Preview
#Preview {
    let task = taskapeTask(
        name: "Complete project",
        taskDescription: "Finish all the views and connect them",
        author: "shevlfs",
        privacy: "private"
    )
    task.proofNeeded = true
    task.proofDescription = "please take a photo of the completed project"

    return ProofSubmissionView(task: task, isPresented: .constant(true))
}
