# Changelog

## 2.1.0 (in Arbeit)

### Neu
- Neue Notenrolle mit Liedern der Heilsarmee *(in Arbeit)*
- Eigene Webseite: https://paradoxianer.github.io/drehorgel/ (mit Web-Version)

### Geändert
- Der Teilen-Text verlinkt auf die neue Webseite statt auf die alte Seite des Korps.
- Der Spenden-Dialog zieht sich auf Tablets nicht mehr über die ganze Breite.
- Info-Dialog: Florian Walz wird für Design und Grafik genannt (mit Link), der tote Link bei Daniel Matzeit ist entfernt.

## 2.0.0 (2026-11)

### Neu
- **Querformat-Szene** nach der Original-Illustration: Drehorgel, zwei
  Salutisten und Spendentopf mit Tafel. Im **Hochformat** nur die Drehorgel.
- **Echte Drehorgel-Mechanik:** Die Kurbelgeschwindigkeit bestimmt das Tempo
  (stufenlos, ohne dass sich die Tonhöhe ändert). Langsames Kurbeln macht die
  Orgel leiser und tiefer, beim Anhalten sackt der letzte Ton ab wie bei
  einem leeren Blasebalg.
- **Notenrollen:** *Weihnachtsrolle* (Stille Nacht, We Wish You a Merry
  Christmas, O Tannenbaum, Jingle Bells, Morgen kommt der Weihnachtsmann) und
  *Standardrolle* (Amazing Grace, When the Saints Go Marching In, Ode an die
  Freude, Michael, Row the Boat Ashore) – mit mehreren Strophen, einzelne
  Lieder anwählbar.
- **Fallendes Geld:** Pro Umdrehung fällt eine Münze in den Spendentopf –
  im Hochformat in den Schlitz der Drehorgel, mit Betragsschild an der Orgel.

### Geändert
- Neuer, eigener Drehorgelklang (SoundFont, zwei schwebende Register,
  Tremulant) statt einer einzelnen mp3.
- Realistischere Sammelbeträge: meist Cent-Münzen statt ganzer Euros.
- Spendenformular: Betrag wird vorbelegt und der Spendenzweck fest auf das
  Korps Chemnitz-Kaßberg gesetzt (die Spendenseite nutzt jetzt Twingle).
  Mindestbetrag 5 €.
- Spenden-Button heißt jetzt „Echt spenden“ und erklärt vorher, dass das
  erorgelte Geld nur gespielt ist und die Spende extern über die Webseite der
  Heilsarmee abgewickelt wird.
- Unnötige Berechtigung „Alle Pakete abfragen“ entfernt.

### Behoben
- Die Kurbel saß je nach Gerät neben der Drehorgel.
- Der Spenden-Link übernahm Betrag und Korps nicht mehr – und der
  Spendenzweck stand standardmäßig auf einem anderen Korps.

### Technisch
- Android-Projekt auf aktuelle Flutter-Vorlage gehoben (minSdk 24 wegen
  FluidSynth, targetSdk aktuell).
- Debug-Builds (`de.heilsarmee.orgel.debug`) lassen sich neben der
  Play-Store-Version installieren.
