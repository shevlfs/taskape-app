//
//  AuthenticationView.swift
//  taskape
//
//  Created by shevlfs on 1/7/25.
//

import Lottie
import SwiftUI

extension View {
    func percentageOffset(x: Double = 0, y: Double = 0) -> some View {
        self
            .modifier(PercentageOffset(x: x, y: y))
    }
}

struct PercentageOffset: ViewModifier {

    let x: Double
    let y: Double

    @State private var size: CGSize = .zero

    func body(content: Content) -> some View {

        content
            .background(
                GeometryReader { geo in Color.clear.onAppear { size = geo.size }
                }
            )
            .offset(x: size.width * x, y: size.height * y)
    }
}

struct AuthenticationView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var LandingButtonPressed = false
    @State var phoneNumberReceived: Bool = false
    @State var phoneNumber: String = ""
    @State var phoneCode: String = ""
    @State var verifyCode: String = ""
    @State var verifyCodeReceived: Bool = false
    @State var numberRegistrationComplete: Bool = false
    @State var displayCodeError: Bool = false
    @State private var path = NavigationPath()

    @State var progress: Float = 1 / 3

    @State var userHandle: String = ""
    @State var userBio: String = ""

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                LottieView(
                    animation: .named(
                        colorScheme == .dark
                            ? "taskapeblack" : "taskapewhite")
                ).configuration(
                    LottieConfiguration(
                        renderingEngine: .automatic
                    )
                ).looping().backgroundBehavior(.pauseAndRestore)
                    .animationSpeed(
                        LandingButtonPressed ? 0.4 : 1
                    ).scaledToFill()
                    .edgesIgnoringSafeArea(.all).opacity(
                        LandingButtonPressed ? 0.5 : 1
                    )
                    .blur(
                        radius:
                            LandingButtonPressed ? 15 : 0
                    ).animation(
                        .snappy(
                            duration: 1.0
                        ),
                        value: LandingButtonPressed
                    ).onTapGesture {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil)
                    }

                RegistrationView(
                    phoneNumber: $phoneNumber,
                    phoneNumberReceived: $phoneNumberReceived,
                    phoneCode: $phoneCode
                )
                .ignoresSafeArea(.all)
                .opacity(
                    LandingButtonPressed && !phoneNumberReceived ? 1 : 0
                ).onTapGesture {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder), to: nil,
                        from: nil,
                        for: nil)
                }
                .animation(
                    .snappy(duration: 1.0),
                    value: !phoneNumberReceived && LandingButtonPressed
                )
                .disabled(
                    !LandingButtonPressed || phoneNumberReceived
                )

                Button(action: {
                    LandingButtonPressed = true
                }) {
                    LandingButton()
                }.sensoryFeedback(.success, trigger: LandingButtonPressed)
                    .buttonStyle(.plain)
                    .opacity(LandingButtonPressed ? 0 : 1).blur(
                        radius:
                            LandingButtonPressed ? 10 : 0
                    ).animation(
                        .snappy(duration: 1.0), value: LandingButtonPressed
                    ).percentageOffset(y: 0.7)

                PhoneVerificationView(
                    code: $verifyCode,
                    codeReceived: $verifyCodeReceived,
                    displayError: $displayCodeError
                ).onTapGesture {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder), to: nil,
                        from: nil,
                        for: nil)
                }
                .ignoresSafeArea(.keyboard)
                .opacity(phoneNumberReceived ? 1 : 0)
                .animation(
                    .snappy(duration: 1.0), value: phoneNumberReceived
                )
                .disabled(
                    !phoneNumberReceived
                ).onChange(of: phoneNumberReceived) {
                    sendVerificationCode(
                        phoneNumber: phoneNumber,
                        country_code: phoneCode
                    )
                }.onChange(of: verifyCodeReceived) {
                    if phoneNumberIsVerified(
                        phoneNumber: phoneNumber,
                        country_code: phoneCode,
                        code: verifyCode
                    ) {
                        UserDefaults.standard.set(
                            true, forKey: "numberIsRegistered")
                        var user_phone = "\(phoneCode)\(phoneNumber)"
                        user_phone.replace(" ", with: "")
                        UserDefaults.standard.set(
                            user_phone,
                            forKey:
                                "userPhoneNumber")
                        path.append(".profile_creation")
                    } else {
                        displayCodeError = true
                        verifyCodeReceived = false
                    }
                }

            }.navigationBarBackButtonHidden()
                .navigationDestination(
                    for: String.self,
                    destination: {
                        route in
                        switch route {
                        case ".profile_creation":
                            ProfileCreationHandleInputView(
                                handle: $userHandle, path: $path,
                                progress: $progress
                            ).navigationBarBackButtonHidden()
                        case "bio_input":
                            ProfileCreationBioInputView(
                                bio: $userBio, path: $path, progress: $progress
                            ).navigationBarBackButtonHidden()
                        default:
                            EmptyView()
                        }
                    }
                )
        }
    }
}

#Preview {
    AuthenticationView()
}

//
//.toolbar {
//    ToolbarItem(placement: .principal) {
//        ProfileCreationProgressBar(
//            progress: $progress
//        )
//        .progressViewStyle(.linear)
//    }
//}

// what do i do with this...
//
// so probably the best idea would be to make the toolbar on the
// authenticationView and then handle whether we need to show the
// bar via .toolbar(.hidden) through a boolean variable
