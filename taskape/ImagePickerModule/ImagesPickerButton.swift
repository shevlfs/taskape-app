import AVFoundation
import SwiftUI

#if canImport(UIKit)
    public struct ImagesPickerButton<Content: View>: View {
        public enum NoCameraAccessStrategy {
            case hideOption, showToSettings
        }

        @Binding public var selectedImages: [UIImage]
        private let noCameraAccessStrategy: NoCameraAccessStrategy
        public let label: Content

        @State private var showCameraImagePicker: Bool = false
        @State private var showLibraryImagePicker: Bool = false
        @State private var showCameraAccessRequiredAlert: Bool = false

        public init(
            selectedImages: Binding<[UIImage]>,
            noCameraAccessStrategy: NoCameraAccessStrategy =
                NoCameraAccessStrategy.showToSettings,
            @ViewBuilder label: @escaping () -> Content
        ) {
            _selectedImages = selectedImages
            self.noCameraAccessStrategy = noCameraAccessStrategy
            self.label = label()
        }

        public var body: some View {
            ZStack {
                Menu(
                    content: {
                        Button(
                            action: { showLibraryImagePicker = true },
                            label: {
                                Label(
                                    NSLocalizedString(
                                        "Foto aus Bibliothek auswählen",
                                        comment: ""
                                    ), systemImage: "folder"
                                )
                            }
                        )

                        if AVCaptureDevice.authorizationStatus(for: .video)
                            == .authorized
                            || AVCaptureDevice.authorizationStatus(for: .video)
                            == .notDetermined
                        {
                            Button(
                                action: { showCameraImagePicker = true },
                                label: {
                                    Label(
                                        NSLocalizedString(
                                            "Foto mit Kamera aufnehmen",
                                            comment: ""
                                        ), systemImage: "camera"
                                    )
                                }
                            )

                        } else if AVCaptureDevice.authorizationStatus(
                            for: .video) == .denied
                        {
                            if noCameraAccessStrategy
                                == NoCameraAccessStrategy.showToSettings
                            {
                                Button(
                                    action: {
                                        showCameraAccessRequiredAlert =
                                            true
                                    },
                                    label: {
                                        Label(
                                            NSLocalizedString(
                                                "Foto mit Kamera aufnehmen",
                                                comment: ""
                                            ),
                                            systemImage: "camera"
                                        )
                                    }
                                )
                            }
                        }

                    },

                    label: { label }

                ).textCase(nil)

                Text("").sheet(isPresented: $showCameraImagePicker) {
                    ImagePicker(
                        sourceType: UIImagePickerController.SourceType.camera
                    ) { image in
                        selectedImages.append(image)
                    }.ignoresSafeArea()
                }

                Text("").sheet(isPresented: $showLibraryImagePicker) {
                    ImagePicker(sourceType: .photoLibrary) { image in
                        selectedImages.append(image)
                    }.ignoresSafeArea()
                }

                Text("").alert(isPresented: $showCameraAccessRequiredAlert) {
                    Alert(
                        title: Text(
                            NSLocalizedString(
                                "Kamerazugriff benötigt", comment: ""
                            )),
                        message: Text(
                            NSLocalizedString(
                                "Der Kamerazugriff kann in den Systemeinstellungen für diese App gewährt werden.",
                                comment: ""
                            )),
                        primaryButton: Alert.Button.default(
                            Text(
                                NSLocalizedString("Einstellungen", comment: ""))
                        ) {
                            guard
                                let settingsULR = URL(
                                    string: UIApplication.openSettingsURLString)
                            else { return }
                            UIApplication.shared.open(
                                settingsULR, options: [:],
                                completionHandler: nil
                            )
                        },
                        secondaryButton: Alert.Button.cancel()
                    )
                }
            }
        }
    }
#endif
