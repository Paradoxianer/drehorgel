# Changelog

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
  *Standortrolle* (Amazing Grace, When the Saints Go Marching In, Ode an die
  Freude, Michael, Row the Boat Ashore) – mit mehreren Strophen, einzelne
  Lieder anwählbar.
- **Fallendes Geld:** Pro Umdrehung fällt eine Münze in den Spendentopf.

### Geändert
- Neuer, eigener Drehorgelklang (SoundFont, zwei schwebende Register,
  Tremulant) statt einer einzelnen mp3.
- Realistischere Sammelbeträge: meist Cent-Münzen statt ganzer Euros.
- Spendenformular: Betrag wird vorbelegt und der Spendenzweck fest auf das
  Korps Chemnitz-Kaßberg gesetzt (die Spendenseite nutzt jetzt Twingle).
  Mindestbetrag 5 €.

### Behoben
- Die Kurbel saß je nach Gerät neben der Drehorgel.
- Der Spenden-Link übernahm Betrag und Korps nicht mehr – und der
  Spendenzweck stand standardmäßig auf einem anderen Korps.

### Technisch
- Android-Projekt auf aktuelle Flutter-Vorlage gehoben (minSdk 24 wegen
  FluidSynth, targetSdk aktuell).
- Debug-Builds (`de.heilsarmee.orgel.debug`) lassen sich neben der
  Play-Store-Version installieren.
