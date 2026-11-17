# VITAL 3.0 – Roadmap

Status betyder:
- [x] Inlagt i repository
- [ ] Återstår
- [~] Påbörjat men inte verifierat/färdigt

## Fas 1 – Appgrund
- [x] Skapa arbetsgrenen `vital-3.0`
- [x] Skapa SwiftUI-startpunkt
- [x] Skapa designfärger och grundläggande kortkomponent
- [x] Skapa fyra flikar
- [x] Skapa första dashboard-layouten
- [x] Skapa första HealthKit-läsaren
- [x] Skapa Info.plist och HealthKit-entitlement
- [x] Skapa Xcode-projekt och verifiera projektstruktur i CI
- [x] Bygg iOS Simulator-målet i CI
- [ ] Starta och prova appen interaktivt i simulator
- [ ] Bygg och kör på fysisk iPhone
- [ ] Verifiera HealthKit-behörigheter och verklig dataläsning

## Fas 2 – Dashboard
- [~] Grundläggande Midnight-designsystem och fyra flikar finns; full visuell avstämning mot referensbilderna återstår
- [x] Ersätta illustrativa grafer med riktiga datakällor eller tydliga tomlägen
- [~] Huvudkort för nattlig återhämtning med poängring, signaler och dagsråd implementerat; visuell finjustering och datavalidering återstår
- [~] Tom- och saknat-underlagstillstånd finns på flera vyer; full genomgång av laddnings- och felstater återstår
- [ ] Säkerställ tillgänglighet och dynamisk textstorlek
- [x] Lägg till uppdatering och senaste uppdateringstid där relevant

## Fas 3 – Hälsodata
- [x] Implementera sömnsammanställning utan dubbelräkning av överlappande segment
- [x] Läs HRV SDNN med separat nattfönster och senaste värde
- [x] Läs vilopuls, steg, aktiv energi, vikt och blodtryck där tillgängligt
- [x] Läsa andningsfrekvens och syremättnad när HealthKit-typer finns
- [~] Datakälla, tidsstämpel och saknat-underlagstillstånd visas för flera mått; full konsekvent granskning återstår
- [ ] Verifiera verkliga HealthKit-serier och blodtryckskorrelationer på fysisk iPhone
- [ ] Lägg till historiska tidsserier för vikt och blodtryck

## Fas 4 – Återhämtning och energi
- [x] Implementera nattligt återhämtningsvärde med sömn, HRV och vilopuls
- [x] Implementera dynamiskt kroppsbatteri separat
- [x] Definiera personliga baslinjer, datakrav och hantering av saknade värden
- [~] Visa förklaringar och signalbaserade råd; heuristikerna behöver valideras mot verkliga data
- [x] Håll nattlig återhämtning och dagens kroppsbatteri visuellt åtskilda
- [ ] Verifiera tidsfönster, baslinjer och poäng på fysisk iPhone

## Fas 5 – Rapporter och notiser
- [x] Historisk fryst morgonrapportmodell och arkiv finns kvar för bakåtkompatibilitet
- [x] Avveckla aktivt kvällsrapportflöde och kvällsrapportnotis
- [~] Dashboarden visar aktuell nattåterhämtning; historisk rapportvy och användarupplevelse behöver slutlig avstämning
- [ ] Påminnelser om blodtryck morgon och kväll
- [ ] Notiser och stöd för Apple Watch där plattformen tillåter
- [ ] Hantera iOS-begränsningar för bakgrundskörning och schemaläggning

## Fas 6 – Insikter och Apple Watch
- [ ] Vecko- och månadsrapporter
- [ ] Personliga trender och avvikelseförklaringar
- [ ] AI-baserade insikter med tydlig källredovisning
- [ ] Apple Watch-komponenter och relevanta komplikationer/notiser

## Fas 7 – Kvalitet och release
- [x] Enhetstester för kärnberäkningar och rapportpolicyer
- [ ] Test med saknade, ofullständiga och motstridiga data
- [ ] Integritet- och behörighetsgranskning
- [ ] Prestanda- och batteritest
- [ ] Konfigurera iOS-signering/provisionering och skapa IPA
- [ ] Verifiera installation och HealthKit-flöde på fysisk iPhone
- [ ] Releaseanteckningar och versionshistorik


## Uppdatering 2026-11-15 – Byggprocess
- [x] Lägga till delad Xcode-scheme
- [x] Lägga till macOS-baserad GitHub Actions-build
- [x] Ta bort exempelkurva som kunde förväxlas med verkliga användardata
- [x] Förtydliga saknade datavärden på dashboarden
- [ ] Köra och godkänna första CI-builden


## Uppdatering 2026-11-15 – Återhämtningsmotor
- [x] Skapa fristående första version av återhämtningsberäkningen
- [x] Kräva personlig baslinje och avstå från poäng när data saknas
- [x] Lägga till fem automatiska enhetstester
- [x] Dokumentera modellens formler och begränsningar
- [ ] Hämta och beräkna rullande 30-dagarsbaslinjer via HealthKit
- [ ] Verifiera sömnperiod och överlappande sömnsegment
- [ ] Validera modellens viktning innan poängen visas i appen


## Uppdatering 2026-11-15 – Sömnperioder
- [x] Slå ihop överlappande sömnintervall för att undvika dubbelräkning
- [x] Gruppera sömnstadier till sömnperioder med en första 90-minutersgräns
- [x] Lägg till fem tester för sömnperiodsberäkningen
- [ ] Validera grupperingströskeln mot verkliga HealthKit-data och tupplurar
- [ ] Verifiera sömnresultat på fysisk iPhone


## Uppdatering 2026-11-15 – Personlig baslinje
- [x] Implementera medianbaserad personlig baslinje
- [x] Räkna högst en giltig dag per kalenderdag
- [x] Ignorera ogiltiga och utanför-fönstret-värden
- [x] Kräva minst 14 giltiga dagar
- [x] Lägga till fem tester för baslinjekalkylatorn
- [x] Hämta 30-dagarsserier för HRV, vilopuls och sömn från HealthKit och koppla in baslinjekalkylatorn
- [ ] Verifiera historiska HealthKit-frågor och baslinjer på fysisk iPhone
- [x] Koppla baslinjer till återhämtningsmotorn och visa saknat underlag i dashboarden
- [ ] Säkerställ att HRV och vilopuls avser relevant natt/tidsfönster
- [ ] Verifiera återhämtningspoängen med verkliga HealthKit-data innan modellen betraktas som färdig
- [ ] Validera datakvalitet och tidsfönster för varje mätvärde


## Uppdatering 2026-11-15 – Nattliga mätvärden
- [x] Skapa fristående urvalsmodell för tidsstämplade nattliga HRV- och vilopulsvärden
- [x] Kräva att sampel ligger inom vald sömnperiod
- [x] Låta saknade nattliga sampel förbli saknade
- [x] Lägga till fyra automatiska testfall
- [ ] Koppla urvalsmodellen till HealthKitStore
- [ ] Verifiera om HealthKit:s vilopulssampel faktiskt kan knytas till sömnperioden
- [ ] Koppla endast kvalitetssäkrade nattvärden till återhämtningsmotorn


## Uppdatering 2026-11-15 – HealthKit nattintegration
- [x] Hämta tidsstämplade HRV- och vilopulssampel från HealthKit
- [x] Välja sampel inom explicit sömnperiod
- [x] Hålla senaste dagvärden separerade från nattliga återhämtningsvärden
- [x] Förhindra att dagvärden används som reserv för saknade nattvärden
- [ ] Verifiera sample-tidsstämplar och vilopulsdata på fysisk iPhone
- [x] Införa heuristik som väljer längsta sömnperioden framför en senare kort tupplur
- [ ] Validera huvudsömnheuristiken mot verkliga HealthKit-data, skiftarbete och fragmenterad sömn
- [ ] Köra samtliga enhetstester och Xcode-build


## Uppdatering 2026-11-15 – Kroppsbatteri prototyp
- [x] Skapa separat deterministisk beräkningsmotor för kroppsbatteriet
- [x] Starta från nattens återhämtningspoäng, separat från daglig belastning
- [x] Beräkna pulsbelastning från tidsstämplade sampel med max 15 minuters lucka
- [x] Ta med aktiv energi som separat belastningskomponent
- [x] Avstå från poäng vid otillräcklig pulstäckning eller saknad baslinje
- [x] Lägga till fyra tester för modellens grundfall och datakvalitet
- [ ] Köra och godkänna CI för kroppsbatterimodellen
- [ ] Hämta tidsstämplade puls- och energisampel från HealthKit
- [ ] Integrera resultat och datakvalitet i dashboarden
- [ ] Utveckla och validera återladdning under vila
- [ ] Kalibrera belastningskoefficienter mot verkliga data


## Uppdatering 2026-11-15 – HealthKit-koppling kroppsbatteri
- [x] Begära HealthKit-läsbehörighet för puls
- [x] Hämta tidsstämplade pulssampel från HealthKit
- [x] Hämta aktiva energisampel från HealthKit
- [x] Beräkna kroppsbatteri från uppvakningstid, nattåterhämtning och personlig vilopulsbaslinje
- [x] Lagra resultat separat i HealthSnapshot
- [x] Visa kroppsbatteri i dashboarden med förklaring och datastatus
- [ ] Godkänna CI för HealthKit- och UI-integrationen
- [ ] Verifiera datainsamling och resultat på fysisk iPhone
- [ ] Utveckla och validera återladdning under vila
- [ ] Kalibrera belastningskoefficienter mot verkliga data

## Uppdatering 2026-11-15 – Energins tidsintervall
- [x] Bevara start- och sluttid för HealthKit-sampel
- [x] Räkna endast aktiva energisampel som helt ligger inom vakenperioden
- [x] Lägga till regressionstest för intervall som överlappar uppvaknande
- [ ] Verifiera CI för korrigeringen
- [ ] Validera kroppsbatteriets koefficienter och återladdning med verkliga data

## Uppdatering 2026-11-15 – Fryst rapportmodell
- [x] Skapa en oföränderlig rapportmodell med separata typer för morgon och kväll
- [x] Spara mätvärden och poäng som frysta värden vid fångsttillfället
- [x] Förhindra att en senare rapport för samma dag och typ skriver över den första
- [x] Tillåta en separat kvällsrapport samma kalenderdag
- [x] Stödja kodning/avkodning för framtida lokal persistens
- [x] Lägga till fem tester för låsning, separata rapporttyper, ny dag och Codable
- [x] Koppla arkivet till beständig lokal lagring i appen
- [ ] Implementera schemalagd 07:00- och 21:00-fångst med iOS-begränsningar
- [x] Visa aktuell fryst morgonrapport och fångsttid i dashboarden\n- [ ] Bygga fullständig rapporthistorikvy
- [ ] Verifiera CI för den nya modellen


## Uppdatering 2026-11-15 – Rapporternas utlösare
- [x] Besluta att Sömnfokus-av är en möjlig morgonsignal efter huvudsömnen
- [x] Besluta att kvällsrapporten använder en fast lokal tid, 21:00 som standard
- [x] Skapa testbar policy med Sömnfokus, HealthKit-sömnuppdatering och appaktivitet som signaler\n- [x] Implementera HealthKit Observer Query för sleepAnalysis och begära Background Delivery\n- [x] Lägga till Background Delivery-entitlement i appens entitlements
- [x] Kontrollera avslutad huvudsömn, minsta sömnlängd, maxålder och lokal rapportdag i kärnmodellen\n- [ ] Verifiera provisionerad Background Delivery-entitlement, HealthKit-datans timing och observer-callback på fysisk iPhone
- [ ] Hantera fördröjda HealthKit-sampel utan att skriva om en redan låst rapport
- [ ] Skydda mot dubbletter och felaktiga utlösningar vid tupplur eller manuell Fokusändring
- [ ] Schemalägga kvällsrapportens lokala notis och skapa kvällssnapshot vid säker körningstid
- [x] Testa grundläggande utlösningspolicy och reservsignaler\n- [ ] Testa tidszon, sommartid, omstart och flera Fokusväxlingar på enhet


## Uppdatering 2026-11-15 – Första morgonrapportflödet
- [x] Koppla HealthKit-uppdatering till morgonrapportens utlösningspolicy
- [x] Spara första morgonrapporten per lokal dag i UserDefaults
- [x] Låsa rapporten så senare uppdateringar inte skriver över den
- [x] Visa rapportvärden och fångsttid i dashboarden
- [ ] Förbättra hantering av fördröjda/partiella HealthKit-data före låsning
- [ ] Lägga till fullständig rapporthistorik
- [ ] Verifiera flödet på fysisk iPhone med riktiga HealthKit-data


## Uppdatering 2026-11-15 – Kvällsrapportens första implementation
- [x] Skapa testbar lokal tidsregel med 21:00 som standard
- [x] Skapa fryst kvällssnapshot vid första lyckade refresh efter 21:00
- [x] Använd samma arkiv och dubblettskydd som morgonrapporten
- [x] Schemalägga daglig lokal påminnelse kl. 21:00 efter notistillstånd
- [x] Kontrollera rapportflödet när appen återgår till förgrunden
- [ ] Verifiera kvällsrapport, notistillstånd, tidszon och sommartid på fysisk iPhone
- [ ] Lägga till inställning för anpassad kvällstid
- [ ] Slutföra CI för kvällsrapportens nya modell och HealthKit-koppling


## Uppdatering 2026-11-15 – Dataväntan för morgonrapport
- [x] Införa minst 20 minuters väntetid efter huvudsömnens sluttid innan morgonrapport får låsas
- [x] Lägga till test som stoppar för tidig rapport och godkänner rapport efter väntetiden
- [ ] Verifiera HealthKit-synkroniseringens faktiska fördröjning på fysisk iPhone
- [ ] Utvärdera 20-minutersheuristiken mot verkliga användardata


## Uppdatering 2026-11-15 – HealthKit-bakgrundsstatus
- [x] Hantera resultatet från enableBackgroundDelivery och exponera aktiveringsstatus
- [ ] Verifiera entitlement och bakgrundsleverans med signerad app på fysisk iPhone


## Uppdatering 2026-11-15 – Notisstatus
- [x] Kontrollera iOS-notisbehörighet innan eventuell begäran
- [x] Undvika upprepade behörighetsdialoger när användaren redan valt
- [x] Visa notisstatus och HealthKit-bakgrundsstatus separat i dashboarden
- [ ] Verifiera notisleverans och inställningsflöde på fysisk iPhone

## Uppdatering 2026-11-15 – Tidszonsstabil rapporthistorik
- [x] Spara lokal kalenderdag som stabil dagnyckel i nya rapporter
- [x] Spara tidszonsidentifierare vid rapportens fångst
- [x] Behålla gamla rapportarkiv läsbara med bakåtkompatibel avkodning
- [x] Visa historikdatum utifrån rapportens sparade lokala dag
- [x] Lägga till tester för tidszonsbyte och sommartidsdag
- [ ] Verifiera tidszonsbyte, omstart och historik på fysisk iPhone
- [ ] Bekräfta CI för denna ändring


## Uppdatering 2026-11-15 – CI och releaseförberedelser
- [x] GitHub Actions run 191 godkänd: kärntester och iOS Simulator-build
- [x] Dokumentera tidszonsstabil rapporthistorik och bakåtkompatibel arkivavkodning
- [ ] Köra appen interaktivt i simulator och granska samtliga skärmar
- [ ] Konfigurera giltig iOS-signering och provisioning för fysisk enhet
- [ ] Skapa signerad IPA och verifiera installation på iPhone
- [ ] Genomföra fysisk HealthKit-, bakgrundsleverans- och notistestning


## Uppdatering 2026-11-15 – Enhetsarkiv verifierat
- [x] Bygga Release-arkiv för `generic/platform=iOS` i GitHub Actions utan kodsignering
- [x] Ladda upp och kontrollera arkivets appbundle och dSYM som CI-artifakt
- [ ] Skapa säker signeringskonfiguration med Apple Development-certifikat och provisioning profile
- [ ] Exportera signerad IPA och verifiera installation på fysisk iPhone
- [ ] Verifiera HealthKit-behörigheter, bakgrundsleverans och notiser på enheten


## Uppdatering 2026-11-15 – Sideload-IPA
- [x] Fastställa leveransmål: osignerad IPA för signering i användarens sideload-verktyg
- [x] Lägga till CI-paketering av `Payload/VITAL.app` till osignerad `.ipa`
- [ ] Verifiera att IPA-artefakten skapas och har korrekt Payload-struktur
- [ ] Signera IPA via AltStore/SideStore eller motsvarande och installera på iPhone
- [ ] Testa HealthKit-läsning, entitlement, notiser och bakgrundsleverans efter sideload-signering


## Uppdatering 2026-11-15 – VITAL som helhetslösning
- [ ] Utöka HealthKit-stöd och behörighetsintroduktion för relevanta hälsokategorier utöver nuvarande sju datatyper
- [ ] Inventera tillgängliga HealthKit-typer och skilja mellan läsbara data, datakällor som saknas och behörighet som användaren inte beviljat (iOS kan begränsa insyn i läsbehörighet)
- [~] Viktmodul finns med lokal journal och målvikt; nuvarande manuella registreringsflöde behöver ersättas enligt produktkravet om automatisk Apple Hälsa-läsning
- [ ] Läs vikt och blodtryck från HealthKit med korrekta tidsstämplar och tydlig datakälla
- [ ] Ta bort nya manuella registreringsflöden för vikt och blodtryck när HealthKit-visningen är verifierad; bevara befintliga lokala journaldata läsbara under övergången
- [ ] Skapa läkemedelsmodul med Wegovy-dos, doshistorik, dosintervall och nästa dospåminnelse
- [ ] Skapa logg för upplevda biverkningar med datum, intensitet och fritext
- [ ] Utreda och dokumentera en försiktig, teoretisk semaglutidnivå-kurva; aldrig presentera den som uppmätt nivå eller doseringsråd
- [ ] Utforma en samlad hälsotidslinje där vikt, doser, biverkningar, sömn och återhämtning kan jämföras utan att påstå orsakssamband
- [ ] Lägga till integritetsvänlig export och säker lokal lagring för läkemedels- och viktjournal


## Uppdatering 2026-11-16 – Fler HealthKit-mått
- [x] Begära läsbehörighet för andningsfrekvens och syremättnad
- [x] Hämta senaste tillgängliga värden från HealthKit
- [x] Visa värdena separat i Hälsa-fliken
- [x] Formatera syremättnad från HealthKit-andel till procent
- [x] Behålla saknade/ogiltiga värden som saknade
- [ ] Verifiera datatillgänglighet och enheter på fysisk iPhone/Apple Watch


## Uppdatering 2026-11-16 – Robust HealthKit-behörighet
- [x] Säkerställ att valfria mätvärden inte blockerar grundläggande HealthKit-auktorisering
- [x] Behåll saknade valfria mätvärden som saknade
- [ ] Verifiera ändringen i CI och på fysisk iPhone


## Uppdatering 2026-11-16 – HealthKit vikt och blodtryck
- [x] Läsa senaste viktvärde och mättid från HealthKit
- [x] Läsa systoliskt och diastoliskt blodtryck från samma HealthKit-korrelation
- [x] Visa HealthKit som primär källa för aktuell vikt och blodtryck
- [x] Ta bort nya manuella registreringsflöden från vikt- och blodtryckskorten
- [x] Behålla tidigare lokala journalposter som äldre historik
- [ ] Verifiera HealthKit-korrelationer, enheter och tidsstämplar på fysisk iPhone
- [ ] Bygga historiska vikt- och blodtrycksgrafer från HealthKit-sampel


## Uppdatering 2026-11-16 – Uppstart och fysisk verifiering
- [x] Ändra simulator-smoketestet till PID-baserad processkontroll efter `simctl launch`
- [x] Korrigera shell-formatsträngen som används för att läsa PID från launch-utdata
- [ ] Få godkänd CI-körning med lyckad simulatorstart och kvarvarande app-process
- [ ] Granska simulatorloggar vid eventuell processavslutning
- [ ] Undersöka FlareStore-signerad IPA och dess entitlements om fysisk iPhone fortfarande kraschar
- [ ] Verifiera installation och uppstart på fysisk iPhone innan ny release betraktas som fungerande


## Uppdatering 2026-11-16 – HealthKit-auktorisering
- [x] Identifiera kraschen via simulatorns exception-logg
- [x] Ta bort blodtryckets korrelationstyp från `requestAuthorization(read:)`
- [x] Behålla systoliskt och diastoliskt som begärda lästyper
- [x] Behålla korrelationsfrågan för att hämta ett parat blodtrycksvärde
- [ ] Verifiera att appen passerar HealthKit-auktorisering i simulatorn
- [ ] Utvärdera simulatorns varning om saknat HealthKit-entitlement separat
- [ ] Bygg ny IPA först efter godkänd CI och verifierad simulatorstart


## Uppdatering 2026-11-16 – Ny produkt- och designriktning för startsidan

### Beslutad målbild
- [x] Fastställa visuell riktning: ren, luftig och premiumbetonad mörk hälsodesign med grafiska mätare, trenddiagram och tydlig informationshierarki
- [x] Behålla Midnight Navy och befintliga accentfärger teal, violet och amber
- [x] Besluta att startsidan ska prioritera förståelse och rekommendation framför en tät lista av siffror
- [x] Ersätta separat morgon- och kvällsrapport med en enda daglig morgonsammanfattning
- [x] Behålla morgonsammanfattningen som fryst snapshot; senare HealthKit-data får inte skriva om den
- [x] Ta bort kvällsrapporten och den separata rapportsektionen ur målgränssnittet
- [ ] Designa om startsidan runt huvudkortet **Dagens återhämtning**
- [ ] Visa en grafisk återhämtningsindikator endast när datakvalitet och personlig baslinje räcker
- [ ] Visa kort nattöversikt, relevanta avvikelser och en förklarad dagsrekommendation
- [ ] Flytta detaljerade värden och historik till relevanta vyer under Insikter, Aktivitet och Hälsa
- [ ] Bygga riktiga sömn- och trendvisualiseringar från HealthKit-tidsserier; inga illustrativa låtsasgrafer
- [ ] Implementera tydliga tom-, laddnings-, fel- och otillräckligt-underlagstillstånd
- [ ] Granska och avveckla kvällsrapportens användarflöde, notis och schemaläggning utan att förlora nödvändig bakåtkompatibilitet
- [ ] Kvalitetssäkra rekommendationer mot personliga baslinjer, datakvalitet och flera samverkande signaler

### Helhetsprodukt – krav som ligger fast
- [x] Fyra flikar: Idag, Insikter, Aktivitet och Hälsa
- [x] Apple Health/HealthKit som primär källa för tillgängliga hälsomått
- [x] Separat nattlig återhämtning och dynamiskt kroppsbatteri
- [x] Personliga baslinjer och historiska trender
- [x] Automatisk HealthKit-läsning av vikt och blodtryck; inga nya manuella registreringsformulär för dessa mått
- [x] Läkemedels-/Wegovy-historik, biverkningslogg och samlad hälsotidslinje kvar i produktplanen
- [x] Notiser och Apple Watch-stöd där plattformen tillåter det
- [x] Ingen kost- eller näringsregistrering
- [ ] Säkerställa att samtliga tidigare beslutade funktioner har en tydlig plats och ett verkligt användningsvärde i den nya informationsarkitekturen

**Överordnat beslut:** Denna målbild ersätter tidigare roadmap-punkter om separata morgon- och kvällsrapporter som framtida användarupplevelse. Historiska implementationsposter behålls som utvecklingshistorik.


## Uppdatering 2026-11-16 – Första dashboardimplementation
- [x] Byta huvudkortets fokus till Dagens återhämtning
- [x] Visa grafisk återhämtningsring och kort statusförklaring när poäng finns
- [x] Visa tillstånd för otillräcklig personlig baslinje utan att hitta på värden
- [x] Visa en kompakt rad med nattens sömntid och nattliga HRV
- [x] Ta bort separat rapportsektion från startsidans synliga flöde
- [x] Ta bort stresskort utan direkt mätkälla
- [ ] Validera statusintervall och rekommendationslogik mot dokumenterad återhämtningsmodell och verkliga data
- [ ] Ersätta nuvarande poängbaserade generella råd med signalbaserade, förklarade rekommendationer
- [ ] Flytta detaljerade mätvärden till grafiska fördjupningsvyer
- [ ] Avveckla kvällsrapportens schemaläggning och notisflöde på ett bakåtkompatibelt sätt
- [ ] Köra CI och granska den nya dashboarden visuellt i simulator
- [ ] Verifiera HealthKit-data och gränssnitt på fysisk iPhone


## Uppdatering 2026-11-17 – Fryst sammanfattning och signalbaserade råd
- [x] Spara sömn-, HRV- och vilopulskomponenter i morgonsnapshoten
- [x] Visa återhämtningspoäng och nattvärden från fryst snapshot under hela dagen
- [x] Identifiera vilka personliga återhämtningssignaler som avviker
- [x] Visa neutralt tillstånd när nödvändiga komponenter saknas
- [x] Avveckla schemaläggning av kvällsrapportnotis
- [x] Sluta skapa nya kvällsrapportsnapshots utan att radera äldre lokala poster
- [x] Lägga till enhetstester för vägledningspolicyn
- [ ] Validera heuristiska trösklar och rekommendationer mot verkliga användningsdata innan de betraktas som slutliga
- [ ] CI och visuell simulatorgranskning efter denna ändring
- [ ] Fysisk iPhone-verifiering med HealthKit-data


## Uppdatering 2026-11-17 – CI och rapportstädning

- [x] Full CI-kedja godkänd på commit `cc243c9`: tester, simulatorbuild/start, enhetsarkiv och IPA-paketering
- [x] Ta bort oanvänd kvällsrapport-state från HealthKitStore
- [x] Ta bort oanvänd rapportvisning från DashboardView
- [x] Behålla bakåtkompatibel avkodning av äldre kvällsrapporter
- [ ] Köra CI på den efterföljande städningscommiten
- [ ] Fysisk iPhone-verifiering av HealthKit-auktorisering, bakgrundsleverans och HealthKit-värden
- [ ] Kontrollera FlareStore-signerad IPA och entitlements på den fysiska enheten
- [ ] Visuell granskning av dashboardens tom-, vänt-, fel- och datatillstånd


## 2026-11-17 – Korrigering av status och aktuell designriktning
- Dashboardens huvudkort använder nu aktuell `HealthSnapshot.recoveryResult`, inte den frysta morgonrapporten. Den äldre snapshotmodellen bevaras för historik/bakåtkompatibilitet.
- Nya manuella registreringsflöden för vikt och blodtryck är borttagna; tidigare lokala poster är läsbara som äldre historik. Målvikt är fortfarande en frivillig inställning.
- Den beslutade designriktningen är Midnight Navy med etablerade teal-, violet- och amber-accenter. Designsystemet finns, men samtliga fyra flikar är ännu inte visuellt slutgranskade.
- Run 44037409691 på commit `0a06959` har passerat kärntester, simulatorbuild, osignerat arkiv, ikonvalidering och IPA-uppladdning. Simulatorns processkontroll pågår; fysisk iPhone är inte verifierad.


## 2026-11-17 – Rapportflöde avvecklat
- [x] Ta bort automatisk skapning av nya frysta morgonrapporter från HealthKit-refresh
- [x] Behålla äldre rapportarkiv enbart för bakåtkompatibilitet
- [x] Låta startsidans återhämtningskort visa aktuell HealthKit-snapshot
- [ ] Rensa oanvänd rapportstate och rapportpolicy efter kontroll av alla referenser och migreringsbehov
