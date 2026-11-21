# VITAL 3.0 – Teknisk grundspecifikation

Status: beslutad målarkitektur, implementation och verifiering återstår om inget annat anges.
Arbetsgren: `vital-3.0`
Syfte: färdigställ datalager, HealthKit, beräkningsmotorer, datakvalitet och tester innan större visuell omarbetning.

## 1. Produktens tekniska kärna

VITAL ska besvara tre frågor:
1. Hur återhämtad är kroppen efter senaste huvudsömnen?
2. Hur förändras kroppens belastning och kapacitet under den vakna dagen?
3. Vilka kroppssignaler avviker från användarens personliga normala nivå?

VITAL är en wellness- och hälsöversiktsapp. Beräknade värden är inte diagnoser, medicinska mätningar eller ersättning för vårdens bedömning.

## 2. Omfattning

### Kärnmått
- Nattlig återhämtning.
- Dynamiskt kroppsbatteri.
- Stressindikator.
- Sömnperiod, sömnlängd och tillgängliga sömnstadier.
- HRV (SDNN).
- Vilopuls och tidsstämplad puls.
- Blodtryck (systoliskt/diastoliskt som ett giltigt par).
- Andningsfrekvens.
- Handledstemperatur som avvikelse från personlig baslinje, när datan finns.
- Aktivitet: steg, aktiv energi och tränings-/rörelsedata som behövs för belastningskontext.
- Personliga baslinjer, trender och datakvalitet.

### Tas bort ur produkten
- Vikt, målvikt och viktutveckling.
- Kroppsfett och fettfri massa/muskelmassa.
- Läkemedelsjournal, doshistorik och läkemedelsnivåmodell.
- Biverkningslogg och läkemedelspåminnelser.
- Progressbilder och vikt-/kroppsutvecklingsflöden.

Borttagningen ska omfatta UI, navigation, state, lokala journaler, beräkningskod, HealthKit-frågor/behörighet, notiser, tester och dokumentation. Kontrollera först om någon delad modell eller lagringsnyckel används av andra funktioner. Destruktiv radering av äldre lokala data ska inte göras utan separat migreringsbeslut.

### Utanför kärnan
- Kost- och kaloriregistrering.
- Diagnostik eller medicinska riskpoäng.
- Automatiska behandlings- eller dosråd.
- Fristående morgon-/kvällsrapporter och rapporthistorik i användarflödet.

## 3. HealthKit – datakontrakt

HealthKit är primär källa för automatiskt tillgängliga mätvärden. Varje datapunkt ska behålla:
- värde i en normaliserad enhet,
- start- och sluttid där typen har intervall,
- källa när det är tillgängligt,
- datatyp och urvalsperiod,
- valideringsstatus.

Frågor ska använda explicita tidsfönster och enheter. Nattvärden får endast väljas från den valda huvudsömnens tidsfönster. Senaste dagvärdet får aldrig användas som tyst ersättning för nattvärde.

HealthKit läsbehörighet kan inte säkert härledas från noll resultat. UI och diagnostik ska därför skilja på:
- värde hittat,
- inga sampel returnerade,
- frågefel,
- ej tillgänglig datatyp,
- otillräcklig täckning.

Blodtryck ska endast användas som korrelerat par med både systoliskt och diastoliskt värde. Orimliga värden och felaktiga enheter ska filtreras.

### Kärnfrågor
- Sleep Analysis och sömnstadier.
- Heart Rate Variability SDNN.
- Resting Heart Rate.
- Heart Rate.
- Active Energy Burned.
- Step Count.
- Blood Pressure Systolic + Diastolic / correlation.
- Respiratory Rate.
- Apple Sleeping Wrist Temperature.
- Exercise Time och rörelsedata där de behövs för belastningskontext.

Ta bort HealthKit-typer som enbart behövs av borttagna vikt-/kroppssammansättningsfunktioner. Begär minsta möjliga behörighet för den kvarvarande produkten.

## 4. Beräkningsmotorer

Beräkningsmotorerna ska vara fristående från SwiftUI och HealthKit-frågor. De tar emot normaliserade, tidsstämplade indata och returnerar resultat med komponenter, täckning, förklaring och datakvalitetsstatus. Samma indata ska alltid ge samma resultat.

### 4.1 Nattlig återhämtning
- Beräknas separat från kroppsbatteriet.
- Bygger på sömn, nattlig HRV och nattlig puls.
- Jämförs med personliga baslinjer byggda av jämförbara historiska perioder.
- Nattlig pulsbaslinje hålls separat från vanlig vilopuls.
- Kräv tillräckligt antal giltiga dagar/nätter innan personlig jämförelse.
- Begränsa poängtak och golv så att en enskild komponent inte maskerar avvikelse i en annan.
- Visa komponentpoäng och varför resultatet blev högt/lågt.
- Om centrala signaler saknas eller underlaget är otillräckligt: visa inget totalvärde.

### 4.2 Kroppsbatteri
- Startar från nattlig återhämtning vid uppvaknande.
- Uppdateras under dagen med tidsstämplad puls, aktiv energi och sammanhängande viloperioder.
- Hantera saknade pulsgap som okänd belastning, inte som vila.
- Undvik dubbelräkning av överlappande energisampel från flera källor.
- Redovisa täckning, belastningsbidrag och återhämtningsbidrag.
- Kalibrera koefficienter med testfall och verkliga observationer; ändra inte vikter enbart för att få önskad visuell kurva.

### 4.3 Stressindikator
Apple HealthKit tillhandahåller inte ett generellt direkt stressmått. VITAL ska därför kalla detta **stressindikator** eller **uppskattad fysiologisk belastning**, inte uppmätt stress.

Första tekniska versionen ska utvärdera:
- HRV-avvikelse från personlig baslinje,
- puls/vilopulsavvikelse från personlig baslinje,
- andningsfrekvens jämfört med personlig baslinje när tillräckliga data finns,
- sömn/återhämtning som kontext,
- aktivitet och träningspass som kontext så normal träningspuls inte feltolkas som negativ stress.

Regler:
- Jämför endast kompatibla mätfönster och tidsperioder.
- Separera aktiv belastning från viloperioder.
- Kräva tillräcklig personlig baslinje och mättäckning.
- Visa låg/ökad/hög indikator endast när underlaget räcker; annars neutral status med orsak.
- Ingen poäng eller klassificering får presenteras som kliniskt validerad.
- Stressindikatorn får inte härledas från HRV ensamt och får inte dubbleräkna samma pulsdata som kroppsbatteriet utan dokumenterad viktning.
- Börja med transparent regelbaserad modell. Maskininlärning ingår inte i första versionen.

## 5. Personliga baslinjer
- Rullande historik med tydlig period och antal giltiga dagar.
- Median och robust spridningsmått prioriteras framför känsligt medelvärde.
- Minimikrav på täckning dokumenteras per signal.
- Nya användare får ett tydligt insamlingsläge i stället för falsk precision.
- Baslinjer får inte blanda nattliga och dagliga värden eller olika enheter.
- Hantera tidszon, sommar-/vintertid och dygnsgränser explicit.

## 6. Datakvalitet och felhantering
Alla beräkningsresultat ska kunna förklara:
- vilka indata som användes,
- vilket tidsfönster som användes,
- vilka data som saknades,
- antal giltiga sampel och täckning,
- vilken baslinje och version av modell som användes.

Ogiltiga, oändliga, negativa eller orimliga värden ska filtreras. Luckor får aldrig fyllas med noll eller uppskattade värden utan uttrycklig, testad modellregel.

## 7. Arkitektur
- SwiftUI ansvarar för presentation och användarinteraktion.
- HealthKitStore ansvarar för behörighet, frågor, normalisering och diagnostik.
- Fristående kalkylatorer ansvarar för återhämtning, kroppsbatteri, stress, sömnkvalitet och baslinjer.
- Snapshot/Health domain models innehåller normaliserad data och beräkningsresultat.
- Persistence ansvarar endast för data som behövs av aktiva funktioner och kompatibilitet.
- Notiser får endast baseras på verkliga, tillgängliga resultat och ska vara separat från beräkningslogiken.
- UI får inte innehålla egen hälsomatematik.

## 8. Teststrategi

### Enhetstester
- Normala, höga och låga värden.
- Saknade värden och otillräcklig täckning.
- Orimliga värden och felaktiga enheter.
- Dubbletter och överlappande intervall.
- Långa pulsgap och glesa sampel.
- Tidszon, midnatt och sommar-/vintertid.
- Personlig baslinje med få/många giltiga dagar.
- Stress under vila kontra under träning.
- Reproducerbarhet och modellgränser.
- Regressionstester för befintliga HealthKit-frågor.

### Integration och enhet
- HealthKit-auktorisering.
- Faktisk hämtning och senaste tidsstämpel per kärnmått.
- Nattvärden bundna till vald huvudsömn.
- Uppdatering när nya HealthKit-data tillkommer.
- Appen fungerar när vissa datatyper saknas.
- iPhone-test av längre tids användning och bakgrunds-/förgrundsuppdatering.

CI/simulator kan verifiera kompilering och logik men ersätter inte HealthKit-test på fysisk iPhone.

## 9. Genomförandeordning

1. Frys denna omfattning och dokumentera beslutet.
2. Inventera alla referenser till vikt, kroppssammansättning, läkemedel, journaler, påminnelser och relaterade HealthKit-typer.
3. Ta bort dessa funktioner säkert, med tester och utan att skada kvarvarande hälsodata.
4. Stabiliserera HealthKit-kärnan och datakvalitetsdiagnostiken.
5. Granska och testa återhämtningsmodellen.
6. Granska och testa kroppsbatteriets belastnings- och återhämtningskurva.
7. Implementera stressindikator med transparent modell och egna tester.
8. Säkerställ baslinjer, tidsfönster och trendberäkningar.
9. Kör full CI och fysisk iPhone-verifiering.
10. När tekniken är godkänd: genomför samlad visuell designfas.

## 10. Definition av tekniskt färdig
Teknikfasen är inte klar förrän:
- borttagna funktioner saknar aktiva UI-, data-, notis- och HealthKit-referenser,
- kärnmåtten har fungerande HealthKit-frågor och tydliga fel-/tomtillstånd,
- återhämtning, kroppsbatteri och stress har dokumenterade modeller och regressionstester,
- baslinjer och tidsfönster är verifierade,
- samtliga CI-tester och byggen passerar,
- fysisk iPhone-testning har verifierat faktisk datainläsning och stabilitet,
- kända begränsningar är dokumenterade.

Först därefter betraktas VITALs tekniska grund som låst för den visuella slutbearbetningen.
