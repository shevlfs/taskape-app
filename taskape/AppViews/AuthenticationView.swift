//
//  AuthenticationView.swift
//  taskape
//
//  Created by shevlfs on 1/7/25.
//

import Lottie
import SwiftData
import SwiftUI

struct AuthenticationView: View {
    @Query private var users: [taskapeUser]
    @Environment(\.modelContext) private var modelContext
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

    @State var progress: Float = 1 / 5

    @State var userHandle: String = ""
    @State var userBio: String = ""

    @State var userColor: String = ""

    @State var userProfileImageData: UIImage?

    @Namespace private var namespace

    private func createUser() {
        let newUser = taskapeUser(
            id: UUID().uuidString,
            handle: userHandle,
            bio: userBio, profileImage: userProfileImageData,
            profileColor: userColor
        )
        modelContext.insert(newUser)

        let userPhone: String = "\(phoneCode)\(phoneNumber)"
            .replacingOccurrences(of: " ", with: "")

        do {
            try modelContext.save()
            UserDefaults.standard.set(true, forKey: "numberIsRegistered")
            UserDefaults.standard.set(userPhone, forKey: "userPhoneNumber")
        } catch {
            print("Error saving user: \(error)")
        }
    }

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
                    Task {
                        await sendVerificationCode(
                            phoneNumber: phoneNumber,
                            country_code: phoneCode
                        )
                    }
                }.onChange(of: verifyCodeReceived) {
                    Task {
                        if await phoneNumberIsVerified(
                            phoneNumber: phoneNumber,
                            country_code: phoneCode,
                            code: verifyCode
                        ) {
                            path.append(".profile_creation")
                        } else {
                            displayCodeError = true
                            verifyCodeReceived = false
                        }
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
                                .navigationTransition(
                                    .zoom(sourceID: "default", in: namespace))
                        case "bio_input":
                            ProfileCreationBioInputView(
                                bio: $userBio, path: $path, progress: $progress
                            ).navigationBarBackButtonHidden()
                        case "color_selection":
                            ProfileCreationColorSelectionView(
                                color: $userColor,
                                path: $path,
                                progress: $progress
                            ).navigationBarBackButtonHidden()
                        case "pfp_selection":
                            ProfileCreationPFPSelectionView(
                                image: $userProfileImageData,
                                path: $path,
                                progress: $progress
                            )
                            .navigationBarBackButtonHidden()
                        case "completion":
                            ProfileCreationProgressBar(progress: $progress)
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
