# VITAL 3.0 – Projektlogg

Det här dokumentet är den kronologiska huvudloggen för utvecklingen. Lägg till en ny post varje gång en funktion, designändring, teknisk lösning eller test genomförs. Ändra inte äldre poster i efterhand; lägg till rättelser som nya poster.

## 2026-11-15 – Projektstart och grundstruktur

### Beslut
- VITAL 3.0 byggs som en native iOS-app med SwiftUI.
- Apple Health/HealthKit är primär källa för hälsodata.
- Gränssnittsspråket är svenska.
- Ingen kost- eller näringsregistrering ska ingå.
- Arbetet sker initialt på Git-grenen `vital-3.0`; `main` lämnas orörd under grundutvecklingen.

### Designreferens
Användarens tre uppladdade skärmbilder i konversationen är den visuella huvudreferensen. De visar en mörk marinblå instrumentpanel, diskreta kort, tydlig informationshierarki, fyra navigationsflikar och färgkodade hälsomått.

Fastställda färger:
- Midnight Navy – grund/bakgrund: `#111C2D`
- Vital Teal – primär accent: `#70D9D1`
- Soft Violet – sömn och vila: `#A9A0F5`
- Warm Amber – belastning och varning: `#E9BD70`
- Cloud White – text och kontrast: `#F1F4F8`

### Produktprinciper
- Separera nattlig återhämtning från dynamiskt kroppsbatteri/energinivå.
- Morgonrapporten ska vara en fryst ögonblicksbild av tillgängliga data vid rapporttillfället. Den får inte skrivas om med senare mätvärden under dagen.
- Skilj tydligt mellan uppmätta värden, beräknade uppskattningar och data som saknas.
- Hitta aldrig på hälsovärden. Visa saknade värden som saknade.
- VITAL ska vara en hälso- och återhämtningsapp, inte en kostapp.

### Implementerat i första kodsteget
- Skapat SwiftUI-appens startpunkt.
- Skapat färg- och kortsystem.
- Skapat fyra flikar: Idag, Insikter, Aktivitet och Hälsa.
- Skapat första dashboard-vyn med status, sömn, HRV, vilopuls, stressplatshållare, energikurva, rörelse och vanor.
- Skapat första read-only HealthKit-lagret för sömnanalys, vilopuls, HRV (SDNN), steg, aktiv energi och kroppsvikt.
- Lagt till Info.plist-texter och HealthKit-entitlement.
- Skapat ett första Xcode-projekt.

### Begränsningar och kvarstående arbete
- Projektet har ännu inte byggts i Xcode eller körts på fysisk iPhone.
- Signering, team, bundle-ID och faktisk HealthKit-behörighetsdialog måste verifieras i Xcode.
- Dashboardens återhämtningspoäng och energinivå är ännu inte beräknade; de visas avsiktligt som saknade/under uppbyggnad.
- Stressvärde saknar ännu datakälla och beräkningsmodell.
- Graflinjen är för närvarande en visuell platshållare, inte verkliga tidsseriedata.
- Automatiska rapporter, notiser, Apple Watch-stöd, AI-insikter, historik och återhämtningsmotor är ännu inte implementerade.

### Git-status vid loggtillfället
- Repository: `72cbbw422f-alt/vit`
- Arbetsgren: `vital-3.0`
- Basgren: `main`
- Arbetsgrenen låg 13 commits före `main` vid kontrollen.
- Filer ändrade/tillagda i jämförelsen: README samt nio nya filer.

### Nästa steg
1. Granska och verifiera Xcode-projektets filstruktur och build-inställningar.
2. Bygg och kör appen i Xcode/simulator.
3. Korrigera alla compiler- och runtime-fel.
4. Förfina dashboarden mot användarens skärmbilder.
5. Implementera datamodell och beräkningsspecifikation för återhämtning och kroppsbatteri.


## 2026-11-15 – Byggbarhetsarbete och datatydlighet

### Genomfört
- Lagt till en delad Xcode-scheme för appmålet VITAL.
- Lagt till GitHub Actions-workflow på macOS för att lista scheme och bygga iOS Simulator utan kodsignering.
- Förtydligat dashboardens saknade datastatus för sömn, HRV och vilopuls.
- Tagit bort den illustrativa energikurvan så att appen inte visar en påhittad tidsserie som om den vore användarens data.
- Ersatt kurvan med ett tomt diagramläge som förklarar att historik krävs.
- Ersatt nollställd återhämtningsprogress med en neutral tom statusindikator.

### Kvar att verifiera
- GitHub Actions-builden måste köras och resultatet granskas.
- Ingen simulator- eller enhetstestning har ännu utförts.
- Xcode-projektets struktur är uppsatt men får inte betraktas som verifierad förrän CI-builden passerat.


## 2026-11-15 – Första återhämtningsmotorn och enhetstester

### Implementerat
- Skapat `RecoveryEngine.swift` som fristående, deterministisk beräkningsmodell.
- Modellen använder sömn, HRV SDNN och vilopuls mot personlig 30-dagarsreferens.
- Prototypen kräver minst 14 giltiga baslinjedagar och returnerar ingen poäng vid saknade värden.
- Skapat Swift Package för att testa beräkningslogik separat från HealthKit och SwiftUI.
- Lagt till fem enhetstester och dokumenterat modellens formler och begränsningar.

### Testresultat
- Körning med Swift 6.2.1 på Linux x86_64.
- Fem tester körda, noll fel efter korrigering av HRV-normaliseringen.
- Första testkörningen upptäckte att HRV-baslinjen gav 50 i stället för 100 poäng. Formeln korrigerades och samtliga fem tester passerade.
- Detta verifierar endast fristående beräkningskod, inte iOS/Xcode-bygget eller HealthKit-datainsamlingen.

### Kvar
- 30-dagarsbaslinjer hämtas ännu inte från HealthKit.
- Återhämtningsmotorn är ännu inte kopplad till dashboarden.
- Prototypens vikter och skalningar är inte medicinskt validerade.


## 2026-11-15 – Sömnperioder och dubbelräkning

### Implementerat
- Skapat `SleepSessionCalculator.swift` som slår ihop överlappande sömnintervall och därmed undviker att sömnstadier från flera källor summeras dubbelt.
- Sömnsegment som ligger intill varandra eller har högst 90 minuters mellanrum grupperas i samma sömnperiod.
- HealthKit-läsaren hämtar nu sömnsegment från ett 36-timmarsfönster och beräknar varaktigheten för den senaste grupperade perioden i stället för att summera alla sömnsegment under 24 timmar.
- Lagt till fem tester för överlapp, intilliggande segment, senaste period, ogiltiga intervall och tom data.

### Testresultat
- Första testkörningen visade fel i testernas datum-fixtures över midnatt, inte i intervallalgoritmen.
- Testdatumen korrigerades till explicita kalenderdagar.
- Därefter passerade samtliga 10 tester: fem för återhämtning och fem för sömnperioder.
- Körmiljö: Swift 6.2.1 på Linux x86_64.

### Kvar att verifiera
- 90-minutersgränsen är en teknisk grupperingströskel och behöver granskas mot verkliga HealthKit-sömndata.
- Valet av senaste sömnperiod kan behöva särskild hantering av tupplurar.
- HealthKit-integrationen är inte testad på iPhone.


## 2026-11-15 – Personlig baslinjeberäkning

### Implementerat
- Skapat `PersonalBaselineCalculator.swift` för att beräkna personlig median från dagliga hälsovärden.
- Flera mätningar samma kalenderdag reduceras till dagens median och räknas som en giltig dag.
- Ogiltiga, negativa, icke-finita och värden utanför valt tidsfönster ignoreras.
- Minst 14 distinkta giltiga dagar krävs innan baslinjen markeras som redo.
- Registrerat kalkylatorn i både Swift Package och Xcode-projektet.
- Lagt till fem enhetstester.

### Viktig avgränsning
Kalkylatorn är nu implementerad och testfallen är skrivna. HealthKitStore hämtar ännu inte 30-dagarsserierna eller matar kalkylatorn. Ingen återhämtningspoäng har därför aktiverats i gränssnittet.


## 2026-11-15 – HealthKit-historik och personliga baslinjer

### Implementerat
- Kopplat HealthKitStore till historiska mätserier för HRV SDNN och vilopuls.
- Hämtar 30 avslutade lokala kalenderdagar; dagens ofullständiga data ingår inte i baslinjen.
- Lagt till historisk sömnhämtning. Överlappande sömnstadier slås ihop och sessioner grupperas enligt befintlig 90-minutersregel.
- Sömnens dagliga representant är den längsta sömnperioden per lokal uppvakningsdag. Separata tupplurar adderas inte.
- Utökat sömnkalkylatorn så den kan returnera samtliga grupperade sessioner, inte bara den senaste.
- Utökat HealthSnapshot med separata baslinjer för sömn, HRV och vilopuls.

### Avgränsningar
- Baslinjerna kräver fortfarande minst 14 giltiga dagar per mätvärde.
- HealthKit-frågorna är ännu inte testade på fysisk iPhone och kan inte verifieras i Linux-testmiljön.
- HRV-representativitet, sömnens 90-minutersgruppering och valet av längsta session per uppvakningsdag behöver valideras mot verkliga användardata.
- Återhämtningsmotorn är ännu inte kopplad till dessa värden eller dashboarden; ingen återhämtningspoäng visas.


## 2026-11-15 – Återhämtningsmotor kopplad till dashboard

### Implementerat
- Utökat HealthSnapshot med en beräknad återhämtningsresultat-egenskap.
- Resultatet använder den lägsta giltiga dagsmängden bland sömn-, HRV- och vilopulsbaslinjerna. En komplett baslinje för en parameter kan inte dölja otillräckligt underlag för en annan.
- Kopplat den befintliga RecoveryEngine-prototypen till dashboardens statuskort.
- Dashboarden visar poäng, förklaring och tre komponentvärden när samtliga indata och baslinjer finns.
- Om data saknas visas ingen poäng; gränssnittet visar i stället hur många baslinjedagar som finns.
- Kroppsbatteriet hålls fortsatt separat och har ingen påhittad nivå eller kurva.

### Viktiga begränsningar
- Poängmodellen är fortfarande en teknisk wellness-prototyp och inte medicinskt validerad.
- Nuvarande HRV/vilopuls-indata är senaste tillgängliga HealthKit-värden, inte ännu en kvalitetssäkrad nattlig datapunkt med gemensam tidsstämpel.
- Sömnperiodsvalet behöver verifieras mot tupplurar och verkliga data.
- Ingen Xcode-build eller fysisk enhetstestning har utförts efter UI-integrationen.


## 2026-11-15 – Tidsstämplad urvalslogik för nattvärden

### Implementerat
- Skapat `OvernightMetricSelector.swift` som väljer HRV- och vilopulsvärden endast när deras tidsstämpel ligger inom den valda sömnperioden.
- Beräkningen använder medianen av giltiga värden inom perioden och redovisar antal sampel.
- Ogiltiga, negativa och icke-finita värden ignoreras.
- Om nattliga sampel saknas returneras nil. Dagtidsvärden får inte ersätta nattvärden i återhämtningsberäkningen.
- Lagt till fyra enhetstester och registrerat modellen i Swift Package samt Xcode-projektet.

### Avgränsning
- Urvalskärnan är implementerad men ännu inte inkopplad i HealthKitStore eller RecoveryEngine.
- Vilopuls från HealthKit kan vara aggregerad eller tidsstämplad på ett sätt som inte motsvarar en faktisk mätning under sömnen. Integrationen ska därför först kontrolleras mot HealthKit-data och får inte anta att vilopulssampel alltid finns under sömnperioden.
- Inga tester eller Xcode-build har körts efter denna ändring.


## 2026-11-15 – Koppling av nattliga värden till HealthKit

### Implementerat
- HealthKitStore hämtar nu tidsstämplade HRV SDNN- och vilopulssampel från ett rullande 36-timmarsfönster.
- Den senaste grupperade sömnperioden används som tidsfönster för natturvalet.
- HealthSnapshot håller nu isär senaste HRV/vilopuls för översikten och nattliga HRV/vilopuls för återhämtningsberäkningen.
- RecoveryEngine får endast nattvärdena. Om HealthKit saknar sampel inom sömnperioden visas ingen återhämtningspoäng.
- Sömnkalkylatorn kan nu returnera hela senaste sömnperioden, inte bara dess längd.
- Korrigerat test-fixtures för att uttryckligen passera midnatt.

### Begränsningar
- HealthKit:s vilopulsdata kan sakna sampel som faktiskt ligger inom sömnperiodens start- och sluttid. Då blir återhämtningsvärdet avsiktligt otillgängligt.
- Den senaste grupperade sömnperioden kan i vissa fall vara en tupplur. Urvalet av huvudperiod behöver valideras mot verkliga data.
- 36-timmarsfönstret, sample-tidsstämplar och datatillgänglighet måste verifieras på fysisk iPhone.
- Ingen Xcode-build eller testkörning har utförts efter integrationen.

## 2026-11-15 – Huvudsömn framför senaste sömnperiod
### Genomfört
- Infört `primarySession` som väljer den längsta grupperade sömnperioden inom HealthKit-fönstret i stället för att alltid välja den senast avslutade perioden.
- Vid lika lång varaktighet väljs perioden som avslutades senast.
- HealthKitStore använder nu huvudsömnurvalet för nattlig återhämtningsdata.
- Lagt till tester som säkerställer att en senare kort tupplur inte ersätter en längre huvudsömn och att lika långa perioder hanteras deterministiskt.
- Flyttat NaN-testvärdet så att det ligger inom den testade sömnperioden.

### Begränsning
- Längsta perioden är en heuristik, inte en säker identifiering av nattsömn. Skiftarbete, lång tupplur eller fragmenterad sömn kan ge andra mönster. Verkliga HealthKit-data måste valideras innan modellen betraktas som färdig.
- GitHub Actions för aktuell föregående commit rapporterade godkända core unit tests men underkänt i steget `Build iOS Simulator target`. Orsaken behöver fortsatt felsökas; ingen grön iOS-build påstås.


## 2026-11-15 – Första kroppsbatterimodellen
### Genomfört
- Skapat en separat, deterministisk `BodyBatteryEngine` som startar från nattens återhämtningspoäng och beräknar en preliminär daglig belastning från tidsstämplad puls och aktiv energi.
- Pulslast beräknas endast över sammanhängande intervall på högst 15 minuter och kräver minst tre pulssampel över minst 30 minuter.
- Saknat morgonvärde, saknad vilopulsbaslinje eller otillräcklig pulstäckning ger inget batterivärde.
- Lagt till fyra enhetstester för saknade data, otillräcklig täckning, belastning och filtrering av ogiltiga/utanförliggande sampel.

### Viktig begränsning
- Detta är en första teknisk prototyp, inte en validerad fysiologisk modell. Den räknar endast ned från morgonens återhämtningsvärde; uppladdning under vila och HealthKit-integration återstår. Ingen dashboard ska presentera modellen som färdig innan vidare validering.


## 2026-11-15 – HealthKit-koppling för kroppsbatteri
- Begärt läsbehörighet för puls från Apple Hälsa.
- Hämtar tidsstämplade pulssampel och aktiv energi i ett rullande 36-timmarsfönster.
- Kroppsbatteriet beräknas från uppvakningstid för vald huvudsömn, nattens återhämtningspoäng och personlig vilopulsbaslinje.
- Resultatet lagras separat i `HealthSnapshot` och visas i dashboardens kroppsbatterikort.
- Diagramplatshållaren har tagits bort; UI visar poäng och förklaring endast när modellen har tillräckligt underlag.
- HealthKit-resultatet är ännu inte validerat på fysisk iPhone. Modellen saknar fortfarande återladdning under vila och dess koefficienter är preliminära.

## 2026-11-15 – Korrekt intervallfiltrering för aktiv energi
- TimedHealthValue har fått en valfri starttidsstämpel så HealthKit-intervall bevaras.
- Aktiv energi räknas nu bara när hela samplets tidsintervall ligger efter uppvaknandet och före beräkningstidpunkten.
- Tester täcker sample som överlappar uppvaknandet, sample helt inom vakenperioden och sample efter aktuell tid.
- Detta förhindrar att aktiv energi som delvis uppstod under sömn felaktigt belastar dagens kroppsbatteri.
- Fortsatt prototyp: belastningskoefficienterna och återladdning under vila är inte validerade.

## 2026-11-15 – Fryst modell för dagsrapporter

### Implementerat
- Lagt till DailyReportSnapshot med separata rapporttyper för morgon och kväll.
- Rapporten lagrar poäng och hälsovärden som konkreta värden tillsammans med lokal rapportdag och fångsttid.
- Lagt till ReportSnapshotArchive som bara accepterar den första rapporten av en viss typ per lokal kalenderdag. Senare HealthKit-värden kan därmed inte skriva om morgonrapporten.
- Morgon och kväll är oberoende poster och kan sparas samma dag.
- Modellen stöder Codable så den kan lagras lokalt i nästa integrationssteg.
- Lagt till fem tester som täcker låsning, separata rapporttyper, ny lokal dag och serialisering.

### Avgränsning
- Detta är kärnmodell och testad arkivpolicy. Beständig lagring, schemaläggning, notiser och UI-historik är ännu inte inkopplade.
- iOS kan inte garantera att appkod körs exakt klockan 07:00 eller 21:00 när appen är avstängd eller suspenderad. Nästa steg måste kombinera schemalagda notiser med en säker fångstpolicy när appen får körningstid; en notis i sig får inte påstå att en rapport har uppdaterats om ingen snapshot faktiskt skapats.


## 2026-11-15 – Morgonrapportens utlösningspolicy
- Lagt till en fristående och testbar policy som bedömer om en händelse får skapa morgonrapport.
- Sömnfokus avslutat är en möjlig signal, men HealthKit-sömnuppdatering och att appen blir aktiv är uttryckliga reservsignaler.
- Rapport skapas bara om en registrerad huvudsömn är avslutad, minst tre timmar lång, högst 18 timmar gammal och har uppvakningsdatum på rapportens lokala kalenderdag.
- Kort tupplur, saknad sömndata, framtida/öppen sömnperiod och gammal sömnperiod avvisas.
- Åtta enhetstester täcker godkända signaler, reservvägar och avvisningsfall.
- Detta är en kärnpolicy, inte färdig bakgrundsintegration. HealthKit Observer Query med Background Delivery behöver implementeras och verifieras på fysisk enhet.


## 2026-11-15 – HealthKit bakgrundsobservation av sömn
- HealthKitStore skapar nu en HKObserverQuery för sleepAnalysis efter att användaren beviljat HealthKit-åtkomst.
- Observeraren begär Background Delivery med omedelbar frekvens och uppdaterar HealthSnapshot när sömndata ändras.
- HealthKit Background Delivery-entitlement har lagts till i appens entitlements.
- Observerhändelsen är en datakälla/uppdateringssignal, inte en direkt avläsning av Sömnfokus-status.
- Måste verifieras med signerad entitlement och fysisk iPhone; simulatorn stöder inte HealthKit background server queries.


## 2026-11-15 – Första kopplingen för fryst morgonrapport
- HealthKitStore laddar nu rapportarkivet från UserDefaults och utvärderar morgonrapport efter varje lyckad HealthKit-uppdatering.
- Rapporten skapas endast när MorningReportTriggerPolicy godkänner en avslutad huvudsömn på minst tre timmar inom tidsfönstret.
- Första rapporten för lokal kalenderdag sparas som DailyReportSnapshot. ReportSnapshotArchive.appendIfAbsent förhindrar att senare HealthKit-uppdateringar skriver över den.
- Saknade värden förblir nil; rapporten hittar inte på HRV, vilopuls, återhämtning eller aktivitetsvärden.
- MorningReport publiceras som aktuell dags rapport i HealthKitStore. Visning, historikvy, kvällsrapport och fysisk iPhone-verifiering återstår.
- CI för denna ändring är ännu inte bekräftad vid loggtillfället.


## 2026-11-15 – Rapporthistorik i dashboarden
- HealthKitStore exponerar nu sparade rapporter i omvänd kronologisk ordning.
- Dashboarden visar upp till fem senaste rapporter med rapporttyp, lokal dag och återhämtningspoäng när sådan finns.
- Historiklistan använder samma lokala arkiv som den frysta morgonrapporten; ingen separat kopia skapas.
- En dashboard-build misslyckades först på en bokstavlig escaped newline i Swift-filen. Den är korrigerad i commit `4cfcde466347648c8b0b9bfb8e1def62963dd4cd`; ny CI körs för senare commits.
- Senaste rapporthistorikändringarna inväntar fullständig CI-verifiering.


## 2026-11-15 – Kvällsrapportens första implementation
- Ny EveningReportTriggerPolicy använder 21:00 lokal tid som standard och kräver att händelsen tillhör rapportens lokala dag.
- HealthKitStore skapar en fryst kvällssnapshot vid första lyckade refresh efter 21:00. Samma arkiv och appendIfAbsent skyddar mot dubbletter och överskrivning.
- Daglig lokal notis schemaläggs kl. 21:00 om användaren beviljar notistillstånd. Notisen instruerar användaren att öppna VITAL; den lovar inte att iOS kör appen i bakgrunden.
- Dashboardens scenePhase-hantering uppdaterar HealthKit när appen återgår till förgrunden.
- Sex enhetstester täcker före/vid/efter 21:00, lokal rapportdag, anpassad timme och ogiltig tid.
- CI för kvällsrapportens modell, HealthKit-koppling och notisflöde är ännu inte bekräftad.
- Fysisk iPhone-testning och signerad IPA-export återstår.


## 2026-11-15 – Kvällsrapport i dashboarden
- Dashboarden visar nu kvällsrapportens fångsttid, steg, aktiv energi, senaste vilopuls och kroppsbatteri när rapporten finns.
- Om rapport saknas visas att påminnelsen kommer kl. 21:00 och att appen behöver öppnas för att fånga rapporten.
- Senaste vilopuls är uttryckligen märkt som senaste vilopuls, inte som momentan puls.
- CI för denna UI-ändring inväntas.


## 2026-11-15 – Fördröjd låsning av morgonrapport
- Identifierade risk att första sömnuppdateringen från HealthKit låste morgonrapporten innan övriga nattvärden hunnit synkroniseras.
- MorningReportTriggerPolicy kräver nu minst 20 minuter från huvudsömnens sluttid innan snapshot får skapas.
- Väntetiden kontrolleras vid varje befintlig trigger/refresh; den skapar ingen bakgrundstimer och lovar därför inte exakt rapporttid.
- Saknade värden förblir nil. Snapshoten är fortsatt oföränderlig efter arkivering.
- Lade till regressionstest för signal före respektive efter 20-minutersgränsen.


## 2026-11-15 – Felhantering för HealthKit-bakgrundsleverans
- Lade till backgroundSleepDeliveryEnabled i HealthKitStore.
- Resultatet från enableBackgroundDelivery hanteras nu uttryckligen; fel och nekad aktivering visas i lastError.
- Ingen garanti om omedelbar bakgrundskörning görs. Verifiering kräver signerad app på fysisk iPhone.


## 2026-11-15 – Robustare kvällspåminnelse
- Ändrade notisflödet så att befintlig iOS-behörighet läses innan någon systemdialog begärs.
- Behörighetsfrågan visas endast vid notDetermined. Nekad behörighet visas som status och väntande notis tas bort.
- Dashboardens statusdel visar nu separat kvällsnotisens behörighet och HealthKit-sömnens bakgrundsleverans.

## 2026-11-15 – Tidszonsstabil rapporthistorik
- Lade till sparad lokal dagnyckel och tidszonsidentifierare i nya rapport-snapshots.
- Dubblettskyddet använder nu den ursprungliga rapportdagen i stället för att omtolka historiska datum med aktuell tidszon.
- Lade till bakåtkompatibel Codable-avkodning för äldre arkiv samt stabil datumetikett i dashboardens historik.
- Lade till tester för byte mellan tidszoner och svensk sommartidsdag. CI-resultat inväntas.


## 2026-11-15 – Förberedelse av iOS-enhetsarkiv i CI
- Utökade GitHub Actions med ett separat Release-arkivsteg för generisk iOS-enhet med kodsignering avstängd.
- Arkivet laddas upp som ett kortlivat CI-artifakt för inspektion. Det är uttryckligen osignerat och kan inte installeras på iPhone.
- Syftet är att verifiera att projektet kan arkiveras för iOS-enhet innan Apple Team, certifikat och provisioning finns tillgängliga.
- Resultatet av arkivsteget inväntas; ingen IPA har skapats.


## 2026-11-15 – IPA-flöde för sideload-signering
- Produktmålet är förtydligat: VITAL ska levereras som osignerad iPhone-IPA för signering via användarens sideload-verktyg, inte som App Store-release.
- GitHub Actions paketerar nu appbundle från det godkända osignerade iOS-arkivet till `VITAL-unsigned.ipa` med `Payload/VITAL.app` och laddar upp den som separat artefakt.
- IPA:n är avsiktligt osignerad och måste signeras av AltStore/SideStore eller motsvarande innan installation.
- CI-resultat för paketeringen inväntas. HealthKit-entitlement och bakgrundsleverans behöver testas efter signering på fysisk iPhone.


## 2026-11-15 – Produktomfattning breddas till helhetslösning
- Efter första iPhone-testet identifierades behov av fler HealthKit-datakategorier och en samlad vikt- och läkemedelsjournal.
- Nuvarande HealthKitStore begär läsning av sju typer: sömn, vilopuls, HRV, puls, steg, aktiv energi och kroppsvikt. Detta förklarar det begränsade urvalet i Apples behörighetsdialog.
- Produktinriktningen breddas till hälsa/återhämtning, aktivitet, viktutveckling och läkemedelsuppföljning inklusive Wegovy-doslogg, påminnelser och biverkningslogg.
- En eventuell beräknad semaglutidnivå ska vara tydligt märkt som teoretisk uppskattning, aldrig uppmätt blodnivå eller doseringsrekommendation.
- Beslut och roadmap uppdaterade; implementationen är ännu inte påbörjad.


## 2026-11-15 – Första versionen av måendedagboken
- Lade till en lokal, beständig måendedagbok i dashboarden.
- Användaren kan registrera måendet med sju tillstånd, intensitet 1–5 och fri anteckning.
- Dashboardkortet visar senaste registreringen och en enkel färgkodad sjudagarsöversikt när tillräckligt många registreringar finns.
- Registreringar sparas lokalt i UserDefaults och lämnar inte enheten i denna implementation.
- Första versionen är en grundfunktion; längre historik, filter, graf med datumaxel och korrelation mot sömn/vikt/läkemedel återstår.
- CI-resultat för denna UI-ändring inväntas.


## 2026-11-15 – Mer grafisk dashboard
- Återhämtningskortet och kroppsbatteriet använder nu cirkulära visuella mätare i stället för enbart horisontella staplar och text.
- Måendedagboken har redan en färgkodad trendvy för de senaste registreringarna.
- Målet är att fortsätta med riktiga historiska grafer för vikt, aktivitet och läkemedelslogg när respektive datamodell finns; inga syntetiska datapunkter används.
- CI verifiering av UI-ändringen inväntas.


## 2026-11-15 – VITAL-appikon integrerad i byggkedjan
- Ny appikonriktning med marinblå grund, turkos/lila gradient, hjärta och EKG-linje har godkänts.
- Lagt till en reproducerbar macOS/Swift-baserad ikonrenderare och AppIcon asset catalog.
- Xcode-targeten pekar nu på AppIcon och GitHub Actions genererar ikonen före simulatorbygge och IPA-arkivering.
- CI måste verifiera renderaren och att ikonen följer med i appbundle innan ändringen betraktas som färdig.


## 2026-11-15 – Visuell omarbetning efter iPhone-test

### Genomfört
- Bytt appikonsymbol från den tidigare textbaserade logotypen till en ren hjärt-/ECG-symbol på djup marinblå grund, med turkos linjeföring och diskret halo.
- Ändrat startsidans ordning så återhämtning, nyckelmått, kroppsbatteri och rörelse kommer före mående och rapporthistorik.
- Samlat morgonrapport, kvällsrapport och rapporthistorik i en hopfällbar sektion för att minska mängden text vid första anblick.
- Kortat hjälpförklaringar i återhämtnings- och kroppsbatterikorten. Saknade värden fortsätter att visas som saknade och inte som noll.

### Kvar att göra
- Granska den nya ikonen på faktisk iPhone efter nästa IPA-installation.
- Fortsätta utveckla VITALs visuella komponentbibliotek med egna ringar, datagrafik och tydligare aktivitetsvisualiseringar.
- Genomföra ny CI-build och granska eventuella SwiftUI-kompileringsfel innan IPA delas.


## 2026-11-15 – Grafisk aktivitetsring och mätkort

- Ersatt den linjära stegmålsindikatorn med en egen cirkulär aktivitetsring som visar faktisk andel av 8 000-stegsmålet.
- Ringen visar neutral saknad status när HealthKit saknar stegvärde; den fabricerar inte nollsteg.
- Gjort sömn-, HRV-, vilopuls- och stresskorten mer grafiska med egna symboler, färgaccent och tydligare visuell hierarki.
- Fortsatt använda enbart riktiga HealthKit-värden i mätkorten; inga syntetiska trendkurvor har lagts till.


## 2026-11-15 – Funktionella huvudflikar

- Ersatt platshållarna för Insikter, Aktivitet och Hälsa med separata SwiftUI-vyer.
- Insikter visar sparade morgonvärden för återhämtning som diagram när sådana finns, samt status för personliga baslinjer.
- Aktivitet visar stegmål i cirkelring, aktiv energi och tillgängligt underlag för kroppsbatteriet.
- Hälsa visar senaste sömn, HRV, vilopuls och vikt från HealthKit.
- Alla vyer använder endast befintliga HealthKit-värden och frysta rapporter. Saknad historik visas som tomt läge, inte som syntetiska kurvor.
- Kompileringskontroll via GitHub Actions återstår för denna ändring.


## 2026-11-15 – Blodtryckslogg

- Lagt till manuell blodtrycksregistrering i fliken Hälsa med systoliskt och diastoliskt tryck, valfri puls och anteckning.
- Mätningar sparas lokalt på enheten och sorteras med senaste först.
- Visar senaste mätningen och en trendgraf för upp till tio senaste mätningar.
- Lagt till delbar textbaserad sammanställning med upp till 100 mätningar för att kunna lämna till läkare.
- Validerar rimliga inmatningsintervall och markerar att loggen inte är diagnostik.
- Nästa steg: komplettera med import/läsning av blodtryck från Apple Hälsa när sådana mätningar finns, samt testa export och graf på fysisk iPhone.


## 2026-11-15 – Vattenlogg med påminnelser

- Lagt till en grafisk vattenlogg i Hälsa med cirkulär måluppföljning, 2 000 ml initialt dagsmål och snabbregistrering för 150, 250 och 500 ml.
- Stöd för ångra senaste registrering.
- Dagens summering sparas lokalt och nollställs automatiskt vid ny kalenderdag.
- Valbara återkommande påminnelser kl. 08–20 med intervall 1–4 timmar och separat av/på-reglage.
- Påminnelser använder iOS-notiser och kräver användarens notisbehörighet.
- Dagsmålet är ett redigerbart produktbeslut att finjustera senare; 2 000 ml är en generell startinställning och inte en individuell medicinsk rekommendation.


## 2026-11-15 – Första viktjournalen

- Lagt till manuell viktregistrering med valfri anteckning och lokal beständig lagring.
- Lagt till redigerbart målvärde och visning av återstående kg till målet.
- Lagt till historikdiagram baserat enbart på registrerade viktvärden samt förändring sedan första registreringen.
- Visar aktuell vikt från Apple Hälsa när ingen manuell registrering finns och märker datakällan.
- Nästa steg: CI-verifiering, bättre startviktsflöde, förändring i procent, datum-/historikdetaljer och verifierad HealthKit-viktserie.


## 2026-11-15 – Första läkemedelsjournalen

- Lagt till lokal doshistorik för Wegovy med registrerad mängd i mg och datum/tid.
- Lagt till biverkningslogg med typ, intensitet 1–5 och valfri anteckning.
- Lagt till en valbar engångspåminnelse med datum och tid via iOS-notiser.
- Doser och tider anges av användaren enligt ordination; appen ger inga doseringsförslag eller råd om dosändring.
- Data lagras lokalt i UserDefaults och sorteras nyast först.
- Nästa steg: CI-verifiering, export av läkemedelsjournalen, möjlighet att redigera/ta bort felregistreringar och test av notiser på fysisk iPhone.


## 2026-11-15 – Privat framstegsfotohistorik

### Implementerat
- Lagt till en lokal framstegsfotohistorik i Hälsa.
- Bilder väljs via iOS bildväljare och kopieras till appens privata dokumentkatalog.
- Metadata med datum och valfri anteckning sparas lokalt.
- Lagt till bildhistorik, markering av exakt två bilder och jämförelse sida vid sida.
- Lagt till fotoguide med råd om konsekvent ljus, avstånd, höjd och bakgrund.
- Lagt till individuell radering av bilder.
- Bilder läggs inte automatiskt till i Bilder och delas inte automatiskt.

### Avgränsningar att verifiera
- Funktionen är implementerad i SwiftUI men behöver verifieras genom CI-build och på fysisk iPhone.
- Bilderna är lokala appdata och synkas inte via iCloud. Om appen avinstalleras kan de försvinna.
- Vikt kopplas tills vidare via senast registrerade vikt i viktjournalen; historisk vikt per enskild bild är inte låst ännu.
- Automatisk vikttext i delningsbild ingår inte i första versionen.


## 2026-11-15 – Kvalitetsjustering av viktjournal

- Tog bort den förinställda målvikt på 90 kg som kunde uppfattas som ett rekommenderat eller personligt mål.
- Målvikt är nu frivillig och anges av användaren själv.
- Målviktens värde valideras inom samma rimliga inmatningsintervall som viktregistreringen.
- Om inget mål har angetts visas i stället en tydlig åtgärd för att lägga till ett eget mål.
- Befintliga sparade målvärden bevaras om de är giltiga.
- Ändringen inväntar CI-build och behöver därefter provas i appen.
