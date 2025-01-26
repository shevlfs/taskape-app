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
        ).onChange(of: current_string) { newValue in
            let formattedNumber = formatPhoneNumber(newValue)
            current_string = formattedNumber
        }
        .accentColor(.taskapeOrange)
        .autocorrectionDisabled()
        .autocapitalization(.none)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 15)
        .padding(.vertical, 15)
        .frame(maxWidth: 270)
        .font(.pathwayBlack(20))
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(.regularMaterial)
                .stroke(.thinMaterial, lineWidth: 1)
        )
        .keyboardType(.numberPad)
    }
}

struct countrySelectionButton: View {
    let country: CPData

    var body: some View {
        Text("\(country.flag) \(country.dial_code)").font(.pathwayBlack(20))
            .padding(.horizontal, 15)
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
        VStack {
            ScrollView {
                ForEach(countries, id: \.code) { country in
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
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 300, height: 300)
        .background(RoundedRectangle(cornerRadius: 12).fill(.regularMaterial))
        .shadow(radius: 10)
    }
}

struct RegistrationView: View {
    @State var selectedCountry: CPData = CPData.example
    @State private var current_number: String = ""
    let countries: [CPData] = Bundle.main.decode("CountryNumbers.json")
    @State private var countryPickerActive = false

    var body: some View {
        VStack {

            ZStack {
                // Background overlay
                if countryPickerActive {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            countryPickerActive = false
                        }
                }

                VStack {

                    Text("heyyy, so, uh... \n what's your number?")
                        .multilineTextAlignment(.center)
                        .font(.pathway(35))
                        .padding(.bottom, 150)

                    HStack {
                        // Country selection button
                        Button(action: {
                            countryPickerActive.toggle()
                        }) {
                            countrySelectionButton(country: selectedCountry)
                        }.buttonStyle(.plain)

                        // Number input field
                        TaskapeNumberField(
                            current_string: $current_number,
                            placeholder: "banana phone",
                            country: selectedCountry
                        )
                    }
                    .padding(.horizontal)

                    // Country picker
                    countryPicker(
                        selectedCountry: $selectedCountry,
                        countries: countries,
                        onDismiss: { countryPickerActive = false }
                    )
                    .opacity(countryPickerActive ? 1 : 0)
                    .animation(
                        .bouncy(duration: 0.25), value: countryPickerActive
                    )
                    .offset(x: -40)

                    Spacer()
                }
                .padding(.top, 80)

                Spacer()
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedCountry: CPData = CPData.example
    RegistrationView(selectedCountry: selectedCountry)
}

struct ButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
