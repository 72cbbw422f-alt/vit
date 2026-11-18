# VITAL 3.0 – Beslutslogg

Detta dokument innehåller beslut som styr produkt, design och teknik. Nya beslut läggs till med datum. Äldre beslut skrivs inte över utan markeras som ersatta när ett nytt beslut fattas.

## Produkt
- Native iOS-app med SwiftUI.
- HealthKit/Apple Hälsa används för att läsa relevanta hälsodata.
- Ingen kostregistrering eller näringsspårning.
- All användarsynlig text ska vara på svenska.
- Hälsodata ska presenteras med tydlig skillnad mellan mätning, beräkning och saknat underlag.

## Design
- Användarens tre skärmbilder från 2026-11-15 är huvudreferens.
- Mörk marinblå grund, inte helsvart.
- Diskreta kort med varierande visuell tyngd; inte varje liten uppgift ska få ett eget stort kort.
- Fyra huvudflikar: Idag, Insikter, Aktivitet, Hälsa.
- Färgpalett:
  - Midnight Navy #111C2D
  - Vital Teal #70D9D1
  - Soft Violet #A9A0F5
  - Warm Amber #E9BD70
  - Cloud White #F1F4F8

## Hälsa och beräkningar
- Nattlig återhämtning är ett separat värde från dynamiskt kroppsbatteri.
- Morgonrapporten är en fryst snapshot och får inte uppdateras med data som tillkommer senare samma dag.
- Inga poäng eller diagnosliknande bedömningar får visas innan beräkningsmodell och datakvalitet är definierade.
- Saknade data ska visas som saknade, inte ersättas med exempelvärden.

## Utvecklingsprocess
- Utveckla på grenen `vital-3.0`.
- Behåll `main` orörd tills grundfunktioner och byggen är verifierade.
- Dokumentera varje större ändring, test, fel och beslut i `docs/`.
- En IPA får inte beskrivas som färdig förrän en faktisk signerad byggfil har skapats och verifierats.


## Datakvalitet – nattliga värden
- Återhämtningsmotorn får inte använda senaste tillgängliga HRV- eller vilopulsvärde som om det automatiskt vore ett nattvärde.
- Nattliga mätvärden måste kopplas till en explicit sömnperiod med tidsstämplar.
- Om relevant nattligt underlag saknas ska värdet vara saknat; dagvärden får inte användas som tyst reserv.
- HealthKit:s semantik och tidsstämplar ska verifieras innan urvalsmodellen kopplas in i produktionsflödet.


## Nattdata – HealthKit-integration
- Senaste HRV och vilopuls kan visas som översiktsvärden men får inte automatiskt användas som nattliga återhämtningsvärden.
- Återhämtningsmotorn får endast värden vars HealthKit-tidsstämpel ligger inom den valda sömnperioden.
- Om HealthKit inte lämnar sampel inom sömnperioden visas ingen återhämtningspoäng.
- Valet av huvudsömnperiod ska kvalitetssäkras separat så att tupplurar inte felaktigt ersätter nattsömnen.

## Sömnperiod – val av huvudsömn (2026-11-15)
- För nattlig återhämtning väljs den längsta grupperade sömnperioden i det hämtade 36-timmarsfönstret. Vid lika längd väljs den senast avslutade perioden.
- Detta minskar risken att en kortare tupplur ersätter huvudsömnen. Det är en dokumenterad heuristik, inte en universell regel; den ska verifieras med användarens faktiska HealthKit-data och får inte beskrivas som säker sömnstegsdetektion.


## Kroppsbatteri – första modellsteg (2026-11-15)
- Kroppsbatteriet är en separat modell från nattens återhämtning.
- Första prototypen startar från nattens återhämtningspoäng och drar av belastning från tidsstämplad puls över personlig vilopuls samt aktiv energi.
- Pulssampel får endast integreras över tidsluckor på högst 15 minuter. Minst tre sampel och minst 30 minuters täckning krävs.
- Otillräckliga eller saknade underlag ska ge saknat värde, aldrig ett påhittat standardvärde.
- Prototypen laddar ännu inte upp under vila. Återladdningsmodell och koefficienter måste valideras mot verkliga data innan produktionsstatus.


## Kroppsbatteri – HealthKit och dashboard (2026-11-15)
- Kroppsbatteriet använder pulssampel (`heartRate`) och aktiv energi (`activeEnergyBurned`) från HealthKit.
- Endast sampel inom perioden från vald sömns uppvakningstid till beräkningstid får påverka dagens batteri.
- Startvärdet är nattens separata återhämtningspoäng; personlig vilopulsbaslinje används som referens för pulsbelastning.
- Resultatet visas inte om nattens återhämtning, vilopulsbaslinje eller tillräcklig pulstäckning saknas.
- UI ska visa att detta är en preliminär wellness-uppskattning och inte medicinskt mått.

## 2026-11-15 – Oföränderlig dagsrapport
- Morgon- och kvällsrapporter lagras som separata snapshot-poster.
- En snapshot är unik per lokal kalenderdag och rapporttyp.
- Den första sparade posten vinner; senare data får inte skriva om rapportens historiska innehåll.
- Rapporten ska innehålla både fångsttid och lokal rapportdag.
- Schemaläggning får inte lova exakt bakgrundskörning vid 07:00/21:00. Rapportskapande och användarnotis måste hållas isär.


## 2026-11-15 – Händelsestyrd morgonrapport och tidsstyrd kvällsrapport
- Morgonrapporten ska inte ha en fast klocktid. Den utlöses när användarens Sömnfokus stängs av efter nattens huvudsömn.
- Sömnfokus-av är en signal att starta rapportflödet, inte ett bevis på att alla HealthKit-sampel redan är tillgängliga.
- Efter signalen ska VITAL uppdatera/inhämta nattens relevanta HealthKit-data, kontrollera att sömnperioden är avslutad och skapa en fryst morgonsnapshot när datan är tillräcklig.
- Om data saknas eller fortfarande är ofullständiga ska VITAL inte hitta på värden. Rapporten kan visa saknade värden och uppdateras endast innan den slutliga snapshoten har låsts; när den väl är låst får den inte skrivas om.
- Dubblettsignaler från Fokus eller appstart får inte skapa flera morgonrapporter samma lokala dag.
- Kvällsrapporten skapas enligt en fast, användarinställbar lokal tid, med 21:00 som standardförslag.
- iOS kan begränsa bakgrundskörning. VITAL måste därför kunna slutföra rapportflödet när appen får körningstid och får inte utlova exakt körning vid en viss sekund.


## 2026-11-15 – Teknisk utlösningspolicy för morgonrapport
- Sömnfokus-av behandlas som en av flera möjliga signaler, inte som en garanterad systemhändelse i bakgrunden.
- HealthKit-sömnuppdatering och appens återgång till aktivt läge är reservsignaler som kan starta samma idempotenta kontroll.
- En signal får endast godkännas när vald huvudsömn är avslutad, minst tre timmar lång, högst 18 timmar gammal och tillhör rapportens lokala uppvakningsdag.
- Tre timmar och 18 timmar är initiala produkttrösklar som ska kunna omprövas efter test med verkliga sömnmönster.
- Rapportarkivets unika nyckel per lokal dag och rapporttyp är sista skyddet mot dubbletter.


## 2026-11-15 – Kvällsrapportens faktiska fångsttid
- Kvällsrapportens standardgräns är kl. 21:00 lokal tid.
- VITAL skapar den frysta snapshoten vid första lyckade HealthKit-uppdateringen från kl. 21:00 och framåt, inte genom att anta att iOS kör appen exakt 21:00.
- En daglig lokal notis påminner kl. 21:00 om att öppna VITAL. Notisen är en påminnelse, inte en garanti för bakgrundskörning eller rapportskapande.
- När appen återgår till förgrunden uppdateras HealthKit och rapportflödet kontrolleras igen.
- Fångsttiden som visas är den faktiska tidpunkten då VITAL skapade rapporten.


## 2026-11-15 – Väntetid före låsning av morgonrapport
- En godkänd morgonrapportsignal får inte omedelbart låsa rapporten. VITAL väntar minst 20 minuter från huvudsömnens sluttid innan snapshot får skapas.
- Väntetiden är en försiktighetsåtgärd för att ge HealthKit tid att leverera fördröjda nattliga sampel; den är ingen garanti för fullständiga data.
- Om appen inte får körningstid när väntetiden passerar skapas rapporten vid nästa HealthKit-uppdatering eller när appen blir aktiv.
- När väntetiden passerat får fortfarande saknade mätvärden vara nil. Rapporten låses då med tillgängliga värden och skrivs aldrig om.
- 20 minuter är en initial produktheuristik som ska utvärderas mot verklig synkronisering på fysisk iPhone.


## 2026-11-15 – Synlig status för HealthKit-bakgrundsleverans
- VITAL ska inte anta att HealthKit-bakgrundsleverans är aktiverad bara för att en observerfråga har registrerats.
- Resultatet från enableBackgroundDelivery sparas som status i HealthKitStore. Fel eller nekad aktivering exponeras via appens felstatus.
- Bakgrundsleverans är fortfarande beroende av entitlement, signering/provisionering och iOS schemaläggning; den är inte en garanti för omedelbar körning.


## 2026-11-15 – Separat hantering av notisbehörighet
- VITAL ska först läsa iOS aktuella notisbehörighet. Behörighet begärs endast när status är notDetermined; en nekad behörighet ska inte utlösa upprepade systemfrågor.
- Om användaren nekat notiser visas status i appen och den dagliga kvällspåminnelsen tas bort från väntande notiser.
- Appen visar separat status för kvällspåminnelsen och HealthKit-bakgrundsleverans så att dessa inte blandas ihop.

## 2026-11-15 – Stabil rapportdag vid tidszonsändring
- En fryst rapport behåller den lokala kalenderdag och tidszon som gällde när rapporten skapades.
- Arkivet använder en sparad `yyyy-MM-dd`-nyckel för dubblettskydd och uppslagning; historiska rapporter ska inte flyttas när användaren reser eller ändrar tidszon.
- Äldre arkiv ska kunna avkodas utan de nya fälten. Sådana poster använder kompatibel reservlogik.
- Sommar-/vintertid hanteras som kalenderdagar, inte genom antaganden om att varje dygn är 24 timmar.


## 2026-11-15 – VITAL som samlad hälso- och behandlingsdagbok
- Produktens omfattning breddas från en ren återhämtningsapp till en samlad personlig hälsoöversikt.
- VITAL ska samla Apple Hälsa-data, sömn/återhämtning, aktivitet, viktutveckling och läkemedelsuppföljning i en sammanhängande upplevelse.
- Wegovy/semaglutid får en egen läkemedelsmodul med doshistorik, nästa dos och påminnelser, registrering av upplevda biverkningar, viktkurva och tydlig förändring från vald startvikt.
- Beräknad läkemedelsnivå får endast visas som en teoretisk farmakokinetisk uppskattning baserad på registrerade doser och tidpunkter; den får aldrig beskrivas som uppmätt blodnivå eller användas för dosråd.
- Läkemedelsmodulen ska inte rekommendera ändrad dos, tidigarelagd dos eller kompensation för missad dos. Sådana frågor hänvisas till ordination och vården.
- HealthKit-behörigheter ska breddas stegvis efter funktion: begär endast datatyper som VITAL faktiskt använder och förklara nyttan före systemdialogen.
- VITAL ska fortsatt skilja mellan Apple Hälsa-data, manuellt registrerade uppgifter, beräknade uppskattningar och saknade värden.
- Ingen fullständig kost- eller kaloriregistrering ingår i detta beslut; fokus är hälsa, behandling, viktutveckling och återhämtning.


## 2026-11-17 – Förtydligande: aktuell återhämtning kontra fryst historik
- Dashboardens återhämtningskort ska använda den aktuella `HealthSnapshot.recoveryResult` som räknas från tillgängliga nattvärden och personliga baslinjer.
- Den frysta morgonrapporten är en historisk snapshotmodell. Den får inte förväxlas med dashboardens levande status eller uppdateras i efterhand.
- Kvällsrapportens aktiva flöde är avvecklat; äldre arkivposter bevaras endast för bakåtkompatibilitet.
- Midnight Navy och den etablerade paletten gäller fortsatt. Designsystemets färgtoken får inte bytas ut utan ett uttryckligt nytt designbeslut.
- Designriktningen är fastställd, men färdig designstatus kräver visuell granskning av samtliga fyra flikar och deras tom-, laddnings-, fel- och datatillstånd.


## 2026-11-17 – Avveckling av automatisk morgonrapport
- Ingen ny fryst morgonrapport ska skapas automatiskt i bakgrunden.
- Startsidan använder aktuell nattlig återhämtning från HealthKit-snapshoten och uppdateras när ny data hämtas.
- Äldre rapportarkiv och Codable-modeller bevaras för bakåtkompatibilitet, men ska inte längre få nya poster eller styra startsidans innehåll.
- Kvällsrapportflödet är fortsatt avvecklat.


## 2026-11-18 — VITAL 3.0 visual direction

- The approved app icon is the dark glass tile with lime circular ring and heart/ECG mark supplied by the user.
- The approved dashboard reference is the premium Midnight interface: near-black/navy foundation, luminous lime as the primary accent, restrained violet for sleep-related visualization, layered wave forms, rounded glass-like panels, and a prominent body-battery visualization.
- Existing HealthKit data flow, recovery calculations, body-battery model, frozen morning/evening report snapshots, and report history must be preserved while the interface is progressively restyled.
- The first implementation step aligns the shared design-system surfaces and primary accent with the approved Midnight/lime palette. The existing dashboard structure is not yet a pixel-level match to the reference; further visual work is planned incrementally.
- Navigation changes must preserve existing destinations. The first tab is named “Översikt”; activity and health destinations remain until their functionality is deliberately consolidated or replaced.


## 2026-11-18 — Shared Midnight surfaces
- Shared `VITALCard` surfaces use a restrained navy gradient, fine light edge and soft shadow to carry the approved glass-like visual language across Insights, Activity and Health.
- The tab bar uses the same Midnight background and lime selection tint.
- Existing destinations and their data/entry workflows remain in place; the visual redesign must not hide or remove them.


## 2026-11-18 — Hälsa: informationshierarki i Midnight

- Hälsa-fliken grupperar innehållet i fem tydliga områden: Hälsoöversikt, Hjärta & kärl, Andning, Kropp & utveckling samt Vardag.
- Hälsoöversikten lyfter vilopuls, HRV och senaste huvudsömn som de tre centrala orienteringsvärdena. Den ersätter inte detaljsektionerna längre ned.
- Blodtryck ligger under Hjärta & kärl; vikt och framstegsbilder under Kropp & utveckling; vätskespårning och sömn under Vardag.
- Sektionerna använder små typografiska rubriker i lime i stället för att ge varje del ett lika tungt stort kort. Det ger tydligare skanning och en lugnare visuell rytm.
- Omstruktureringen är en presentationsändring. HealthKit-källor, lokala journaler, redigering, påminnelser och historik ska bevaras.
- Saknade värden ska fortsatt visas som saknade. Senaste mätningens tidsstämpel och upplysningen om att HealthKit-värden inte nödvändigtvis är realtid ska finnas kvar.


## 2026-11-18 — Personlig coach på Översikt
- Ett coachkort placeras direkt efter nattens återhämtningssammanfattning på Översikt.
- Texten varierar deterministiskt mellan flera formuleringar och baseras på aktuellt återhämtningsestimat samt användarens dagliga måendenotering.
- Coachens rekommendationer är försiktiga wellness-reflektioner, inte medicinska råd eller träningsordinationer.
- När återhämtningsvärden saknas ska coachen uttryckligen säga att underlaget är otillräckligt; saknade värden får aldrig beskrivas som positiva eller negativa.
- Användarens upplevda mående ska väga tyngre än en positiv mätpoäng när de två signalerna skiljer sig åt.
- Wegovy/semaglutids uppskattade läkemedelsnivå planeras som en separat funktion under Hälsa → Läkemedel. Beräkningen ska summera kvarvarande bidrag från registrerade doser med en dokumenterad farmakokinetisk modell och får inte ge dosråd.


## 2026-11-18 — Förbättrad läsbarhet
- Appens textstorlek får en större grundnivå och stöd för större dynamiska textstorlekar (Large till xxxLarge) utan att låsa användaren till en enda storlek.
- Dashboardens fasta typografiska storlekar höjs med cirka 15 procent för bättre läsbarhet.
- Kontrollera radbrytningar, kort och diagram i samtliga flikar vid simulatorgranskning; undvik att text kapas vid större systemstorlek.


## 2026-11-18 — Andra läsbarhetsrundan
- Höj även små etiketter och detaljtexter i Hälsa-vyerna; undvik fasta textstorlekar under 12 pt i dessa vyer.
- Låt systemfontens storlekar följa Dynamic Type via relativa SwiftUI-fontstorlekar, med stöd för större textinställningar.
- Granska omflöde och kortens höjd när texten förstoras; innehåll ska kunna växa vertikalt och får inte kapas.
- Behåll färger, kortstil, informationshierarki och etablerad Midnight-design.
