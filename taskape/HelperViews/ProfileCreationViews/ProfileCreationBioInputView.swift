//
//  ProfileCreationBioInputView.swift
//  taskape
//
//  Created by shevlfs on 1/28/25.
//

import SwiftUI

struct ProfileCreationBioInputView: View {
    @Binding var bio: String
    @Binding var path: NavigationPath
    @Binding var progress: Float
    var body: some View {
        Text( /*@START_MENU_TOKEN@*/"Hello, World!" /*@END_MENU_TOKEN@*/)
            
    }
}

#Preview {
    @Previewable @State var bio: String = ""
    @Previewable @State var path = NavigationPath()
    ProfileCreationBioInputView(
        bio: $bio,
        path: $path, progress: .constant(0.0)
    )
}
