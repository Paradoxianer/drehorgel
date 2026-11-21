# Drehorgel

Eine App, die das weihnachtliche Spendensammeln der Heilsarmee mit der
Drehorgel simuliert. Wer kurbelt, spielt Musik und „ersammelt“ dabei Geld –
den erorgelten Betrag kann man am Ende direkt an die Heilsarmee spenden
(Korps Chemnitz-Kaßberg).

![Screenshot_20211214-111244](https://user-images.githubusercontent.com/7062893/146240104-c7d60894-13eb-4b5b-bd14-9c67a247e9b4.png)
![Screenshot_20211214-111313](https://user-images.githubusercontent.com/7062893/146240299-a1609e6f-a611-44e5-ba75-2a2458ca7b98.png)

## Funktionen

- **Querformat:** ganze Szene mit Drehorgel, Salutisten und Spendentopf.
  **Hochformat:** nur die Drehorgel.
- **Kurbel:** Drehgeschwindigkeit = Tempo (stufenlos). Langsames Kurbeln macht
  die Orgel leiser und tiefer, beim Anhalten sackt die letzte Note ab
  („Blasebalg leer“).
- **Notenrollen** wie bei einer echten Drehorgel: *Weihnachtsrolle* und
  *Standardrolle*, mehrere Strophen pro Lied, Lieder einzeln anwählbar.
- Pro Umdrehung fällt eine Münze in den Spendentopf; der Spenden-Button öffnet
  das Spendenformular mit vorbelegtem Betrag.

## Technik

- Flutter (Android, Web; iOS ungetestet)
- **Android:** MIDI über FluidSynth ([flutter_midi_pro](https://pub.dev/packages/flutter_midi_pro))
  mit eigener Drehorgel-SoundFont – Tempo ohne Tonhöhenänderung.
  **Web/iOS:** vorgerenderte mp3 der Notenrollen.
- Alle Audio-Assets erzeugt `tools/drehorgel_audio.py` (nur Python-Standard-
  bibliothek, für mp3 zusätzlich ffmpeg):

  ```sh
  python3 tools/drehorgel_audio.py all   # SoundFont, Rollen-MIDI/-Index, mp3
  ```

  Neue Lieder: in `SONGS` als Notentext eintragen, in `ROLLS` einreihen.
  Die Melodien sind gemeinfrei, die Arrangements eigene.
- Szene in festen Bühnenkoordinaten (`lib/globals.dart`, 1920×1080), die als
  Ganzes skaliert wird – deshalb sitzt die Kurbel auf jedem Gerät richtig.

## Bauen

```sh
flutter test
flutter build appbundle --release   # benötigt android/key.properties (nicht im Repo)
flutter build web --release --base-href /drehorgel/app/   # wird per GitHub Action auf paradoxianer.github.io/drehorgel veröffentlicht
```

iOS: siehe [docs/IOS.md](docs/IOS.md).

Der Debug-Build hat die App-ID `de.heilsarmee.orgel.debug` und kann neben der
Play-Store-Version installiert werden.

## Rechtliches

- [Datenschutzerklärung](Datenschutz) · [AGB](AGB) · [Lizenz (MIT)](LICENSE)
