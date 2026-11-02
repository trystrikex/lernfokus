import SwiftUI
import WidgetKit
import ActivityKit

@main struct FocusWidgets: WidgetBundle {
    var body: some Widget { FocusLiveActivity() }
}

struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusAttributes.self) { context in
            VStack(alignment: .leading, spacing: 12) {
                Label(context.attributes.name, systemImage: "leaf.fill").font(.headline)
                HStack {
                    VStack(alignment: .leading) {
                        Text("Fokus verbleibend").font(.caption)
                        Text(timerInterval: context.state.start...context.state.focusEnd, countsDown: true).font(.largeTitle).monospacedDigit()
                    }
                    Spacer()
                    if context.state.end > context.state.focusEnd {
                        VStack(alignment: .trailing) {
                            Text("Pause bis").font(.caption)
                            Text(context.state.end, style: .time).font(.title2)
                            Text("ab \(context.state.focusEnd.formatted(date: .omitted, time: .shortened))").font(.caption2)
                        }
                    }
                }
            }.padding(20).activityBackgroundTint(Color(red: 0.08, green: 0.12, blue: 0.09)).activitySystemActionForegroundColor(.white).foregroundStyle(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Label("Fokus", systemImage: "leaf.fill") }
                DynamicIslandExpandedRegion(.trailing) { Text(timerInterval: context.state.start...context.state.focusEnd, countsDown: true).monospacedDigit().frame(width: 80) }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.end > context.state.focusEnd ? "Anschließend Pause bis \(context.state.end.formatted(date: .omitted, time: .shortened))" : context.attributes.name).font(.caption)
                }
            } compactLeading: { Image(systemName: "leaf.fill") }
              compactTrailing: { Text(timerInterval: context.state.start...context.state.focusEnd, countsDown: true).monospacedDigit().frame(width: 48) }
              minimal: { Image(systemName: "leaf.fill") }
        }
    }
}
