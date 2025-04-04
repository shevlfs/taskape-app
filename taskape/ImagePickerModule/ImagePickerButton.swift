

import AVFoundation
import SwiftUI

#if canImport(UIKit)
    public struct ImagePickerButton<Content: View, DefaultImageContent: View>: View {
        public enum NoCameraAccessStrategy {
            case hideOption, showToSettings
        }

        private let noCameraAccessStrategy: NoCameraAccessStrategy

        @Binding private var selectedImage: UIImage?
        private let label: Content

        private let onDelete: (() -> Void)?
        private let defaultImageContent: (() -> DefaultImageContent)?

        @State private var showCameraImagePicker: Bool = false
        @State private var showLibraryImagePicker: Bool = false
        @State private var showSelectedImage: Bool = false
        @State private var showCameraAccessRequiredAlert: Bool = false

        public var body: some View {
            ZStack {
                Menu(
                    content: {
                        Button(
                            action: { showLibraryImagePicker = true },
                            label: {
                                Label(NSLocalizedString("Foto aus Bibliothek auswählen", comment: ""), systemImage: "folder")
                            }
                        )

                        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized ||
                            AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined
                        {
                            Button(
                                action: { showCameraImagePicker = true },
                                label: { Label(NSLocalizedString("Foto mit Kamera aufnehmen", comment: ""), systemImage: "camera") }
                            )

                        } else if AVCaptureDevice.authorizationStatus(for: .video) == .denied {
                            if noCameraAccessStrategy == NoCameraAccessStrategy.showToSettings {
                                Button(
                                    action: { showCameraAccessRequiredAlert = true },
                                    label: {
                                        Label(
                                            NSLocalizedString("Foto mit Kamera aufnehmen", comment: ""),
                                            systemImage: "camera"
                                        )
                                    }
                                )
                            }
                        }

                        if defaultImageContent != nil || selectedImage != nil {
                            Button(
                                action: { showSelectedImage = true },
                                label: {
                                    Label(
                                        NSLocalizedString("Aktuelles Bild anzeigen", comment: ""),
                                        systemImage: "arrow.up.backward.and.arrow.down.forward"
                                    )
                                }
                            )
                        }

                        if let onDelete {
                            Button(
                                action: {
                                    onDelete()
                                    selectedImage = nil
                                },
                                label: {
                                    Label(
                                        NSLocalizedString("Aktuelles Bild entfernen", comment: ""),
                                        systemImage: "xmark"
                                    )
                                }
                            )
                        }

                    },

                    label: {
                        if let defaultImageContent, selectedImage == nil {
                            defaultImageContent()
                        } else {
                            label
                        }
                    }

                ).textCase(nil)

                Text("").sheet(isPresented: $showCameraImagePicker) {
                    ImagePicker(sourceType: UIImagePickerController.SourceType.camera) { image in
                        selectedImage = image
                    }.ignoresSafeArea()
                }

                Text("").sheet(isPresented: $showLibraryImagePicker) {
                    ImagePicker(sourceType: .photoLibrary) { image in
                        selectedImage = image
                    }.ignoresSafeArea()
                }

                Text("").sheet(isPresented: $showSelectedImage) {
                    if let defaultImageContent {
                        defaultImageContent()

                    } else if let profilePicture = selectedImage {
                        Image(uiImage: profilePicture)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                    }
                }

                Text("").alert(isPresented: $showCameraAccessRequiredAlert) {
                    Alert(
                        title: Text(NSLocalizedString("Kamerazugriff benötigt", comment: "")),
                        message: Text(NSLocalizedString("Der Kamerazugriff kann in den Systemeinstellungen für diese App gewährt werden.", comment: "")),
                        primaryButton: Alert.Button.default(Text(NSLocalizedString("Einstellungen", comment: ""))) {
                            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                        },
                        secondaryButton: Alert.Button.cancel()
                    )
                }
            }
        }
    }

    public extension ImagePickerButton {
        init(
            selectedImage: Binding<UIImage?>,
            noCameraAccessStrategy: NoCameraAccessStrategy = NoCameraAccessStrategy.showToSettings,
            label: @escaping () -> Content,
            onDelete: (() -> Void)? = nil,
            defaultImageContent: (() -> DefaultImageContent)?
        ) {
            _selectedImage = selectedImage
            self.noCameraAccessStrategy = noCameraAccessStrategy
            self.onDelete = onDelete
            self.label = label()
            self.defaultImageContent = defaultImageContent
        }
    }

    public extension ImagePickerButton where DefaultImageContent == EmptyView {
        init(
            selectedImage: Binding<UIImage?>,
            noCameraAccessStrategy: NoCameraAccessStrategy = NoCameraAccessStrategy.showToSettings,
            label: @escaping () -> Content,
            onDelete: (() -> Void)? = nil
        ) {
            self.init(
                selectedImage: selectedImage,
                noCameraAccessStrategy: noCameraAccessStrategy,
                label: label,
                onDelete: onDelete,
                defaultImageContent: nil
            )
        }
    }
#endif
