# VITAL 3.0 – Bygg- och testlogg

Registrera varje byggförsök och test här. Skriv exakt miljö, resultat och eventuella fel. Ett ej utfört test ska aldrig markeras som godkänt.

## 2026-11-15
- Xcode build: Inte utförd i denna arbetsmiljö.
- iOS Simulator: Inte testad.
- Fysisk iPhone: Inte testad.
- HealthKit-auktorisering: Inte testad.
- HealthKit-datainsamling: Inte testad.
- IPA-export/signering: Inte utförd.
- Källkod och projektfiler har lagts till i GitHub-grenen `vital-3.0`.
- Status: Första källkodsgrund incheckad; teknisk verifiering återstår.

## Mall för kommande test
### Datum och version
- Commit:
- Xcode-version:
- iOS-version/enhet:
- Test:
- Förväntat resultat:
- Faktiskt resultat:
- Fel/loggar:
- Åtgärd:
- Status: Ej testad / Godkänd / Underkänd


## 2026-11-15 – Förberedelse för automatiserad build
- Delad Xcode-scheme: Inlagd, ej verifierad med Xcode lokalt.
- GitHub Actions-workflow: Inlagd för macOS 15 och iOS Simulator SDK.
- Buildstatus: Väntar på första workflow-körningen.
- Dashboard-dataetiketter: Förbättrade så saknade värden inte felaktigt anges som hämtade.
- Energidiagram: Illustrativ kurva borttagen; tomt tillstånd visas tills verklig historik finns.
- Ingen build eller test markeras som godkänd innan CI-resultat finns.
