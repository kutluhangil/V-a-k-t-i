import WidgetKit
import SwiftUI

// Vakti home screen widget (blueprint §8.2). Reads the daily tip that Flutter
// writes into the shared App Group via the home_widget bridge.
// NOTE: this target must be added once in Xcode (see docs/ios_widget_setup.md);
// the App Group is group.com.vakti.app.

private let appGroupId = "group.com.vakti.app"

struct VaktiEntry: TimelineEntry {
    let date: Date
    let emoji: String
    let title: String
    let primary: String
    let secondary: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> VaktiEntry {
        VaktiEntry(date: Date(), emoji: "🌅", title: "Vakti",
                   primary: "", secondary: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (VaktiEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VaktiEntry>) -> Void) {
        // Refresh at the next midnight so the daily tip rolls over.
        let entry = readEntry()
        let next = Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func readEntry() -> VaktiEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        return VaktiEntry(
            date: Date(),
            emoji: defaults?.string(forKey: "emoji") ?? "🌅",
            title: defaults?.string(forKey: "title") ?? "Vakti",
            primary: defaults?.string(forKey: "primary") ?? "",
            secondary: defaults?.string(forKey: "secondary") ?? ""
        )
    }
}

struct VaktiWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.emoji).font(.title3)
                Spacer()
                Text("VAKTİ")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundColor(Color(red: 0.88, green: 0.64, blue: 0.29))
            }
            Spacer(minLength: 2)
            Text(entry.title)
                .font(.system(.headline, design: .serif))
                .foregroundColor(Color(red: 0.95, green: 0.94, blue: 0.91))
                .lineLimit(2)
            if !entry.primary.isEmpty {
                Text(entry.primary)
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.95, green: 0.94, blue: 0.91))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .widgetURL(URL(string: "vakti://tip"))
        .containerBackground(for: .widget) {
            Color(red: 0.078, green: 0.094, blue: 0.122)
        }
    }
}

@main
struct VaktiWidget: Widget {
    let kind: String = "VaktiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VaktiWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Vakti")
        .description("Doğru bilgi, doğru vakitte.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
