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
