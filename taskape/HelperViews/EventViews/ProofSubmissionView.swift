import Alamofire
import AVFoundation
import Photos
import PhotosUI
import SwiftDotenv
import SwiftUI

struct ProofSubmissionView: View {
    @Bindable var task: taskapeTask
    @Binding var isPresented: Bool
    @State private var selectedImage: UIImage?
    @State private var proofDescription: String = ""
    @State private var isUploading: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var photoPickerItem: PhotosPickerItem?
    @Binding var proofSubmitted: Bool
    @Environment(\.modelContext) var modelContext
    @State var mediaAccessDenied: Bool = false

    @State private var photoPermissionStatus: PHAuthorizationStatus =
        .notDetermined
    @State private var cameraPermissionStatus: AVAuthorizationStatus =
        .notDetermined
    @State private var showPermissionAlert: Bool = false
    @State private var permissionChecked: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
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

                VStack(spacing: 15) {
                    if let selectedImage {
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

    func hasRequiredPermissions() -> Bool {
        (photoPermissionStatus == .authorized
            || photoPermissionStatus == .limited)
            && cameraPermissionStatus == .authorized
    }

    func checkPermissions() {
        photoPermissionStatus = PHPhotoLibrary.authorizationStatus(
            for: .readWrite)

        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(
            for: .video)

        if photoPermissionStatus == .denied
            || photoPermissionStatus == .restricted
            || cameraPermissionStatus == .denied
            || cameraPermissionStatus == .restricted
        {
            mediaAccessDenied = true
        } else if photoPermissionStatus == .notDetermined
            || cameraPermissionStatus == .notDetermined
        {
            showPermissionAlert = true
        }
    }

    func requestRequiredPermissions() {
        requestCameraPermission()
        requestPhotoPermission()
    }

    func requestCameraPermission() {
        if cameraPermissionStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermissionStatus =
                        granted ? .authorized : .denied
                    updateMediaAccessState()
                }
            }
        }
    }

    func requestPhotoPermission() {
        if photoPermissionStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    photoPermissionStatus = status
                    updateMediaAccessState()
                }
            }
        }
    }

    func updateMediaAccessState() {
        if hasRequiredPermissions() {
            mediaAccessDenied = false

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
                let imageUrl = try await uploadimage(image: image)

                await MainActor.run {
                    task.completion.proofURL = imageUrl
                    task.proofDescription = proofDescription
                    task.completion.requiresConfirmation = true

                    do {
                        try modelContext.save()

                        Task {
                            await syncTaskChanges(task: task)
                        }

                        isPresented = false
                        proofSubmitted = true
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

    func uploadimage(image: UIImage) async throws -> String {
        let apiKey: String = Dotenv["IAPIKEY"]!.stringValue
        let endpoint: String = Dotenv["IAPIENDPOINT"]!.stringValue

        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            debugPrint(#function, "Couldn't convert image to data")
            throw URLError(.badURL)
        }

        let parameters: [String: Any] = [
            "key": apiKey,
        ]

        return try await withCheckedThrowingContinuation { continuation in
            AF.upload(
                multipartFormData: { multipartFormData in
                    for (key, value) in parameters {
                        if let data = "\(value)".data(using: .utf8) {
                            multipartFormData.append(data, withName: key)
                        }
                    }
                    multipartFormData.append(
                        imageData,
                        withName: "image",
                        fileName: "profile.jpg",
                        mimeType: "image/jpeg"
                    )
                }, to: endpoint
            )
            .responseJSON { response in
                switch response.result {
                case let .success(value):
                    if let json = value as? [String: Any],
                       let data = json["data"] as? [String: Any],
                       let url = data["url"] as? String
                    {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(
                            throwing: URLError(.badServerResponse))
                    }
                case let .failure(error):
                    print("error: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

#Preview {
    let task = taskapeTask(
        name: "Complete project",
        taskDescription: "Finish all the views and connect them",
        author: "shevlfs",
        privacy: "private"
    )
    task.proofNeeded = true
    task.proofDescription = "please take a photo of the completed project"

    return ProofSubmissionView(
        task: task, isPresented: .constant(true),
        proofSubmitted: .constant(false)
    )
}
