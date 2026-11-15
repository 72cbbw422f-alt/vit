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
