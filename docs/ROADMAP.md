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
- [~] Skapa Xcode-projekt – måste verifieras genom faktisk build
- [ ] Bygg och kör i simulator
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
- [ ] Morgonrapport kl. 07:00 som fryst snapshot
- [ ] Kvällsrapport kl. 21:00
- [ ] Påminnelser om blodtryck morgon och kväll
- [ ] Notiser och stöd för Apple Watch där plattformen tillåter
- [ ] Hantera iOS-begränsningar för bakgrundskörning och schemaläggning

## Fas 6 – Insikter och Apple Watch
- [ ] Vecko- och månadsrapporter
- [ ] Personliga trender och avvikelseförklaringar
- [ ] AI-baserade insikter med tydlig källredovisning
- [ ] Apple Watch-komponenter och relevanta komplikationer/notiser

## Fas 7 – Kvalitet och release
- [ ] Enhetstester för beräkningar
- [ ] Test med saknade, ofullständiga och motstridiga data
- [ ] Integritet- och behörighetsgranskning
- [ ] Prestanda- och batteritest
- [ ] Signerad IPA och verifierad installation
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
- [ ] Förbättra valet av huvudsömn så att tupplurar inte blir nattens återhämtningsperiod
- [ ] Köra samtliga enhetstester och Xcode-build
