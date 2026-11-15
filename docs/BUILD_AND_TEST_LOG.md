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


## 2026-11-15 – RecoveryEngine unit tests
- Kommando: `swift test`
- Miljö: Swift 6.2.1, Linux x86_64.
- Resultat: 5 tester passerade, 0 fel.
- Testfall: otillräcklig baslinje, värden lika med personlig baslinje, saknat mätvärde, försämrade komponenter och begränsning till 0–100.
- En initial testmiss avslöjade felaktig HRV-normalisering; den korrigerades innan den godkända omkörningen.
- Begränsning: detta test omfattar endast Swift Package-kärnan, inte iOS-appen eller HealthKit.


## 2026-11-15 – SleepSessionCalculator unit tests
- Kommando: `swift test`
- Miljö: Swift 6.2.1, Linux x86_64.
- Resultat: totalt 10 tester passerade, 0 fel (5 RecoveryEngine + 5 SleepSessionCalculator).
- Testfall sömn: överlappande stadier dubbelräknas inte, intilliggande stadier grupperas, senaste session väljs efter lång vakenperiod, ogiltiga intervall ignoreras och tom lista ger nil.
- Begränsning: fristående kärnlogik testad; HealthKit-frågan och iOS-appen är inte testade på enheten.


## 2026-11-15 – PersonalBaselineCalculator
- Fem nya enhetstester har lagts till: minimikrav 14 dagar, median, flera värden per dag, ogiltiga/utanför fönster och ogiltigt tidsfönster.
- Testerna är incheckade men har ännu inte körts i CI efter senaste commit.
- Tidigare verifierad kärna: 10 tester passerade. Totalt antal definierade tester är nu 15.
- Väntar på GitHub Actions-resultat för aktuell gren.
