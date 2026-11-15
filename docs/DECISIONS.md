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
