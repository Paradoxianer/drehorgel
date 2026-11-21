# iOS-Build (Mac)

Der iOS-Ordner wurde mit Flutter 3.47 aus der aktuellen Vorlage neu erzeugt
(auf Linux, daher **noch nie auf einem Mac gebaut**). Bundle-ID, Icons,
Anzeigename und Ausrichtungen sind schon gesetzt.

## Stand

| Punkt | Wert |
|---|---|
| Bundle-ID | `de.heilsarmee.orgel` (wie Android) |
| Anzeigename | Drehorgel |
| Mindestversion | iOS 15.0 (Vorlage; `flutter_midi_pro` braucht ≥ 13) |
| Ausrichtung | Hoch- und Querformat (quer: ganze Szene, hoch: nur die Orgel) |
| Icons | aus `android/app/src/main/1024.png` erzeugt (ohne Alphakanal) |
| Version | aus `pubspec.yaml` (aktuell 2.0.0+6) |
| Abhängigkeiten | Swift Package Manager; Plugins ohne SPM-Unterstützung fallen auf CocoaPods zurück |

## Ton auf iOS

`flutter_midi_pro` kann auf iOS/macOS **keine MIDI-Dateien abspielen**
(`loadMidiFile` & Co. werfen dort `UNSUPPORTED`). `OrganPlayer.forPlatform()`
in `lib/organ_player.dart` nimmt deshalb auf iOS automatisch den
`AudioOrganPlayer` mit den vorgerenderten mp3-Rollen (`assets/rolls/*.mp3`).
Das Tempo ändert sich dort in 0,1er-Schritten; „Blasebalg leer“ ist nur ein
Ausklingen. Nichts zu tun, nur beim Testen wissen.

## Schritte

1. Voraussetzungen: Xcode (aktuell), CocoaPods (`sudo gem install cocoapods`
   oder `brew install cocoapods`), Flutter 3.47 (`flutter --version`).
2. ```sh
   git clone https://github.com/Paradoxianer/drehorgel.git
   cd drehorgel
   flutter pub get
   flutter test
   ```
3. `open ios/Runner.xcworkspace` → Target **Runner** → *Signing & Capabilities*
   → eigenes **Team** wählen (Apple-Developer-Account). Bundle-ID nicht ändern,
   außer sie ist im Developer-Account schon anderweitig vergeben.
4. Im Simulator testen: `flutter run` (Simulator vorher in Xcode starten).
   Prüfen: Kurbel dreht und Musik läuft, Hoch-/Querformat, Notenband +
   Rollenauswahl, „Echt spenden“ öffnet Safari.
5. Auf echtem iPhone testen (per Kabel oder WLAN, Team muss gesetzt sein).
6. Release: `flutter build ipa` → Upload mit Xcode-Organizer oder der App
   **Transporter** nach App Store Connect.

## App Store

- In App Store Connect eine App mit Bundle-ID `de.heilsarmee.orgel` anlegen.
- **Spenden:** Apple erlaubt Spendensammel-Apps nur, wenn sie kostenlos sind
  und das Geld **außerhalb der App** (z. B. Safari) gesammelt wird. Die App
  öffnet die Spendenseite der Heilsarmee deshalb bewusst im externen Browser
  (`LaunchMode.externalApplication` in `lib/donation_button.dart`) und erklärt
  das vorher im Dialog. Vor dem Einreichen den aktuellen Wortlaut der
  [App Review Guidelines, Abschnitt 3.2](https://developer.apple.com/app-store/review/guidelines/#business)
  prüfen.
- Datenschutz-URL: `https://raw.githubusercontent.com/Paradoxianer/drehorgel/main/Datenschutz`
- Texte für die Store-Beschreibung: `release/`
