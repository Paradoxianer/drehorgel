# Web-Version auf heilsarmee.de

Ziel-URL: <https://www.heilsarmee.de/files/orgel-app/#/>

## Bauen

GitHub → Actions → „Web-Build für heilsarmee.de“ → *Run workflow*; das
Artifact `orgel-app` entpacken und den Inhalt nach `/files/orgel-app/`
hochladen. Lokal:

```sh
flutter build web --release --base-href /files/orgel-app/ \
  --no-web-resources-cdn --pwa-strategy=none
```

## Datenschutz – was dafür geändert wurde

- `--no-web-resources-cdn`: CanvasKit und Schriften kommen vom eigenen Server,
  nicht von gstatic.com (Google). Der Workflow bricht ab, wenn Verweise auf
  Google-Hosts im Build stehen.
- `--pwa-strategy=none` und kein Service Worker in `web/index.html`: nichts
  wird im Browser gespeichert, deshalb ist kein Banner nach § 25 TDDDG nötig.
- Content-Security-Policy und `Referrer-Policy` als `<meta>` in `web/index.html`
  (falls der Server echte Header setzen kann, besser dort).
- Im Info-Dialog der Web-Version verlinken Impressum und Datenschutz auf
  <https://www.heilsarmee.de/impressum.html> (Verantwortliche: Die Heilsarmee
  in Deutschland KdöR). Die App selbst erhebt keine Daten; es fallen nur die
  Server-Logs des Webservers an (laut Heilsarmee-Datenschutzerklärung max. 3 Tage).
- Der Spenden-Button öffnet erst nach Bestätigung die Twingle-Seite auf
  heilsarmee.de und übergibt nur Betrag und Korps-Nummer.

## Zu klären mit der Heilsarmee

- Datenschutzbeauftragte/r der Heilsarmee soll die Web-Version freigeben und
  die Datenschutzerklärung ggf. um einen Absatz „Drehorgel-Web-App“ ergänzen.
- Der Server muss `.js`, `.wasm`, `.json`, `.mp3` mit korrekten MIME-Typen liefern.
- Nutzungsrechte an Grafiken (Florian Walz) und Musik (Daniel Matzeit) für das
  Hosting bei der Heilsarmee.
- Korps per URL wählen: `…/orgel-app/?custom1=<Korps-Nr>&custom2=<Zweck>#/`
  (Query-String vor dem `#`). Bitte nach dem Upload testen.

Hinweis: Diese Änderungen wurden ohne Flutter-SDK erstellt und noch nicht
gebaut/getestet – bitte zuerst den Workflow laufen lassen.
