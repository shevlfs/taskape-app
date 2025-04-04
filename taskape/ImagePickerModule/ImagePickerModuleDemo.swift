import SwiftUI

#if canImport(UIKit)
    public struct ImagePickerDemo: View {
        @State private var selectedImage: UIImage?
        @State private var selectedImages: [UIImage] = []

        public var body: some View {
            List {
                Section(header: Text("Regular Image Picker")) {}

                Section(header: Text("Image Picker Button")) {
                    ImagePickerButton(selectedImage: $selectedImage) {
                        Image(systemName: "photo")
                    }

                    ImagePickerButton(
                        selectedImage: $selectedImage,
                        noCameraAccessStrategy: .hideOption
                    ) {
                        Image(systemName: "photo")
                    }

                    ImagePickerButton(
                        selectedImage: $selectedImage,
                        noCameraAccessStrategy: .showToSettings
                    ) {
                        Image(systemName: "photo")
                    }

                    ImagePickerButton(
                        selectedImage: $selectedImage,
                        label: { Image(systemName: "photo") },
                        defaultImageContent: nil != nil
                            ? nil : { Text("Default") }
                    )

                    ImagePickerButton(
                        selectedImage: $selectedImage,
                        label: { Image(systemName: "photo") },
                        onDelete: {},
                        defaultImageContent: { Image(systemName: "photo") }
                    )

                    ImagePickerButton(
                        selectedImage: $selectedImage,
                        noCameraAccessStrategy: .hideOption,
                        label: { Image(systemName: "photo") },
                        onDelete: {},
                        defaultImageContent: { Image(systemName: "photo") }
                    )
                }

                Section(header: Text("Images Picker Button")) {
                    ImagesPickerButton(selectedImages: $selectedImages) {
                        Image(systemName: "plus")
                    }

                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(selectedImages, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: 48, height: 48)
                                    .cornerRadius(8)
                            }
                        }
                    }.padding(.vertical)
                }

            }.listStyle(GroupedListStyle())
        }
    }

    public struct ImagePicker_Previews: PreviewProvider {
        public static var previews: some View {
            ImagePickerDemo()
        }
    }
#endif
