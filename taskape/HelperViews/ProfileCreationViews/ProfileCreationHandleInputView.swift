import SwiftUI

struct ProfileCreationProgressBar: View {
    @Binding var progress: Float
    var body: some View {
        ProgressView(value: progress)
            .accentColor(Color.taskapeOrange)
            .padding().shadow(radius: 1.5).animation(
                .bouncy(duration: 0.35), value: progress)
    }
}

struct taskapeHandleField: View {
    @Binding var handle: String
    @Binding var isChecking: Bool
    @Binding var isAvailable: Bool?
    @Binding var wasChecked: Bool
    var onHandleChanged: () -> Void

    func handleFormatter(input: String) -> String {
        let alphanumerics = CharacterSet.alphanumerics
        let filtered = input.unicodeScalars.filter {
            alphanumerics.contains($0)
        }.map(String.init).joined()
        return "@" + filtered.prefix(18)
    }

    var body: some View {
        TextField("handle goes here", text: $handle)
            .onChange(of: handle) {
                handle = self.handleFormatter(input: handle)
                isAvailable = nil
                wasChecked = false
                onHandleChanged()
            }
            .padding(15)
            .accentColor(.taskapeOrange)
            .autocorrectionDisabled()
            .autocapitalization(.none)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 270)
            .font(.pathwayBlack(20))
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(.regularMaterial)
                    .stroke(
                        .thinMaterial,
                        lineWidth: 1
                    )
            )
            .overlay(
                Group {
                    if isChecking {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.7)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 16)
                    } else if wasChecked && isAvailable == true {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 16)
                    } else if wasChecked && isAvailable == false {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 16)
                    }
                }
            )
    }
}

struct ProfileCreationHandleInputView: View {
    @Binding var handle: String
    @Binding var path: NavigationPath
    @Binding var progress: Float

    @State private var isChecking: Bool = false
    @State private var isHandleAvailable: Bool? = nil
    @State private var wasHandleChecked: Bool = false
    @State private var debounceTimer: Timer? = nil

    var body: some View {
        VStack {
            ProfileCreationProgressBar(progress: $progress)
            Text("so, what should your @ be?")
                .multilineTextAlignment(.center)
                .font(.pathway(30))
                .padding()

            Spacer()

            taskapeHandleField(
                handle: $handle,
                isChecking: $isChecking,
                isAvailable: $isHandleAvailable,
                wasChecked: $wasHandleChecked,
                onHandleChanged: handleTypingDebounce
            ).overlay(
                Group {
                    if wasHandleChecked && isHandleAvailable == false {
                        Text("this username is already taken")
                            .font(.pathway(15))
                            .foregroundColor(Color.red)
                            .offset(y: 80)
                    }
                }
            )

            Spacer()

            Button(action: {
                if wasHandleChecked && isHandleAvailable == true {
                    proceedToNextStep()
                }
            }) {
                taskapeContinueButton()
            }
            .buttonStyle(.plain)
            .disabled(
                handle.count < 4 || isChecking
                    || !(wasHandleChecked && isHandleAvailable == true))

            Text("P.S. they are unique to each profile").multilineTextAlignment(
                .center
            )
            .font(.pathwayItalic(16))
            .padding()
        }.navigationBarTitleDisplayMode(.inline)
    }

    private func checkHandleAndProceed() {
        if handle.count < 5 {
            return
        }

        if wasHandleChecked && isHandleAvailable == true {
            proceedToNextStep()
            return
        }

        isChecking = true

        Task {
            let handleToCheck =
                handle.hasPrefix("@") ? String(handle.dropFirst()) : handle

            if handleToCheck.isEmpty {
                await MainActor.run {
                    isChecking = false
                    isHandleAvailable = false
                    wasHandleChecked = true
                }
                return
            }

            let available = await checkHandleAvailability(handle: handle)

            await MainActor.run {
                isChecking = false
                isHandleAvailable = available
                wasHandleChecked = true
            }
        }
    }

    private func proceedToNextStep() {
        self.handle =
            handle.hasPrefix("@") ? String(handle.dropFirst()) : handle
        UserDefaults.standard.set(self.handle, forKey: "handle")
        path.append("bio_input")
        progress += 1 / 5
    }

    private func handleTypingDebounce() {
        debounceTimer?.invalidate()
        if handle.count >= 5 {
            debounceTimer = Timer.scheduledTimer(
                withTimeInterval: 0.7, repeats: false
            ) { _ in
                if !isChecking && !wasHandleChecked {
                    checkHandleAndProceed()
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var handle: String = ""
    @Previewable @State var path = NavigationPath()
    @Previewable @State var progress: Float = 0
    ProfileCreationHandleInputView(
        handle: .constant(handle), path: .constant(path),
        progress: .constant(progress))
}

