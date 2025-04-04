import SwiftData
import SwiftUI

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
                    if Array(
                        user.tasks.filter { !$0.completion.isCompleted }
                    ).count != 0 {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(
                                Array(
                                    user.tasks.filter {
                                        !$0.completion.isCompleted
                                    }
                                    .prefix(3))
                            ) { task in
                                TaskItem(task: task)
                            }
                        }
                    } else {
                        VStack(alignment: .center) {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("woo-hoo everything is done!")
                                    .font(.pathway(16))
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }.scrollDisabled(true)
                    .padding(.horizontal, 16)

                HStack {
                    Spacer()
                    let uncompletedTasks = user.tasks.filter {
                        !$0.completion.isCompleted
                    }
                    if uncompletedTasks.count > 3 {
                        Text("& \(uncompletedTasks.count - 3) others...")
                            .font(.pathwaySemiBoldCondensed)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .padding(.top, 8)
            }
            .frame(
                width: UIScreen.main.bounds.width * 0.93,
                height: UIScreen.main.bounds.height * 0.24
            )
        }.frame(
            width: UIScreen.main.bounds.width * 0.93,
            height: UIScreen.main.bounds.height * 0.24
        )
    }
}

struct TaskItem: View {
    @Bindable var task: taskapeTask
    var body: some View {
        HStack {
            if task.name != "" {
                Text("•  \(task.name)")
                    .font(.pathway(14))
                    .lineLimit(1)
                Spacer()
                Text("")
            } else {
                Text("•  new to-do")
                    .font(.pathway(14)).foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Text("")
            }
        }
    }
}

#Preview {}
