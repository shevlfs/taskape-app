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
        ).onChange(of: $current_string.wrappedValue) { newValue in
            current_string = formatPhoneNumber(newValue)
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
        VStack {
            ScrollView {
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
    @FocusState private var isFocused: Bool
    @State var selectedCountry: CPData = CPData.example
    @State private var current_number: String = ""
    let countries: [CPData] = Bundle.main.decode("CountryNumbers.json")
    @State private var countryPickerActive = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background overlay

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
                    Text("heyyy, so, uh... \n what's your number?")
                        .multilineTextAlignment(.center)
                        .font(.pathway(35))
                        .padding(.top, geometry.safeAreaInsets.top + 120)
                        .padding(.bottom, 160)

                    HStack {
                        Button(action: {
                            isFocused = false
                            countryPickerActive.toggle()
                        }) {
                            countrySelectionButton(country: selectedCountry)
                        }
                        .buttonStyle(.plain)

                        TaskapeNumberField(
                            current_string: $current_number,
                            placeholder: "banana phone",
                            country: selectedCountry, isFocused: _isFocused
                        )
                    }
                    .padding(.horizontal)

                    if countryPickerActive {
                        countryPicker(
                            selectedCountry: $selectedCountry,
                            countries: countries,
                            onDismiss: { countryPickerActive = false }
                        )
                        .transition(.opacity)
                        .animation(
                            .bouncy(duration: 0.25), value: countryPickerActive)
                    }

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
        }
        .ignoresSafeArea()
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
