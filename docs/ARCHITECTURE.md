# VITAL 3.0 – Teknisk arkitektur

## Nuvarande struktur

```
VITAL/
  App/
    VITALApp.swift
  Design/
    VITALDesignSystem.swift
  Health/
    HealthKitStore.swift
  Models/
    HealthSnapshot.swift
  Views/
    RootView.swift
    DashboardView.swift
  Info.plist
  VITAL.entitlements
VITAL.xcodeproj/
  project.pbxproj
docs/
  PROJECT_LOG.md
  DECISIONS.md
  ROADMAP.md
  BUILD_AND_TEST_LOG.md
  ARCHITECTURE.md
```

## Ansvar
- `VITALApp`: SwiftUI-appens startpunkt och delning av HealthKitStore.
- `VITALDesignSystem`: färgtoken, spacing och gemensamma kort.
- `HealthKitStore`: begär read-only-behörighet och hämtar hälsodata.
- `HealthSnapshot`: sammanhållen ögonblicksbild av senast hämtade mätvärden.
- `RootView`: fyra huvudflikar.
- `DashboardView`: dagens hälsostatus och översikt.

## HealthKit-data i aktuell implementation
- Sömnanalys och grupperade sömnperioder
- HRV SDNN och vilopuls, både senaste värden och separata nattvärden
- Personliga baslinjer för sömn, HRV och vilopuls
- Steg och aktiv energi
- Kroppsvikt
- Blodtryck som sammanhållen systolisk/diastolisk korrelation
- Andningsfrekvens och syremättnad när datatyper och mätningar finns tillgängliga

Träningspass är inte ännu en fullständig aktivitetsdatakälla. Tillgängliga HealthKit-värden beror på användarens enheter, datakällor och behörigheter.

## Arkitekturprinciper framåt
- Håll datainsamling, beräkningar och presentation separerade.
- Beräkningar ska vara testbara utan HealthKit.
- Håll historiska rapport-snapshots oföränderliga och åtskilda från dashboardens aktuella HealthKit-baserade återhämtningsstatus.
- Håll kroppsbatteriets löpande tillstånd separat från nattlig återhämtning.
- Låt UI visa datakälla, tidsstämpel och datatillgänglighet.
- Ge inte UI ansvar för att hitta på eller uppskatta saknade mätvärden.


## CI och Xcode-projekt
- Delad scheme finns i `VITAL.xcodeproj/xcshareddata/xcschemes/VITAL.xcscheme`.
- GitHub Actions-workflow finns i `.github/workflows/ios-build.yml`.
- Workflow kör på macOS och bygger appmålet mot iOS Simulator med kodsignering avstängd.
- Denna CI-build verifierar kompilering och projektkonfiguration, inte HealthKit-funktionalitet på en fysisk enhet.


## Fristående beräkningskärna
- `VITAL/Models/RecoveryEngine.swift` innehåller den rena återhämtningsfunktionen utan beroende till HealthKit eller SwiftUI.
- `Package.swift` exponerar modellen som Swift Package så att den kan testas separat.
- `Tests/VITALCoreTests/RecoveryEngineTests.swift` innehåller tester för baslinjekrav, saknade värden, normalisering och begränsning av komponentpoäng.
- Modellen är kopplad till HealthSnapshot via nattvärden och personliga baslinjer. CI verifierar kod och tester; verkliga HealthKit-data måste fortfarande verifieras på fysisk iPhone.


## Sömnperiodsberäkning
- `VITAL/Models/SleepSessionCalculator.swift` slår ihop överlappande sömnintervall och grupperar sammanhängande segment.
- `HealthKitStore.latestSleepDuration()` läser sömnsegment från de senaste 36 timmarna och skickar endast sömnklassade intervall till kalkylatorn.
- Första prototypen grupperar segment med högst 90 minuters mellanrum. Tröskeln är konfigurerbar och ska valideras mot verkliga data.


## Personliga baslinjer
- `VITAL/Models/PersonalBaselineCalculator.swift` beräknar median från dagliga värden i ett explicit tidsfönster.
- Flera mätningar samma dag reduceras till en dagsmedian, så tätare samplingsfrekvens inte automatiskt ger större vikt.
- Minst 14 distinkta dagar krävs.
- `HealthKitStore` hämtar nu historiska HRV SDNN- och vilopulssampel för de 30 avslutade kalenderdagarna före idag.
- Sömnsegment hämtas för samma period, slås ihop till sömnperioder och reduceras till den längsta perioden per lokal uppvakningsdag. Tupplurar summeras alltså inte med nattsömnen.
- Resultaten sparas i `HealthSnapshot` som tre separata baslinjeobjekt och används av RecoveryEngine i dashboardens återhämtningskort.
- HealthKit-frågorna kräver verifiering på fysisk iPhone. Om HealthKit inte returnerar data ska baslinjen förbli ej redo.


## Tidsstämplade nattvärden
- `OvernightMetricSelector.swift` är en fristående kärnmodell för att välja HRV- och vilopulsvärden inom en explicit `SleepSession`.
- Modellen returnerar median och antal giltiga sampel per mätvärde.
- Den gör inget antagande om att nattliga sampel måste finnas. Saknade värden förblir nil.
- Modellen används av HealthKitStore för att välja nattvärden inom vald sömnperiod. Faktiska sampeltidsstämplar och vilopulsens lämplighet måste fortfarande verifieras på fysisk iPhone.


## HealthKit – nattlig återhämtning
- HealthKitStore hämtar tidsstämplade HRV SDNN- och vilopulssampel från de senaste 36 timmarna.
- Den senaste grupperade sömnperioden väljs och används som explicit tidsfönster för `OvernightMetricSelector`.
- `HealthSnapshot.hrv` och `restingHeartRate` är senaste tillgängliga värden för översikten. Separata fält, `overnightHRV` och `overnightRestingHeartRate`, används av RecoveryEngine.
- Saknade nattliga sampel lämnas nil. Senaste dagvärdet får inte ersätta nattvärdet.
- Valet av senaste sömnperiod kan fortfarande fånga en tupplur. Det behöver valideras och eventuellt ersättas med urval av huvudperiod.

## Huvudsömn och tupplurar
- `SleepSessionCalculator.primarySession` väljer den längsta grupperade sömnperioden i det aktuella HealthKit-fönstret; vid lika längd väljs den senast avslutade.
- HealthKitStore använder denna period för urval av nattliga HRV- och vilopulsvärden.
- Urvalet är en heuristik. Det identifierar inte säkert nattsömn och måste verifieras mot verkliga data. `latestSession` finns kvar för anrop som uttryckligen behöver den senast avslutade perioden.


## Kroppsbatteri
- `BodyBatteryEngine` är fristående från `RecoveryEngine`.
- Indata: morgonens återhämtningspoäng, personlig vilopulsbaslinje, tidsstämplade pulssampel, tidsstämplade aktiva energisampel samt uppvakningstid och beräkningstid.
- Pulslast integreras endast mellan sampel med högst 15 minuters mellanrum. Minst tre sampel över minst 30 minuter krävs.
- Aktiv energi summeras inom vakenperioden. Saknat underlag ger nil-poäng.
- Nuvarande modell minskar från nattens återhämtningsvärde och modellerar ännu inte återladdning under vila. Resultatet visas som en preliminär uppskattning.


## Kroppsbatteri – HealthKit-flöde
- `HealthKitStore` läser tidsstämplad puls och aktiv energi från ett rullande 36-timmarsfönster.
- Vid uppdatering väljs huvudsömnens sluttid som uppvakningstid och `HealthSnapshot.recoveryResult.score` som startvärde.
- `BodyBatteryEngine` får endast dagens sampel mellan uppvakning och aktuell beräkningstid.
- Resultatet lagras i `HealthSnapshot.bodyBattery` och renderas av dashboardens energikort.
- Om underlaget inte räcker lämnas poängen nil och förklaringen visas i stället.

## Aktiv energi – intervallsemantik
- TimedHealthValue kan bära både start- och sluttidsstämpel.
- För aktiva energisampel måste hela intervallet rymmas inom vakenperioden (start >= wakeTime och end <= asOf).
- Ögonblicksvärden utan starttid använder sin tidsstämpel som intervallstart.
- Sampel som överlappar sömn eller ligger efter beräkningstidpunkten utesluts helt; ingen proportionell fördelning görs.


## Morgonrapport – utlösningspolicy
- `MorningReportTriggerPolicy` är en ren kärnmodell som bedömer om en händelse får skapa morgonsnapshot.
- Källor: avslutat Sömnfokus, uppdaterad sömndata från HealthKit eller att appen blir aktiv.
- Fokusstatus är en signal; beslutet baseras på HealthKit-huvudsömnens slut och lokala rapportdag.
- Initiala skydd: minst tre timmars sömn, avslutad sömnperiod, max 18 timmar från uppvaknande och samma lokala kalenderdag.
- Arkivet `ReportSnapshotArchive` förhindrar fortfarande fler än en morgonrapport per lokal dag.
- `HealthKitStore` startar en `HKObserverQuery` för `sleepAnalysis` efter HealthKit-auktorisering och begär `.immediate` Background Delivery.\n- Observerarens callback gör en ny HealthKit-refresh och anropar completion-handlern.\n- Entitlement `com.apple.developer.healthkit.background-delivery` finns i `VITAL.entitlements`.\n- Detta observerar ändringar i HealthKit, inte Sleep Focus-status. Bakgrundsleverans måste verifieras på fysisk enhet och kräver korrekt provisionerad entitlement.


## Morgonrapport – dataväntan
Morgonrapportens triggerpolicy kräver att huvudsömnen är avslutad och att minst 20 minuter har passerat från sömnperiodens sluttid. HealthKit-uppdateringar och appens återgång till aktivt läge kan kontrollera policyn igen. Väntetiden garanterar inte att alla sampel har levererats; saknade värden förblir nil när snapshoten till slut låses. Rapportarkivet gör därefter snapshoten oföränderlig per lokal dag och rapporttyp.


## HealthKit-bakgrundsleverans
HealthKitStore registrerar en observerfråga för sömn och begär bakgrundsleverans. Resultatet från enableBackgroundDelivery sparas i backgroundSleepDeliveryEnabled. Fel och nekad aktivering förs vidare till lastError i stället för att tyst ignoreras. Statusen bevisar inte att framtida observerhändelser levereras i tid; fysisk enhet och korrekt entitlement/provisionering krävs för verifiering.


## Notisbehörighet och synlig status
VITAL läser först UNUserNotificationCenter notificationSettings. Systemdialogen begärs endast om behörigheten ännu inte har valts. Vid nekad behörighet tas väntande kvällspåminnelse bort. Dashboarden visar notisstatus separat från HealthKit-bakgrundsleverans; de två funktionerna har olika behörigheter och felorsaker.

## Stabil rapportdag över tidszoner
Varje ny DailyReportSnapshot lagrar en lokal dagnyckel (`yyyy-MM-dd`) och tidszonsidentifieraren som gällde när rapporten skapades. Arkivets dubblettskydd använder dagnyckeln i stället för att räkna om äldre datum med enhetens nuvarande tidszon. Dashboarden visar datumetiketten från den sparade nyckeln. Äldre arkiv utan dessa fält kan fortfarande avkodas och använder den tidigare datumjämförelsen.


## Andning och syremättnad – HealthKit
- HealthKitStore begär läsbehörighet för andningsfrekvens (`respiratoryRate`) och syremättnad (`oxygenSaturation`).
- Senaste tillgängliga värde hämtas separat från nattens återhämtningsmått.
- Andningsfrekvens visas i andetag/minut.
- HealthKit lagrar syremättnad som en andel; presentationen omvandlar exempelvis 0,975 till 98 %.
- Saknade, icke-finita eller orimliga värden visas som saknade.
- Tillgången till dessa mätvärden beror på kompatibel enhet och datakällor i Apple Hälsa; appen hittar inte på reservvärden.


## Valfria HealthKit-mätvärden
Andningsfrekvens och syremättnad läggs till i läsbehörighetsmängden endast om respektive HealthKit-typ finns tillgänglig. Om en av dessa valfria typer saknas får det inte stoppa auktorisering eller hämtning av kärndata som sömn, puls och aktivitet. Ett saknat sampel är fortfarande ett saknat värde; HealthKit ger inte appen en säker generell signal för att skilja nekad läsbehörighet från att ingen data finns.


## Vikt och blodtryck från HealthKit
- Senaste kroppsmassa hämtas som HealthKit quantity sample med värde i kg och sampelns sluttid.
- Blodtryck hämtas som en sammanhängande HealthKit bloodPressure-korrelation. Systoliskt och diastoliskt värde måste finnas i samma korrelation.
- Båda blodtrycksvärdena konverteras till mmHg och visas endast när paret är komplett och rimligt.
- UI prioriterar HealthKit-data. Äldre lokala journalposter behålls som historik och exponeras inte längre som nya registreringsflöden.
- Tillgänglighet och korrekt dataläsning måste verifieras med enhet som har HealthKit-data.


## Aktuell implementation – kodgranskad 2026-11-17 (CI pågår)

- `HealthSnapshot.recoveryResult` kopplar nu ihop de personliga baslinjerna, nattliga HealthKit-värdena och `RecoveryEngine`.
- RecoveryEngine kräver minst 14 giltiga dagar för var och en av de tre baslinjerna. Baslinjerna beräknas från de 30 avslutade kalenderdagarna före aktuell dag.
- Återhämtningspoängen är en produktmässig wellness-uppskattning: sömn 40 %, HRV 35 % och vilopuls 25 %. Komponenterna begränsas till 0–100. Vilopulskomponenten minskar med 5 poäng per bpm över den personliga medianen. Dessa vikter och omräkningar är heuristiker, inte kliniskt validerade gränser.
- Dashboardens huvudkort använder `health.snapshot.recoveryResult` direkt: aktuell HealthKit-snapshot, nattvärden och personliga baslinjer. Det är alltså inte den frysta historiska morgonrapporten som styr kortet. Senare HealthKit-refresh kan uppdatera dashboardens aktuella värden.
- Vägledningspolicyn flaggar komponenter under 85. Gränsen är en produktheuristik. Saknas en av de tre komponenterna visas neutralt vänteläge och inga signaler fabriceras.
- Kvällsrapporten är avvecklad som användarflöde: ingen ny kvällssnapshot, schemaläggning eller visningskod. Datamodellen och arkivet kan fortfarande avkoda och bevara äldre kvällsposter för bakåtkompatibilitet.
- Tidigare CI-run 43980719580 på commit `cc243c9` verifierade kärntester, simulatorbuild, simulatorstart, osignerat iOS-enhetsarkiv, appikon och IPA-paketering. Nyare run 44037409691 på commit `0a06959` har vid denna dokumentationsuppdatering passerat kärntester, simulatorbuild, arkivering, ikonkontroll och IPA-uppladdning; simulatorns slutliga processkontroll pågår. CI verifierar inte HealthKit-data eller installation på fysisk iPhone.


## Hälsa-fliken – aktuell datakälla och historik
- Aktuell vikt och blodtryck hämtas automatiskt från Apple Hälsa när tillgängligt.
- Nya manuella mätformulär för vikt och blodtryck är borttagna. Äldre lokala journalposter visas endast som historik.
- Målvikt är en separat frivillig användarinställning och ska inte blandas ihop med manuell viktmätning.
- Läkemedelsdos, biverkningar, vätska och framstegsbilder är separata journal-/verktygsfunktioner, inte HealthKit-mätvärden.
