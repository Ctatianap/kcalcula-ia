import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

const outfitLicenseAsset = 'assets/fonts/OFL.txt';

/// SPEC-010 R2: la OFL 1.1 (condición 2) exige que cada copia distribuida
/// de la fuente lleve su aviso de copyright y su licencia. Se registran en
/// el `LicenseRegistry`, que muestra "Licencias de código abierto" (Ajustes).
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Outfit',
    ], await rootBundle.loadString(outfitLicenseAsset));
  });
}
