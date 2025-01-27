//
//  PhoneVerificationView.swift
//  taskape
//
//  Created by shevlfs on 1/27/25.
//

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
    var body: some View {
        VStack(alignment: .center) {
            Text("uh, sent you a code...\nyada-yada...")
                .multilineTextAlignment(.center)
                .font(.pathway(30))
                .percentageOffset(y: 1.25)
                .padding(.bottom, 200)

            TaskapeCodeField(
                current_string: $code,
                placeholder: "beep-boop",
                isCorrect: $isValid
            )
            .percentageOffset(y: 0.5)
            .overlay(
                Text("that's not quite right...")
                    .foregroundColor(Color.taskapeOrange)
                    .font(.pathway(15))
                    .offset(y: 80)
                    .opacity(displayError ? 1 : 0)
            )

            Spacer()

            Button(action: {
                codeReceived = true
            }) {
                Text("continue")
                    .padding()
                    .frame(maxWidth: 230)
                    .font(.pathway(21))
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.regularMaterial)
                            .stroke(.thinMaterial, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!isValid)
            .percentageOffset(y: -1.5)
        }
    }

}

#Preview {
    PhoneVerificationView(
        code: .constant(""),
        codeReceived: .constant(false),
        displayError: .constant(false)
    )
}
