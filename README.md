# Lernfokus – Lernzeit für dein iPhone

![App-Icon](Fokus/Assets.xcassets/AppIcon.appiconset/FokusIcon.png)

Native SwiftUI-App für iPhone ab iOS 17. Öffne `Fokus.xcodeproj` in Xcode und wähle das Scheme **Fokus**.

## Bildschirmzeit-Version

Diese Variante sperrt ausgewählte Apps, Kategorien und Websites während der Lernzeit über Apples Bildschirmzeit-Schnittstellen. Zum Fokusende gibt die DeviceActivity-Erweiterung die Apps für die Pause wieder frei. Mit ausgeschaltetem Schalter „Ablenkungen sperren“ ist ein reiner Timer möglich.

Die Version mit iPhone-Systemfokus über Kurzbefehle bleibt auf dem Branch [iphone-fokus](https://github.com/trystrikex/lernfokus/tree/iphone-fokus) erhalten. Eine eigenständige lokale Kopie liegt im Ordner `iPhoneFokus` (nicht Bestandteil von `main`), mit eigener Bundle-ID `de.fokuslern.iphonefocus`.

Für Bildschirmzeit-Sperren ist ein Apple-Developer-Team erforderlich, das Family Controls unterstützt. Ein kostenloses Personal Team unterstützt diese Capability nicht. Die Bildschirmzeit-Zustimmung auf dem iPhone kann diese Signierungsvoraussetzung nicht ersetzen.

Das Scheme `Fokus` startet die Haupt-App und baut `FocusMonitor` und `FocusLiveActivity` automatisch mit. Die Erweiterungen werden nicht direkt gestartet.

## Enthalten

- 25 Minuten Fokus + 5 Minuten Pause, 60 Minuten Fokus sowie 50 + 10.
- Eigene, lokal gespeicherte Lernrhythmen (15–180 Minuten Fokus, 0–60 Minuten Pause).
- Bildschirmzeit-App-Auswahl und App-Sperren über FamilyControls, ManagedSettings und DeviceActivity.
- Optionaler Timer ohne App-Sperren, gespeicherte Sitzungen und Wiederherstellung beim Öffnen.
- Live Activity auf dem Sperrbildschirm und in der Dynamic Island; Mitteilungen zu Fokus- und Pausenende.
- Vorzeitiges Beenden mit Bestätigung. Jede weitere Lernrunde wird bewusst manuell gestartet.

## Auf dem iPhone installieren

1. Ein geeignetes Apple-Developer-Team in allen drei Targets auswählen und automatische Signierung aktivieren.
2. Eigene eindeutige Bundle-IDs eintragen. Beide Erweiterungs-IDs müssen mit der Haupt-App-ID beginnen.
3. Eine App Group registrieren und `group.de.fokuslern.app` in allen drei Entitlements sowie `Shared/ScreenTimeStore.swift` ersetzen.
4. Family Controls für **Fokus** und **FocusMonitor** aktivieren. Für TestFlight/App Store ist die Distribution-Freigabe von Apple für beide Targets notwendig.
5. iPhone verbinden, Entwicklermodus aktivieren und das Scheme **Fokus** starten.
6. „Apps auswählen“ antippen, Bildschirmzeit freigeben und Apps wählen. Live-Aktivitäten und Mitteilungen erlauben.

## Technische Grenzen und ehrlicher Teststatus

Die Bildschirmzeit-Version wurde wiederhergestellt. Der Build wird ohne Signierung geprüft; App-Sperren, Hintergrund-Freigabe und Live Activities müssen auf einem passend signierten echten Gerät getestet werden. Die zuvor bestätigte iPhone-Installation betraf die Variante ohne Bildschirmzeit.

DeviceActivity benötigt Überwachungsintervalle von mindestens 15 Minuten. Die 5-Minuten-Pause braucht kein eigenes Sperrintervall. iOS verwaltet die Zustellung der Hintergrund-Callbacks; eine sekundengenaue Freigabe ist nicht garantiert. Beim Öffnen der App wird der Sperrstatus zusätzlich anhand der gespeicherten Endzeit abgeglichen.

Die Live Activity verwendet einen systemseitigen Countdown, der bei null stehen bleibt. Sie zeigt die Pausen-Endzeit separat; ohne erneute App-Ausführung gibt es keinen automatisch umgeschalteten Phasentitel. Eine abgelaufene Anzeige kann bis zum nächsten Öffnen bzw. Entfernen durch iOS sichtbar bleiben. Es gibt keinen Push-Server. Die App erhebt keine Nutzungsdaten und sendet keine Daten an einen eigenen Server.

Die individuelle Bildschirmzeit-Zustimmung kann in den Einstellungen entzogen werden. Diese App ist eine freiwillige Selbstsperre.

## Prüfen

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Fokus.xcodeproj -scheme Fokus -sdk iphonesimulator \
  -configuration Debug -derivedDataPath /tmp/FokusBuild \
  CODE_SIGNING_ALLOWED=NO build

swiftc Shared/FocusSession.swift Tests/SessionTests.swift -o /tmp/fokus-session-tests
/tmp/fokus-session-tests
```

Manueller Gerätetest: Apps wählen → 25 + 5 starten → ausgewählte App öffnen (gesperrt) → iPhone sperren (Countdown) → Fokusende abwarten (frei) → Pauseende. Zusätzlich: reiner Timer, Abbruch, App-Neustart, abgelehnte Berechtigungen und Sitzung über Mitternacht.

`scripts/generate_project.py` erzeugt das Xcode-Projekt und die Plists reproduzierbar. Bestehende Team-Auswahl, Bundle-IDs, Signierungsidentität und Profilangaben werden übernommen.

## Apple-Dokumentation

- [Family Controls und Distribution](https://developer.apple.com/documentation/FamilyControls/requesting-the-family-controls-entitlement)
- [DeviceActivity: Mindestdauer](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter/monitoringerror/intervaltooshort)
- [Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)
