import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), tasks: sampleTasks)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let tasks = WidgetDataManager.shared.loadTasks()
        let entry = SimpleEntry(date: Date(), tasks: tasks.isEmpty ? sampleTasks : tasks)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let tasks = WidgetDataManager.shared.loadTasks()

        // Create entry for current time
        let entry = SimpleEntry(date: currentDate, tasks: tasks)

        // Create a timeline that refreshes every 30 minutes
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTaskModel]
}

struct TaskapeWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Simplified gradient background inspired by MenuItem but simpler
            LinearGradient(
                stops: colorScheme == .dark ? [
                    Gradient.Stop(color: Color.taskapeOrange.opacity(0.9), location: 0.1),
                    Gradient.Stop(color: Color.taskapeOrange.opacity(0.7), location: 0.5),
                    Gradient.Stop(color: Color.taskapeOrange.opacity(0.5), location: 0.9),
                ] : [
                    Gradient.Stop(color: Color.taskapeOrange.opacity(0.8), location: 0.1),
                    Gradient.Stop(color: Color.taskapeOrange.opacity(0.6), location: 0.5),
                    Gradient.Stop(color: Color.taskapeOrange.opacity(0.4), location: 0.9),
                ],
                startPoint: UnitPoint(x: 0.5, y: 1),
                endPoint: UnitPoint(x: 0.5, y: 0)
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .inset(by: 0.5)
                    .stroke(
                        colorScheme == .dark ?
                            Color.taskapeOrange.opacity(0.3) : Color.taskapeOrange.opacity(0.15),
                        lineWidth: colorScheme == .dark ? 1.5 : 1
                    )
            )

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("your jungle")
                        .font(.pathwaySemiBold(19))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

                if entry.tasks.isEmpty {
                    Spacer()
                    Text("no tasks yet")
                        .font(.pathway(16))
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(Array(entry.tasks.prefix(3))) { task in
                            HStack {
                                if task.name.isEmpty {
                                    Text("•  new to-do")
                                        .font(.pathway(14)).opacity(0.8)
                                        .lineLimit(1)
                                } else {
                                    Text("•  \(task.name)")
                                        .font(.pathway(14))
                                        .lineLimit(1)
                                        .strikethrough(task.isCompleted)
                                        .opacity(task.isCompleted ? 0.5 : 1)
                                }

                                Spacer()
                                
                                if task.isCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                }

                                if let flagColor = task.flagColor, !flagColor.isEmpty {
                                    Circle()
                                        .fill(Color(hex: flagColor))
                                        .frame(width: 8, height: 8)
                                        .padding(.leading, 4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()

                    if entry.tasks.count > 3 {
                        HStack {
                            Spacer()
                            Text("& \(entry.tasks.count - 3) others...")
                                .font(.pathwaySemiBoldCondensed(14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .padding(.top, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

@main
struct TaskapeWidget: Widget {
    let kind: String = "TaskapeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TaskapeWidgetEntryView(entry: entry)
        }.contentMarginsDisabled()
        .configurationDisplayName("taskape")
        .description("view your tasks at a glance")
        .supportedFamilies([.systemMedium]) // Only support medium size
    }
}

// Sample tasks for preview and placeholder
let sampleTasks: [WidgetTaskModel] = [
    WidgetTaskModel(id: "1", name: "finish the project", isCompleted: false, flagColor: nil, flagName: nil),
    WidgetTaskModel(id: "2", name: "buy groceries", isCompleted: false, flagColor: "#FF6B6B", flagName: "important"),
    WidgetTaskModel(id: "3", name: "call mom", isCompleted: true, flagColor: nil, flagName: nil)
]

// Color extension for widget (matching the app's implementation)
extension Color {
    static var taskapeOrange: Color {
        Color(red: 0.914, green: 0.427, blue: 0.078)
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct TaskapeWidget_Previews: PreviewProvider {
    static var previews: some View {
        TaskapeWidgetEntryView(entry: SimpleEntry(date: Date(), tasks: sampleTasks))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

extension Font {
    static func pathway(_ size: CGFloat) -> Font {
        .custom("PathwayExtreme-Regular", size: size)
    }

    static func pathwayBold(_ size: CGFloat) -> Font {
        .custom("PathwayExtreme-Bold", size: size)
    }

    static func pathwayBlack(_ size: CGFloat) -> Font {
        .custom("PathwayExtreme-Black", size: size)
    }

    static func pathwaySemiBold(_ size: CGFloat) -> Font {
        .custom("PathwayExtreme-SemiBold", size: size)
    }

    static func pathwayItalic(_ size: CGFloat) -> Font {
        .custom("PathwayExtreme-Italic", size: size)
    }

    static func pathwaySemiBoldCondensed(_ size: CGFloat) -> Font {
        .custom("PathwayExtreme-SemBdCond", size: size)
    }
}

