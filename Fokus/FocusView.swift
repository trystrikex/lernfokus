import SwiftUI

private let mint = Color(red: 0.72, green: 0.94, blue: 0.67)

struct FocusView: View {
    @Bindable var controller: FocusController
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var selected = FocusPreset.defaults[0]
    @AppStorage("useSystemFocusShortcut") private var useSystemFocus = false
    @State private var focusHelp = false
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
                            Toggle(isOn: $useSystemFocus) { Label("iPhone-Fokus einschalten", systemImage: "moon.fill") }.tint(mint)
                            Text("Über deinen Kurzbefehl „Lernfokus“. Er schaltet Mitteilungen bis zum Ende der Lernzeit stumm. Apps bleiben zugänglich.").font(.caption).foregroundStyle(.secondary)
                            Button("Einmalige Einrichtung anzeigen") { focusHelp = true }
                        }.padding(20).background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 20))
                        Button { Task {
                            await controller.start(selected)
                            if useSystemFocus, let session = controller.session {
                                var components = URLComponents(string: "shortcuts://run-shortcut")!
                                components.queryItems = [
                                    URLQueryItem(name: "name", value: "Lernfokus"),
                                    URLQueryItem(name: "input", value: "text"),
                                    URLQueryItem(name: "text", value: session.focusEnd.ISO8601Format())
                                ]
                                if let url = components.url {
                                    openURL(url) { accepted in
                                        if !accepted { controller.message = "Dein Timer läuft. Kurzbefehle konnte nicht geöffnet werden. Prüfe, ob die Kurzbefehle-App installiert ist." }
                                    }
                                }
                            }
                        } } label: {
                            Label("Fokus starten", systemImage: "play.fill").frame(maxWidth: .infinity).padding(12)
                        }.buttonStyle(.borderedProminent).tint(mint).foregroundStyle(.black).disabled(controller.busy)
                        Text("Eine Runde nach der anderen. Die nächste startest du bewusst selbst.").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                    }
                }.padding(24)
            }.background(Color(red: 0.055, green: 0.075, blue: 0.065))
                .toolbar(.hidden, for: .navigationBar)
        }.tint(mint)
            .sheet(isPresented: $editor) { PresetEditor(controller: controller) }
            .sheet(isPresented: $focusHelp) { SystemFocusHelp() }
            .alert("Hinweis", isPresented: Binding(get: { controller.message != nil }, set: { if !$0 { controller.message = nil } })) { Button("OK") { controller.message = nil } } message: { Text(controller.message ?? "") }
            .confirmationDialog("Timer vorzeitig beenden? Einen über Kurzbefehle aktivierten iPhone-Fokus beendest du separat im Kontrollzentrum.", isPresented: $confirmEnd, titleVisibility: .visible) { Button("Timer beenden", role: .destructive) { Task { await controller.finish() } } }
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
                Text(rest ? "Genieße deine Pause." : "Zeit zum Lernen. Dein Timer läuft.")
                    .multilineTextAlignment(.center).foregroundStyle(.secondary)
                Label("Auch auf deinem Sperrbildschirm", systemImage: "iphone.gen3").font(.caption)
                Button("Vorzeitig beenden", role: .destructive) { confirmEnd = true }.padding(.top, 24)
            }.frame(maxWidth: .infinity).padding(.vertical, 50)
        }
    }
}

struct SystemFocusHelp: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("Einmal auf deinem iPhone einrichten") {
                    Text("1. Lege unter Einstellungen → Fokus einen Fokus „Lernen“ an und wähle, welche Mitteilungen erlaubt sind. Alternativ kannst du „Nicht stören“ verwenden.")
                    Text("2. Erstelle in Apples Kurzbefehle-App einen Kurzbefehl mit dem Namen „Lernfokus“.")
                    Text("3. Füge die Aktion „Datumsangaben aus Eingabe abrufen“ hinzu. Verwende als Eingabe die Variable „Kurzbefehlseingabe“. Die App übergibt hier das Ende deiner Lernzeit.")
                    Text("4. Füge „Fokus festlegen“ hinzu: deinen Fokus einschalten, bis „Zeit“. Wähle als Zeit das Datum aus der vorherigen Aktion.")
                    Text("5. Kehre zur App zurück und aktiviere „iPhone-Fokus einschalten“. Beim Timerstart öffnet sich Kurzbefehle und führt „Lernfokus“ aus. Bestätige beim ersten Mal gegebenenfalls den Zugriff.")
                }
                Section("Während deiner Lernzeit") {
                    Text("Der iPhone-Fokus wird von deinem Kurzbefehl gesteuert. Die App kann nicht prüfen, ob er erfolgreich aktiviert wurde. Teste die Einrichtung einmal mit einem Timer.")
                    Text("Der Fokus endet zur übergebenen Zeit, auch wenn du die App verlässt. Bei vorzeitigem Timer-Abbruch schaltest du ihn im Kontrollzentrum selbst aus.")
                    Text("Ein iPhone-Fokus filtert Mitteilungen und kann Home-Bildschirme ausblenden. Er sperrt keine Apps. Bildschirmzeit ist für diesen Timer nicht erforderlich.")
                }
                Link("Kurzbefehle öffnen", destination: URL(string: "shortcuts://")!)
            }.navigationTitle("iPhone-Fokus")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } } }
        }.tint(mint)
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
