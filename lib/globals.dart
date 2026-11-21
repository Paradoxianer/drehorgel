import 'package:flutter/widgets.dart';

/// Alle Positionen der Szene werden in einem festen "Bühnen"-Koordinatensystem
/// angegeben (Größe des Hintergrundbildes, 1920x1080). Die komplette Bühne wird
/// am Stück per FittedBox auf den Bildschirm skaliert – dadurch passen Orgel,
/// Kurbel und Figuren auf jedem Gerät exakt zueinander, ohne dass irgendwo
/// selbst mit Bildschirmgrößen gerechnet werden muss.
///
/// Die Werte sind aus der Designvorlage `data/Drehorgel Illustration.jpg`
/// abgeleitet.
const Size stageSize = Size(1920, 1080);

/// Ein Bild auf der Bühne: obere linke Ecke + Skalierung der Originalgröße.
class StageSprite {
  final String asset;
  final Size imageSize; // Pixelgröße des PNG
  final Offset topLeft; // in Bühnenkoordinaten
  final double scale;

  const StageSprite(this.asset, this.imageSize, this.topLeft, this.scale);

  Rect get rect => topLeft & (imageSize * scale);

  /// Rechnet einen Punkt im Originalbild in Bühnenkoordinaten um.
  Offset toStage(Offset imagePoint) => topLeft + imagePoint * scale;
}

const organ = StageSprite(
    'assets/images/drehorgel.png', Size(450, 639), Offset(98, 350), 1.12);

const maleSalutist = StageSprite(
    'assets/images/male.png', Size(300, 904), Offset(638, 104), 1.05);

const femaleSalutist = StageSprite(
    'assets/images/female.png', Size(255, 956), Offset(1051, 158), 0.94);

const bucket = StageSprite(
    'assets/images/bucket.png', Size(540, 824), Offset(1306, 244), 0.96);

/// Weiße Tafel im Bucket-Bild (Bildpixel), dort wird der Betrag angezeigt.
const Rect bucketBoardInImage = Rect.fromLTWH(140, 55, 265, 200);

/// Kurbelbild: 450x450, die Drehachse (das große runde Ende) liegt genau in der
/// Bildmitte, der Griff zeigt im unrotierten Bild nach unten.
const String crankAsset = 'assets/images/kurbel_margin.png';
const double crankImageSize = 450;

/// Drehachse der Kurbel im Orgelbild (Bildpixel), aus der Designvorlage
/// `data/Drehorgel komplett.png` übernommen.
const Offset crankPivotInOrgan = Offset(320, 39);

/// Hochformat: Mitte des Betragsschilds auf der Orgelfront und der Schlitz
/// (dunkle Öffnung unten), in den die Münzen fallen – beides Orgelbild-Pixel.
const Offset organPlateCenterInOrgan = Offset(225, 300);
const Offset organSlotInOrgan = Offset(225, 395);
