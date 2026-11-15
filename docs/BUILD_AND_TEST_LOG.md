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


## 2026-11-15 – HealthKit-historik
- Källkod uppdaterad för att hämta 30 avslutade kalenderdagar av HRV SDNN, vilopuls och sömn.
- Baslinjer räknas via PersonalBaselineCalculator och kräver minst 14 giltiga dagar.
- Ingen Xcode-build eller HealthKit-enhetstest har körts efter ändringen.
- Status: Implementerat i källkod, ännu ej byggverifierat eller enhetstestat.


## 2026-11-15 – Dashboardintegration av återhämtning
- HealthSnapshot kopplar nu tre baslinjer till RecoveryEngine. Den svagaste baslinjen styr om beräkningen får köras.
- Dashboarden visar prototypens poäng och komponenter när data räcker, annars saknat underlag och antal baslinjedagar.
- Kroppsbatteriet är fortsatt separat och visar ingen påhittad nivå.
- Xcode-build, Swift-test och fysisk enhetstestning har inte körts efter denna ändring.
- Status: Källkod incheckad; build- och enhetsverifiering återstår.


## 2026-11-15 – Tidsstämplad natturvalsmodell
- Fyra enhetstester har lagts till för urval inom sömnperiod, saknade nattvärden, ogiltiga värden och exakta periodgränser.
- Modellen har registrerats i Swift Package och Xcode-projektets källfas.
- Testerna har ännu inte körts.
- Xcode-build och HealthKit-enhetstest har inte körts.
- Status: Implementerat i källkod; verifiering återstår.


## 2026-11-15 – HealthKit nattintegration
- HealthKitStore uppdaterad för att hämta HRV SDNN och vilopuls med tidsstämplar inom 36 timmar.
- Återhämtningsmotorn använder separata nattvärden i HealthSnapshot; senaste tillgängliga värden används endast i översiktsmätningarna.
- Fyra natturvalstester finns. Test-fixtures har korrigerats för datum över midnatt.
- Testerna har ännu inte körts efter ändringen.
- Ingen Xcode-build, simulator- eller iPhone-testning har utförts.
- Status: Integrerad i källkod; teknisk verifiering återstår.

## 2026-11-15 – CI-status efter nattintegration
- GitHub Actions run 72, commit `0226746e416419f421f5e220d0adfe53293d8304`.
- `Run core unit tests`: Godkänd.
- `Build iOS Simulator target`: Underkänd.
- Ingen IPA skapad. Simulatorbygget är inte godkänt; felorsaken är ännu inte fastställd från tillgängliga loggar.

## 2026-11-15 – Verifierad HealthKit- och dashboardintegration
- GitHub Actions run 100, commit `e3517a6af7d14375314b976ef710bf64b30241ce`: `Run core unit tests` och `Build iOS Simulator target` godkända.
- Runs 97–100 rapporterade också godkända för sina respektive commits.
- Detta verifierar källkodsläget före korrigeringen av aktiva energisampels intervallgränser.
- Korrigeringen och dess nya regressionstest är incheckade; CI för dessa commits är ännu pågående.
- Ingen fysisk iPhone-testning, HealthKit-auktorisering eller IPA-export är utförd.

## 2026-11-15 – CI-fel och korrigering av sample-initiering
- GitHub Actions runs 102–109 föll i `Run core unit tests` eftersom den syntetiserade Swift-initieraren inte exponerade `startTimestamp` som förväntat när egenskapen hade standardvärde.
- Felet var i test-/modellens initieringsgränssnitt, inte i iOS Simulator-bygget (det steget hoppades över efter testfelet).
- `TimedHealthValue` har nu en explicit initierare med valfri `startTimestamp` och standardvärdet nil.
- Korrigeringen är incheckad i commit `dc752f30f416249a2ed12ed0787e1b62c0a885f7`; ny CI-körning inväntas.

## 2026-11-15 – Aktiv energi-intervall: CI godkänd
- GitHub Actions run 110, commit `dc752f30f416249a2ed12ed0787e1b62c0a885f7`: `Run core unit tests` godkänd och `Build iOS Simulator target` godkänd.
- GitHub Actions run 111, dokumentationscommit `b22ccb533636cfe591d7967cb7a2f084a7bd286c`: båda stegen godkända.
- Regressionstestet för aktiv energi verifierar att endast ett sampel helt inom vakenperioden räknas; överlappande och framtida sampel utesluts.
- Ingen fysisk iPhone-testning, HealthKit-auktorisering eller IPA-export är utförd.


## 2026-11-15 – HealthKit-triggerad morgonrapport: första CI-verifiering
- GitHub Actions run 137, commit `c03f16a46b22b15158f3596b74e32464c4551988`: kärntester och iOS Simulator-build godkända.
- Denna körning verifierar arkivkopplingen i HealthKitStore före den senaste dashboardvyn.
- Därefter har dashboarden fått en vy för fryst morgonrapport; CI för den och efterföljande dokumentationsändringar inväntas.
- Ingen fysisk iPhone-testning eller IPA-export har utförts.


## 2026-11-15 – Dashboardrapport och historik
- GitHub Actions run 142, commit `4cfcde466347648c8b0b9bfb8e1def62963dd4cd`: kärntester och iOS Simulator-build godkända efter korrigering av en bokstavlig escaped newline i DashboardView.swift.
- GitHub Actions run 143, commit `7f082516a50247c4f569f41b4af0d57e1fe2d2be`: kärntester godkända; hela körningen slutfördes senare med godkänt resultat.
- Rapporthistorikens senaste ändringar, inklusive Array-materialisering, väntar på efterföljande CI.

## 2026-11-15 – Kvällsrapport
- EveningReportTriggerPolicy och sex tester har lagts till.
- HealthKitStore, UserNotifications och DashboardView har uppdaterats för första kvällsrapportflödet.
- CI för dessa ändringar väntar; inga tester eller simulatorbyggen markeras som godkända ännu.
- Ingen fysisk iPhone-testning eller IPA-export har utförts.
