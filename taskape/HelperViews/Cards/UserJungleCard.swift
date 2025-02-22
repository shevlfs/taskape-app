//
//  UserJungleView.swift
//  taskape
//
//  Created by shevlfs on 1/8/25.
//
import SwiftUI
import _SwiftData_SwiftUI

struct UserJungleCard: View {
    @Bindable var user: taskapeUser
    var body: some View {
        ZStack {
            MenuItem(
                mainColor: Color.taskapeOrange,
                widthProportion: 0.93,
                heightProportion: 0.24
            )

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("your jungle")
                        .font(.pathwaySemiBold(19))
                    Spacer()
                    Image(systemName: "chevron.right.circle")
                        .font(.system(size: 21))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(user.tasks) {
                            task in
                            TaskItem(task: task)
                        }
                    }
                }.scrollDisabled(true)
                    .padding(.horizontal, 16)

                HStack {
                    Spacer()
                    Text("& 5 others...")
                        .font(.pathwaySemiBoldCondensed)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .padding(.top, 8)
            }
            .frame(
                width: UIScreen.main.bounds.width * 0.93,
                height: UIScreen.main.bounds.height * 0.24
            )
        }
    }
}

struct TaskItem: View {
    @Bindable var task: taskapeTask
    var body: some View {
        HStack {
            Text("•  \(task.name)")
                .font(.pathway(14))
                .lineLimit(1)
            Spacer()
            Text("")
        }
    }
}

#Preview {
    // UserJungleCard()
}
