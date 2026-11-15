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

## Status
- [x] Ren beräkningsfunktion
- [x] Saknade värden och otillräcklig baslinje hanteras
- [x] Fem enhetstester
- [ ] Beräkna 30-dagarsbaslinje från HealthKit
- [ ] Definiera nattens sömnperiod och eliminera dubbelräkning
- [ ] Granska vikter mot verkliga data
- [ ] Koppla till UI efter verifiering
