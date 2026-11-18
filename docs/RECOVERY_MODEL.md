# VITAL 3.0 – Modell för nattlig återhämtning

## Syfte
Transparent wellness-uppskattning, inte medicinskt mått, diagnos eller kliniskt validerad modell. Poängen ska inte visas som färdig funktion innan modellen granskats.

## Indata
- Senaste avslutade sömnperiodens varaktighet.
- Personlig median för sömnvaraktighet under föregående 30 dagar.
- Senaste nattens HRV SDNN i millisekunder.
- Personlig HRV-baslinje från föregående 30 dagar.
- Vilopuls och personlig vilopulsbaslinje från föregående 30 dagar.
- Antal giltiga dagar i baslinjeunderlaget.

Baslinjen ska vara personlig; populationsvärden får inte användas.

## Baslinjekrav
- Rullande 30 dagar före aktuell natt.
- Minst 14 giltiga dagar krävs i första prototypen.
- Otillräckligt underlag eller saknade mätvärden ger ingen poäng.

## Prototypens komponenter
Alla komponenter begränsas till 0–100:
- Sömn: min(sömn / personlig sömnmedian × 100, 100)
- HRV: clamp(100 + (aktuell HRV / personlig HRV-baslinje − 1) × 100, 0, 100)
- Vilopuls: clamp(100 − (aktuell vilopuls − personlig vilopulsbaslinje) × 5, 0, 100)

Viktning:
- Sömn 40 %
- HRV 35 %
- Vilopuls 25 %

Slutpoängen avrundas till heltal.

## Begränsningar
- Vikter och skalningar är en teknisk prototyp, inte medicinskt validerade gränser.
- Sömnmedian är personlig referens, inte medicinsk rekommendation.
- HRV och vilopuls påverkas av många faktorer och ska inte användas diagnostiskt.
- Överlappande sömnsegment måste hanteras innan HealthKit-koppling.
- Modellen får inte ensam ge medicinska råd eller träningsinstruktioner.

## Integrationsstatus och databegränsningar
- Dashboarden använder det lägsta antalet giltiga dagar bland sömn, HRV och vilopuls. Alla tre baslinjer måste nå 14 dagar.
- Nuvarande HealthKit-läsare använder senaste tillgängliga HRV- och vilopulsvärde, inte en verifierad nattlig mätning med gemensam tidsstämpel. Det måste förbättras innan poängen betraktas som en stabil nattlig bedömning.
- Sömnvärdet är den senaste grupperade sömnperioden inom ett 36-timmarsfönster. Tupplurar kan fortfarande påverka valet och ska verifieras mot verkliga data.
- Poängen visas som prototyp och ska inte tolkas som medicinskt mått eller kliniskt validerad återhämtning.

## Status
- [x] Ren beräkningsfunktion
- [x] Saknade värden och otillräcklig baslinje hanteras
- [x] Fem enhetstester
- [x] Beräkna 30-dagarsbaslinje från HealthKit
- [ ] Definiera nattens sömnperiod och eliminera dubbelräkning
- [ ] Granska vikter mot verkliga data
- [x] Koppla prototypen till dashboarden med tydlig varning om att den inte är medicinskt validerad

## Uppdatering – val av huvudsömn
- HealthKitStore använder nu längsta grupperade sömnperioden som huvudsömn, med senast avslutade period som tie-breaker.
- Syftet är att inte låta en kortare senare tupplur ersätta huvudsömnen.
- Heuristiken är inte kliniskt validerad och kan vara fel vid skiftarbete eller atypiska sömnmönster. Verklig HealthKit-verifiering krävs.


## Uppdatering 2026-11-17 – Fryst morgonsammanfattning och signalbaserad vägledning
- Morgonsammanfattningen sparar komponentpoängen för sömn, HRV och vilopuls tillsammans med totalpoängen. Fälten är valfria vid avkodning så äldre lokala arkiv fortsätter fungera.
- Startsidan läser poäng, nattvärden och vägledning från den frysta morgonsammanfattningen. Senare HealthKit-uppdateringar under dagen får inte skriva om sammanfattningen.
- Vägledningen pekar ut vilka komponenter som avviker från den personliga referensen. En komponentpoäng under 85 markeras som en uppmärksamhetssignal. Detta är en preliminär produktheuristik, inte en medicinsk gräns eller validerad träningsregel.
- Om data saknas visas ett neutralt vänteläge; inga avvikelsesignaler eller rekommendationer konstrueras från saknade värden.
- Kvällsrapporten fångas vid första lyckade HealthKit-uppdateringen från lokal tid 21.00. Den sparar dagens steg, aktiva kalorier och kroppsbatteri som en oföränderlig ögonblicksbild.
- Kvällsrapporten återanvänder inte nattens återhämtningspoäng eller dess sömn-/HRV-/vilopulskomponenter. Dessa hör till morgonrapporten. Kvällsrapportens fokus är dagens belastning och kroppsbatteri.
- iOS garanterar inte körning exakt 21.00. Rapporten skapas därför vid första uppdateringen efter tidsgränsen; om appen inte får en uppdatering den kvällen kan rapporten utebli eller fångas senare.
