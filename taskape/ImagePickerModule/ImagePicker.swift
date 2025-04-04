import SwiftUI

#if canImport(UIKit)
    public struct ImagePicker: UIViewControllerRepresentable {
        private let sourceType: UIImagePickerController.SourceType
        private let onImagePicked: (UIImage) -> Void
        @Environment(\.presentationMode) private var presentationMode:
            Binding<PresentationMode>

        public init(
            sourceType: UIImagePickerController.SourceType,
            onImagePicked: @escaping (UIImage) -> Void
        ) {
            self.sourceType = sourceType
            self.onImagePicked = onImagePicked
        }

        public func makeUIViewController(context: Context)
            -> UIImagePickerController
        {
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.delegate = context.coordinator
            picker.allowsEditing = false
            return picker
        }

        public func updateUIViewController(
            _: UIImagePickerController, context _: Context
        ) {}

        public func makeCoordinator() -> Coordinator {
            Coordinator(
                onDismiss: { presentationMode.wrappedValue.dismiss() },
                onImagePicked: onImagePicked
            )
        }

        public final class Coordinator: NSObject,
            UINavigationControllerDelegate, UIImagePickerControllerDelegate
        {
            private let onDismiss: () -> Void
            private let onImagePicked: (UIImage) -> Void

            init(
                onDismiss: @escaping () -> Void,
                onImagePicked: @escaping (UIImage) -> Void
            ) {
                self.onDismiss = onDismiss
                self.onImagePicked = onImagePicked
            }

            public func imagePickerController(
                _: UIImagePickerController,
                didFinishPickingMediaWithInfo info: [UIImagePickerController
                    .InfoKey: Any]
            ) {
                if let image = info[.originalImage] as? UIImage {
                    onImagePicked(image)
                }
                onDismiss()
            }

            public func imagePickerControllerDidCancel(
                _: UIImagePickerController
            ) {
                onDismiss()
            }
        }
    }
#endif
