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


## 2026-11-15 – Kvällsrapportens kärnmodell och Xcode-registrering
- GitHub Actions run 149, commit `9eda93dbca2917bec0ced2d157a9056c362fb18a`: kärntester godkända efter att EveningReportTriggerPolicy registrerats i Swift Package.
- GitHub Actions run 150, commit `1cf42062cea11e066623ea7181dfebfa28c053b9`: kärntester och iOS Simulator-build godkända efter Xcode-projektregistrering.
- GitHub Actions run 151, commit `cc672e9bc26366aaacd618728682cceffc7a50d7`: kärntester och iOS Simulator-build godkända för HealthKitStore-kopplingen av kvällssnapshot.
- Körningar för daglig notis, scenePhase-refresh och senaste rapportkortet väntar fortfarande.
- Ingen fysisk iPhone-testning eller IPA-export har utförts.


## 2026-11-15 – Morgonrapportens dataväntan
- Ändrat triggerpolicyn till minst 20 minuters väntetid efter huvudsömnens sluttid.
- Lagt till test för att rapport inte får skapas efter 19 minuter och 59 sekunder, men får skapas vid 20 minuter.
- Källkod och test är incheckade; CI-resultat för dessa commits inväntas.
- Ingen fysisk iPhone-testning eller HealthKit-synkroniseringsmätning är utförd.


## 2026-11-15 – CI för morgonrapportens väntetid
- GitHub Actions run 163, commit `16b4c8f6ee36c77d07b2d665c8fdfd49a27eb262`: kärntesterna föll eftersom den äldre testfixturen fortfarande förväntade omedelbar rapport vid 15 minuter efter uppvaknande. Detta var ett förväntat testkontraktsfel efter införandet av 20-minutersgränsen.
- Uppdaterade testfixturen och lade till separat gränstest för 19 minuter och 20 minuter.
- GitHub Actions run 164, commit `0faa3689e68f3b9d1fc9da9a472039be1b70871d`: kärntester godkända och hela workflow-körningen slutförd med godkänt resultat.
- Senare dokumentations- och HealthKit-felhanteringsändringar har egna CI-körningar i kö/pågående; de är ännu inte verifierade.

## 2026-11-15 – Tidszonsstabil rapporthistorik
- Utökade DailyReportSnapshot med lokal dagnyckel och tidszonsidentifierare; äldre Codable-arkiv avkodas med reservvärden.
- Arkivets dubblettskydd och dashboardens historikdatum använder sparad lokal dag.
- Lade till två tester för tidszonsbyte och sommartidsdag.
- Källkod och tester är incheckade. CI-resultat för de nya testerna och simulatorbygget inväntas; ingen fysisk enhetstestning är utförd.

## 2026-11-15 – CI för tidszonsstabil rapporthistorik
- GitHub Actions run 191, commit `de89a1a2f935df89f4c77fb0dc500996d32673c0`: kärntester godkända och iOS Simulator target byggd utan fel.
- Tidigare körningar 182–190 avsåg mellanliggande commits och misslyckades bland annat på ett felaktigt metodargument i dagnyckelns konstruktion. Felet är korrigerat i run 191.
- Detta verifierar kompilering och tester i CI, inte HealthKit-beteende, notisleverans eller installation på fysisk iPhone.


## 2026-11-15 – Första iOS-enhetsarkivet
- GitHub Actions run 195, commit `7406408bd8fdde701423cd87081bf80dba205f1e`: kärntester, iOS Simulator-build och `archive` för `generic/platform=iOS` godkända.
- CI-artifakt `VITAL-unsigned-device-archive` skapades och laddades upp. Arkivets innehåll inspekterades: `Products/Applications/VITAL.app/VITAL`, Info.plist och dSYM finns med.
- Arkivet är osignerat (`CODE_SIGNING_ALLOWED=NO`) och är endast en byggverifiering. Det är inte en signerad IPA och kan inte installeras på iPhone.
- Signering, provisioning, IPA-export och fysisk enhetstestning återstår.


## 2026-11-15 – Osignerad sideload-IPA verifierad
- GitHub Actions run 201, commit `4e37de29ef7566c99ec8ceda9f41493e7f2c5c0e`: kärntester, simulatorbygge, iOS-enhetsarkiv, IPA-paketering och uppladdning godkända.
- CI-artifakt `VITAL-unsigned-IPA` hämtades och öppnades. IPA:n innehåller `Payload/VITAL.app` med arm64 Mach-O-binär och Info.plist.
- Verifierade metadata: bundle ID `se.vital.health`, visningsnamn VITAL, version 3.0 (build 1), minsta iOS 17.0, iPhone/iPad.
- IPA:n är osignerad och saknar provisioning profile; den måste signeras via sideload-verktyget före installation. Ingen fysisk enhetsinstallation är ännu verifierad.


## 2026-11-16 – Simulator-smoketest och CI-felsökning
- Commit `4120ffc63ae70d960e1b7ae0e014d536edea5313`: smoke-testet ändrades från sökning i `launchctl list` till PID-kontroll baserad på resultatet från `simctl launch`.
- Run 43889360011, attempt 2: fortfarande köad vid kontrollen den 2026-11-16. Ingen slutsats om simulatorstart eller build kan dras från en köad körning.
- Korrigering vid eftergranskning: shell-formatsträngen för radbrytning i PID-parsningen hade dubblerad backslash. Detta korrigeras i en separat workflow-commit; den nya körningen måste verifiera att PID läses och att processen överlever kontrollintervallet.
- Tidigare run 43874399827 föll på den gamla processidentifieringskontrollen. Loggen visade att `simctl launch` hade startat VITAL och returnerat PID 3393; felet var kontrollmetoden, inte bevis på appkrasch.
- Fysisk iPhone: appen har tidigare rapporterats krascha direkt vid start efter FlareStore-signering. Ingen diagnostisk crashrapport har ännu kunnat granskas. Simulatorstart kan inte ersätta fysisk enhetsverifiering.
- Status: Nytt simulator-smoketest väntar på CI. Ingen ny IPA ska lämnas ut som verifierad förrän byggstegen och simulatorstarten har passerat.


## 2026-11-16 – Statisk uppstartsgranskning
- Granskade `VITALApp`, `RootView`, `Info.plist`, `VITAL.entitlements` och huvuddelen av `HealthKitStore`.
- Bekräftat i källkoden: HealthKitStore initieras vid appstart, HealthKit-auktorisering begärs senare från dashboardens uppgift, och HealthKit usage description finns i Info.plist.
- Inga uppenbara force unwraps eller direkta fatalError-anrop hittades i den granskade uppstartsvägen.
- Detta är en statisk kodgranskning, inte ett körtest. Den fastställer inte orsaken till kraschen på fysisk iPhone.
- Nästa diagnostiska underlag: resultat från PID-baserat simulator-smoketest samt vid behov crashrapport eller signerad IPA med dess entitlements.


## 2026-11-16 – Dokumentationscommit och ny CI-trigger
- Den samlade dokumentationsuppdateringen för statisk uppstartsgranskning lades in på grenen `vital-3.0`.
- Grenpekaren uppdaterades via Git Data API, vilket inte startade GitHub Actions som en vanlig push-händelse.
- En efterföljande dokumentationspush används därför för att trigga workflow på den aktuella grenkoden.
- Status för byggning och simulatorstart ska hämtas från den nya körningen; äldre körning 43921250780 avslutades som avbruten och verifierar inte den senaste dokumentationen.


## 2026-11-16 – Bekräftad krasch i HealthKit-auktorisering
- Run 43922206353: core unit tests godkända; iOS Simulator build godkänd; appen startade men avslutades under HealthKit-auktorisering.
- Simulatorloggen visar `NSInvalidArgumentException`: `Authorization to read the following types is disallowed: HKCorrelationTypeIdentifierBloodPressure`.
- Rotorsak identifierad: `HKCorrelationType` för blodtryck lades till i `readTypes` i `requestAuthorization`.
- Åtgärd i commit `88bcdd9e6638ecb3979e10619f152254d128d50a`: endast systoliskt och diastoliskt `HKQuantityType` begärs i read-authorization. Den befintliga korrelationsfrågan för att läsa ihop parade värden är kvar.
- Ny simulator- och CI-verifiering återstår. Inga IPA-steg kördes i den misslyckade körningen eftersom smoke-testet stoppade workflow.
- Notering: loggen innehåller även HealthKit-meddelanden om saknat HealthKit-entitlement i simulatorn. Dessa ska utvärderas separat efter att auktoriseringsundantaget är borta; de var inte den utlösande NSInvalidArgumentException som avslutade processen.


## 2026-11-16 – Återhämtningsfokuserad dashboard, första iteration
- Kodändring: dashboarden har fått huvudkortet Dagens återhämtning, kompakt nattlig sömn/HRV-rad och dagsråd; rapportsektionen och stressplatshållaren har tagits bort från startsidan.
- Relevanta kodcommits: `b12e4691c0c71200defd24b4305dd3d853af9f8f` och `630c2f82653f4b3c813c861dcc906be68b38e304`.
- En CI-körning för mellanliggande kodcommit avbröts på grund av efterföljande commit/concurrency. Den nya dokumentationscommiten används för att starta verifiering mot aktuell gren.
- Simulatorbuild och enhetstester för den nya dashboarden: inväntar aktuell CI.
- Visuell granskning i simulator och fysisk iPhone: ej utförd.
- Status: Implementerat i källkod, ännu inte verifierat.


## 2026-11-17 – Fryst sammanfattning och borttagning av kvällsflöde
- Ändrade filer: HealthSnapshot.swift, RecoveryEngine.swift, HealthKitStore.swift och DashboardView.swift.
- Tillagt: frysta komponentpoäng i morgonsnapshoten och signalbaserad vägledningspolicy.
- Borttaget: notisbehörighet enbart för kvällsrapporten, schemaläggning av kvällsrapportnotis och skapande av nya kvällssnapshots.
- Äldre rapportarkiv bevaras; inga lokala historikposter raderas.
- Fyra enhetstester tillagda för en avvikande signal, flera signaler, saknade data och neutralt läge.
- Status före körning: ej verifierat. Resultat ska fyllas i efter CI.


## 2026-11-17 – Full CI-kedja godkänd

- GitHub Actions run [43980719580](https://github.com/72cbbw422f-alt/vit/actions/runs/43980719580), commit `cc243c927606c5ab960a0d0b3b27718f1788f006`: **success**.
- Godkända steg: `swift test`, iOS Simulator-build, PID-baserat simulator-smoketest, osignerat iOS-enhetsarkiv, kontroll av inbäddad appikon, IPA-paketering och uppladdning av båda artefakterna.
- Artefakt `VITAL-unsigned-IPA`: 1 342 956 byte. Artefakt `VITAL-unsigned-device-archive`: 2 740 207 byte. Båda har sju dagars retention och måste hämtas via Actions innan de löper ut.
- IPA:n är avsiktligt osignerad. Den måste signeras med FlareStore eller annat kompatibelt verktyg innan installation. CI-resultatet bevisar inte att den tidigare fysiska iPhone-kraschen är löst.
- Varningar i arkivsteget: iOS-orienteringskonfiguration och äldre headermap-inställning. De stoppade inte bygget men ska städas separat.
- HealthKit-entitlement och faktisk HealthKit-auktorisering/dataåtkomst måste fortfarande verifieras på fysisk enhet.

## 2026-11-17 – Avveckling av kvarvarande kvällsrapportkod

- Efter den godkända CI-körningen togs den oanvända `eveningReport`-publiceringen och tilldelningen bort från HealthKitStore.
- Oanvända vyer för morgon-/kvällsrapport och rapportsektionen togs bort från DashboardView. Det aktiva huvudkortet Dagens återhämtning är den enda morgonsammanfattningen i dashboarden.
- Arkivmodellens `DailyReportKind.evening` och äldre poster behålls för att gamla lokala arkiv fortsatt ska kunna avkodas.
- Denna städning kräver en ny CI-körning; den tidigare godkända körningen gäller commit `cc243c9`, inte den nya städningscommiten.


## 2026-11-20 – Korrigering av testkontrakt för sömneffektivitet

- Granskad gren: `vital-3.0`.
- Föregående verifiering: Actions run 499 (`4fb4d2e`) misslyckades i `swift test`; samma fel som run 498.
- Rotorsak: testet `testRejectsInvalidOrShorterThanSleepBedInterval` använde ett in-bed-intervall som exakt täckte sömnperioden och förväntade ändå `nil`. Beräknaren returnerade matematiskt korrekt 100 %.
- Ändrad fil: `Tests/VITALCoreTests/SleepQualityCalculatorTests.swift`. Testet heter nu `testAcceptsInBedIntervalExactlyMatchingSleepDuration` och verifierar 7 timmars sömn, 7 timmars in-bed och 100 % effektivitet.
- Ändrad fil: `docs/DECISIONS.md`. Kontraktet är dokumenterat: ett in-bed-intervall som täcker hela sömnperioden är giltigt även vid exakt lika start-/sluttider; ofullständig täckning ger fortsatt nil.
- Kodfilen `VITAL/Models/SleepQualityCalculator.swift` är inte ändrad.
- Testkörning efter ändringen: inväntar GitHub Actions.
- Actions run 500 och 501 startades av de två efterföljande commitsen; run 501 pekar på senaste commit `5559b66`. Status vid dokumentationstillfället: queued.
- Simulatorbygge, device archive, IPA-paketering och simulator-smoketest är ännu inte verifierade för den nya koden.
- Berörda commits: `89d58e9` (test) och `5559b66` (beslutslogg).
- Nästa steg: invänta senaste workflow-resultatet och granska loggen. Om testerna passerar ska hela återstående byggkedjan verifieras; om de fallerar ska det faktiska felet analyseras innan fler kodändringar görs.


## 2026-11-20 – Full CI 502 godkänd och artefakter verifierade

- Gren: `vital-3.0`; commit: `48e23c20a1f1e396405f62c550f12838965b41a0`.
- GitHub Actions run [502](https://github.com/72cbbw422f-alt/vit/actions/runs/44737348376): **success**, job `build` slutförd 2026-11-20 12:54 UTC.
- `swift test`: **113 tester, 0 fel, 0 oväntade fel**. Alla testsviter passerade.
- iOS Simulator target: **build godkänd**.
- Osignerat iOS device archive: **archive godkänd**.
- IPA-paketering och uppladdning: **godkända**.
- Simulator-smoketest: VITAL installerades och startades; processen förblev igång (PID 7225) efter kontrollintervallet.
- Artefakter: `VITAL-unsigned-IPA` (1 857 907 byte; artifact ID `14628989476`) och `VITAL-unsigned-device-archive` (3 766 075 byte; artifact ID `14629144199`). Båda har sju dagars retention, till 2026-11-27 cirka 12:51 UTC.
- IPA-arkivet laddades ned och inspekterades lokalt. Innehåller `Payload/VITAL.app`, arm64 Mach-O-binär (1 498 144 byte), Info.plist och Assets.car. Metadata: bundle ID `se.vital.health`, version 3.0, build 1, minsta iOS 17.0, iPhone/iPad.
- Signering verifierad som **saknad**: ingen `_CodeSignature` och ingen `embedded.mobileprovision`. Detta är avsiktligt; IPA:n är inte installationsklar förrän FlareStore har signerat den.
- Källans `VITAL/VITAL.entitlements` deklarerar HealthKit och background delivery, och projektets Debug/Release-konfiguration pekar på entitlement-filen. Eftersom arkivet byggdes med `CODE_SIGNING_ALLOWED=NO` är aktiverade signerade entitlements inte verifierade i paketet. FlareStore-signeringen måste bevara/inkludera HealthKit-entitlements innan HealthKit-test på enhet.
- Kvarvarande icke-blockerande Xcode-varningar: HealthKitStore använder en äldre synkron funktion med async-alternativ; orienteringskonfigurationen saknar stöd för alla interface orientations; traditionell headermap-konfiguration är föråldrad; AppIntents-metadata hoppas över eftersom ramverket inte används.
- Ingen fysisk iPhone-installation, HealthKit-auktorisering/dataåtkomst, notisleverans eller Apple Watch-testning är utförd i denna körning.
- Slutsats: CI, 113 tester, simulatorbygge, osignerat device archive, osignerad IPA och simulatorstart är verifierade för commit `48e23c2`. Fysisk enhetsfunktionalitet är fortsatt ej verifierad.
