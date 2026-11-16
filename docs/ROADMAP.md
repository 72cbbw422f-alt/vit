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
- [ ] Matcha referensbildernas layout, marginaler, typografi och kortproportioner
- [ ] Byt ut graflinjeplatshållare mot riktiga tidsserier
- [ ] Lägg till tom-, laddnings- och felstater
- [ ] Säkerställ tillgänglighet och dynamisk textstorlek
- [ ] Lägg till uppdatering och tydlig senaste uppdateringstid

## Fas 3 – Hälsodata
- [ ] Verifiera sömnsammanställning utan dubbelräkning av överlappande sömnsegment
- [ ] Läs HRV SDNN med korrekt enhet och tidsfönster
- [ ] Läs vilopuls, steg, aktiv energi, vikt och blodtryck där tillgängligt
- [ ] Definiera datakvalitet, källor och färskhet för varje mätvärde
- [ ] Lägg till historiska tidsserier

## Fas 4 – Återhämtning och energi
- [ ] Specificera nattligt återhämtningsvärde
- [ ] Specificera dynamiskt kroppsbatteri separat
- [ ] Definiera personlig baslinje, datakrav och hantering av saknade värden
- [ ] Validera modeller mot verkliga data och visa förklaringar
- [ ] Håll prognos och historik visuellt åtskilda

## Fas 5 – Rapporter och notiser
- [x] Händelsestyrd morgonrapport efter huvudsömn, med väntetid och fryst snapshot
- [x] Kvällsrapport vid första säkra refresh efter 21:00 och lokal påminnelse
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
- [~] Första viktmodul: manuell registrering, redigerbar målvikt, förändring i kg och historikgraf; startvikt/procent och full HealthKit-synk återstår
- [ ] Synka vikt med Apple Hälsa och tillåt manuell registrering med tydlig källa
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
