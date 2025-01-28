import Combine
import SwiftUI

struct TaskapeNumberField: View {
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    @Binding var current_string: String
    let placeholder: String
    let country: CPData
    @FocusState var isFocused: Bool
    @Binding var isCorrect: Bool

    func formatPhoneNumber(_ phoneNumber: String) -> String {
        // Remove all non-digit characters
        let cleanNumber = phoneNumber.components(
            separatedBy: CharacterSet.decimalDigits.inverted
        ).joined()

        // Check if the number exceeds the country's limit
        guard cleanNumber.count <= country.limit else {
            // Truncate to the maximum allowed digits
            return String(cleanNumber.prefix(country.limit))
        }

        guard !cleanNumber.isEmpty else {
            return ""
        }

        var formattedNumber = ""
        let pattern = country.pattern.map { $0 }
        var numberIndex = cleanNumber.startIndex
        var patternIndex = pattern.startIndex

        while numberIndex < cleanNumber.endIndex
            && patternIndex < pattern.endIndex
        {
            if pattern[patternIndex] == "#" {
                // Add the next digit from the clean number
                formattedNumber.append(cleanNumber[numberIndex])
                numberIndex = cleanNumber.index(after: numberIndex)
            } else {
                // Add the formatting character from the pattern
                formattedNumber.append(pattern[patternIndex])
            }
            patternIndex = pattern.index(after: patternIndex)
        }

        return formattedNumber
    }
    var body: some View {
        TextField(
            placeholder,
            text: $current_string
        ).onChange(of: $current_string.wrappedValue) {
            current_string = formatPhoneNumber(current_string)
            isCorrect = current_string.count == country.pattern.count
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

struct countrySelectionButton: View {
    let country: CPData

    var body: some View {
        Text("\(country.flag) \(country.dial_code)").font(.pathwayBlack(20))
            .frame(minWidth: 120)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 30).fill(.regularMaterial)
                    .stroke(.thinMaterial, lineWidth: 1))
    }
}

struct countryPicker: View {
    @Binding var selectedCountry: CPData
    let countries: [CPData]
    var onDismiss: () -> Void

    var body: some View {
            ScrollView(.vertical, showsIndicators: false) {
                VStack{
                    ForEach(countries, id: \.id) { country in
                        Button(action: {

                            selectedCountry = country
                            onDismiss()
                        }) {
                            HStack {
                                Text(country.flag).font(.pathwayBlack(20))
                                Text("\(country.dial_code)").font(.pathwayBlack(20))
                                    .foregroundColor(.secondary)
                                Text(country.name).font(.pathwayBold(16))
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }

                    }
                }
 .shadow(radius: 10)
        }.frame(maxWidth: 300, maxHeight: 350).background(
            RoundedRectangle(cornerRadius: 12).fill(
                .regularMaterial)
        ).buttonStyle(.plain) .shadow(radius: 10)
    }
}

struct RegistrationView: View {
    @FocusState private var isFocused: Bool
    @State var selectedCountry: CPData = CPData.example
    @Binding var phoneNumber: String
    let countries: [CPData] = Bundle.main.decode("CountryNumbers.json")
    @State private var countryPickerActive = false
    @Binding var phoneNumberReceived: Bool
    @State var numberOk: Bool = false
    @Binding var phoneCode: String

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    Button(action: {
                        phoneCode = selectedCountry.dial_code
                        phoneNumberReceived = true
                    }) {
                        taskapeContinueButton()
                    }.buttonStyle(.plain).disabled(
                        !numberOk)
                }.percentageOffset(y: 4)

                Color.black
                    .opacity(countryPickerActive ? 0.5 : 0)
                    .ignoresSafeArea()
                    .animation(
                        .easeInOut(duration: 0.25),
                        value: countryPickerActive
                    ).onTapGesture {
                        isFocused = false
                        countryPickerActive = false
                    }
                VStack {
                    Text("heyyy, so, uh...\n what's your number?")
                        .multilineTextAlignment(.center)
                        .font(.pathway(30))
                        .percentageOffset(y: 2).padding(.bottom, 280)

                    HStack {
                        Button(action: {
                            isFocused = false
                            countryPickerActive.toggle()
                        }) {
                            countrySelectionButton(country: selectedCountry)
                        }
                        .buttonStyle(.plain)

                        TaskapeNumberField(
                            current_string: $phoneNumber,
                            placeholder: "banana phone",
                            country: selectedCountry, isFocused: _isFocused,
                            isCorrect: $numberOk
                        )
                    }.percentageOffset(y: 0.5)
                    Spacer()
                }.overlay(countryPicker(
                    selectedCountry: $selectedCountry,
                    countries: countries,
                    onDismiss: { countryPickerActive = false }
                ).disabled(!countryPickerActive).opacity(
                    countryPickerActive ? 1 : 0
                )
                    .percentageOffset(x: -0.15, y: 0.5).transition(.opacity)
                .animation(
                    .bouncy(duration: 0.25), value: countryPickerActive))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
        }.ignoresSafeArea()
    }
}

#Preview {
    @Previewable @State var selectedCountry: CPData = CPData.example
    RegistrationView(
        selectedCountry: selectedCountry,
        phoneNumber: .constant(""),
        phoneNumberReceived: .constant(true), phoneCode: .constant("")
    )
}

struct ButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
