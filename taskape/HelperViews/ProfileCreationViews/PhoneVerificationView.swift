import SwiftUI

struct TaskapeCodeField: View {
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    @Binding var current_string: String
    let placeholder: String
    @Binding var isCorrect: Bool
    @FocusState var isFocused: Bool

    func formatCode(_ phoneNumber: String) -> String {
        let cleanNumber = phoneNumber.components(
            separatedBy: CharacterSet.decimalDigits.inverted
        ).joined()

        guard cleanNumber.count <= 6 else {
            return String(cleanNumber.prefix(6))
        }

        return cleanNumber
    }

    var body: some View {
        TextField(
            placeholder,
            text: $current_string
        ).onChange(of: $current_string.wrappedValue) {
            current_string = formatCode(current_string)
            isCorrect = current_string.count == 6
        }.padding(15)
            .focused($isFocused)
            .accentColor(.taskapeOrange)
            .autocorrectionDisabled()
            .autocapitalization(.none)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 270)
            .font(.pathwayBlack(20))
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(.regularMaterial)
                    .stroke(.thinMaterial, lineWidth: 1)
            )
            .keyboardType(.numberPad)
            .onTapGesture {
                isFocused = true
            }
    }
}

struct PhoneVerificationView: View {
    @Binding var code: String
    @State var isValid: Bool = false
    @Binding var codeReceived: Bool
    @Binding var displayError: Bool
    @State private var isResending: Bool = false
    @State private var showResendMessage: Bool = false

    var phoneNumber: String
    var countryCode: String

    var body: some View {
        VStack(alignment: .center) {
            Text("uh, sent you a code...\nyada-yada...")
                .multilineTextAlignment(.center)
                .font(.pathway(30)).padding(.top, 40)

            Spacer()

            TaskapeCodeField(
                current_string: $code,
                placeholder: "beep-boop",
                isCorrect: $isValid
            )
            .overlay(
                Text("that's not quite right...")
                    .foregroundColor(Color.taskapeOrange)
                    .font(.pathway(15))
                    .offset(y: 120)
                    .opacity(displayError ? 1 : 0)
            )

            Button(action: {
                resendCode()
            }) {
                HStack {
                    Text("didn't get a code?")
                        .font(.pathway(15))
                        .foregroundColor(.secondary)

                    Text("resend")
                        .font(.pathwayBold(15))
                        .foregroundColor(Color.taskapeOrange)
                }
                .padding(.top, 30)
            }
            .buttonStyle(.plain)
            .disabled(isResending)

            if showResendMessage {
                Text("code sent!")
                    .font(.pathway(14))
                    .foregroundColor(.green)
                    .padding(.top, 8)
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showResendMessage = false
                            }
                        }
                    }
            }

            Spacer()

            Button(action: {
                codeReceived = true
            }) {
                taskapeContinueButton()
            }
            .buttonStyle(.plain)
            .disabled(!isValid).padding(.bottom, 120)
        }
    }

    private func resendCode() {
        isResending = true

        Task {
            await sendVerificationCode(
                phoneNumber: phoneNumber,
                country_code: countryCode
            )

            await MainActor.run {
                isResending = false
                withAnimation {
                    showResendMessage = true
                }
                displayError = false
            }
        }
    }
}

#Preview {
    PhoneVerificationView(
        code: .constant(""),
        codeReceived: .constant(false),
        displayError: .constant(false),
        phoneNumber: "1234567890",
        countryCode: "+1"
    )
}
