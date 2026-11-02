import SwiftUI
import FamilyControls

private let mint = Color(red: 0.72, green: 0.94, blue: 0.67)

struct FocusView: View {
    @Bindable var controller: FocusController
    @Environment(\.scenePhase) private var scenePhase
    @State private var selected = FocusPreset.defaults[0]
    @State private var blocking = true
    @State private var picker = false
    @State private var editor = false
    @State private var confirmEnd = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        Label("FOKUS", systemImage: "sparkle").font(.system(.subheadline, design: .rounded, weight: .bold)).tracking(3)
                        Spacer()
                        Text("ZEIT FÜR DICH").font(.caption2).tracking(2).foregroundStyle(.secondary)
                    }
                    if let session = controller.session {
                        activeSession(session)
                    } else {
                        Text("Weniger scrollen.\nMehr schaffen.")
                            .font(.system(size: 38, weight: .semibold, design: .rounded)).tracking(-1)
                        Text("Ein klarer Kopf beginnt mit einer kleinen Pause vom Rest der Welt.")
                            .foregroundStyle(.secondary)
                        timer(minutes: selected.minutes)
                        HStack { Text("Dein Lernrhythmus").font(.headline); Spacer(); Button { editor = true } label: { Image(systemName: "plus.circle.fill").font(.title2) }.accessibilityLabel("Eigenen Fokus erstellen") }
                        ForEach(controller.presets) { preset in
                            Button { selected = preset } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: preset.breakMinutes > 0 ? "leaf" : "moon.stars").font(.title2).frame(width: 38)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(preset.name).font(.headline)
                                        Text("\(preset.minutes) Min. Fokus" + (preset.breakMinutes > 0 ? " · \(preset.breakMinutes) Min. Pause" : " · ohne Pause")).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: selected.id == preset.id ? "checkmark.circle.fill" : "circle").foregroundStyle(selected.id == preset.id ? mint : .gray)
                                }.padding(18).background(selected.id == preset.id ? mint.opacity(0.10) : Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 20))
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(selected.id == preset.id ? mint.opacity(0.5) : .clear))
                            }.buttonStyle(.plain)
                        }
                        VStack(alignment: .leading, spacing: 18) {
                            Toggle(isOn: $blocking) { Label("Ablenkungen sperren", systemImage: "lock.shield") }.tint(mint)
                            if blocking {
                                Button {
                                    Task {
                                        if !controller.authorized { await controller.authorize() }
                                        if controller.authorized { picker = true }
                                    }
                                } label: {
                                    HStack { Text(controller.hasSelection ? "App-Auswahl bearbeiten" : "Apps auswählen"); Spacer(); Image(systemName: "chevron.right") }
                                }
                                Text("Wähle die Apps, Kategorien und Websites, die während deiner Lernzeit gesperrt sind. In der Pause sind sie wieder frei.").font(.caption).foregroundStyle(.secondary)
                            }
                        }.padding(20).background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 20))
                        Button { Task {
                            await controller.start(selected, blocking: blocking)
                        } } label: {
                            Label("Fokus starten", systemImage: "play.fill").frame(maxWidth: .infinity).padding(12)
                        }.buttonStyle(.borderedProminent).tint(mint).foregroundStyle(.black).disabled(controller.busy)
                        Text("Eine Runde nach der anderen. Die nächste startest du bewusst selbst.").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                    }
                }.padding(24)
            }.background(Color(red: 0.055, green: 0.075, blue: 0.065))
                .toolbar(.hidden, for: .navigationBar)
        }.tint(mint)
            .familyActivityPicker(isPresented: $picker, selection: $controller.selection)
            .onChange(of: picker) { _, open in if !open { controller.saveSelection() } }
            .sheet(isPresented: $editor) { PresetEditor(controller: controller) }
            .alert("Hinweis", isPresented: Binding(get: { controller.message != nil }, set: { if !$0 { controller.message = nil } })) { Button("OK") { controller.message = nil } } message: { Text(controller.message ?? "") }
            .confirmationDialog("Fokus vorzeitig beenden? Deine Apps werden wieder freigegeben.", isPresented: $confirmEnd, titleVisibility: .visible) { Button("Fokus beenden", role: .destructive) { Task { await controller.finish() } } }
            .onChange(of: scenePhase) { _, phase in if phase == .active { controller.refresh() } }
            .task {
                if let first = controller.presets.first { selected = first }
                while !Task.isCancelled {
                    controller.refresh()
                    try? await Task.sleep(for: .seconds(1))
                }
            }
    }
    private func timer(minutes: Int) -> some View {
        ZStack {
            Circle().stroke(.white.opacity(0.06), lineWidth: 7)
            Circle().trim(from: 0, to: 0.78).stroke(mint, style: StrokeStyle(lineWidth: 7, lineCap: .round)).rotationEffect(.degrees(-90))
            VStack(spacing: 8) {
                Text(String(format: "%02d:00", minutes)).font(.system(size: 58, weight: .light, design: .rounded)).monospacedDigit()
                Text("DEIN NÄCHSTER FOKUS").font(.caption2).tracking(2).foregroundStyle(.secondary)
            }
        }.frame(width: 250, height: 250).frame(maxWidth: .infinity).padding(.vertical, 10).accessibilityElement(children: .combine)
    }
    private func activeSession(_ session: FocusSession) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let rest = session.phase(at: context.date) != .focus
            let target = rest ? session.end : session.focusEnd
            VStack(spacing: 30) {
                Image(systemName: rest ? "cup.and.saucer" : "leaf").font(.system(size: 50)).foregroundStyle(mint)
                Text(rest ? "Durchatmen." : "Jetzt zählt nur du.").font(.largeTitle.bold())
                Text(session.name).foregroundStyle(.secondary)
                Text(timerInterval: min(context.date, target)...target, countsDown: true)
                    .font(.system(size: 66, weight: .light, design: .rounded)).monospacedDigit()
                Text(rest ? "Deine Apps sind frei. Genieße deine Pause." : session.blocksApps ? "Deine ausgewählten Apps sind gesperrt." : "Dein Timer läuft ohne App-Sperre.")
                    .multilineTextAlignment(.center).foregroundStyle(.secondary)
                Label("Auch auf deinem Sperrbildschirm", systemImage: "iphone.gen3").font(.caption)
                Button("Vorzeitig beenden", role: .destructive) { confirmEnd = true }.padding(.top, 24)
            }.frame(maxWidth: .infinity).padding(.vertical, 50)
        }
    }
}

struct PresetEditor: View {
    var controller: FocusController
    @Environment(\.dismiss) private var dismiss
    @State private var name = "Mein Fokus"
    @State private var minutes = 25
    @State private var rest = 5
    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Stepper("\(minutes) Minuten Fokus", value: $minutes, in: 15...180, step: 5)
                Stepper("\(rest) Minuten Pause", value: $rest, in: 0...60, step: 5)
                Text("Fokusphasen dauern mindestens 15 Minuten. Mit 0 Minuten Pause endet die Runde direkt nach dem Fokus.").font(.caption).foregroundStyle(.secondary)
            }.navigationTitle("Eigener Fokus")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Speichern") {
                        controller.add(FocusPreset(name: name.trimmingCharacters(in: .whitespacesAndNewlines), minutes: minutes, breakMinutes: rest)); dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
                }
        }.tint(mint)
    }
}
