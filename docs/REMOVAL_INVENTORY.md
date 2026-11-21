# VITAL 3.0 – Inventering inför renodling

Datum: 2026-11-21
Gren: `vital-3.0`

Detta är en kodinventering baserad på filinnehållet i aktuell gren. Den är inte ett påstående om att borttagningen är genomförd.

## Bekräftade träffar

### `VITAL/Views/RootView.swift`
- `HealthOverviewView` äger `WeightJournal`, `SemaglutideJournal` och `ProgressPhotoJournal`.
- Hälsavyn innehåller viktkort, kroppssammansättning, progressbilder och läkemedelskort.
- Läkemedelsflödet innehåller dosregistrering, biverkningslogg, dospåminnelse och beräkning via `SemaglutideLevelModel`.
- Viktflödet innehåller lokal historik, målvikt, redigering och diagram.
- Progressbilder har egen lokal filkatalog `VITALProgressPhotos` och journalnyckel `vital.progressPhotos.v1`.
- Läkemedelsdata ligger i UserDefaults under `vital.medication.doses.v1`, `vital.medication.effects.v1` och `vital.medication.reminder.v1`. Påminnelsen använder notisidentifieraren `vital.medication.nextDose`.
- Viktdata ligger under `vital.weight.journal.v1` och målvikt under `vital.weight.target.v1`.

### `VITAL/Health/HealthKitStore.swift`
- Behörighetsmängden kräver i nuläget `bodyMass` som en grundtyp tillsammans med sömn, puls, HRV, steg och aktiv energi. Det måste tas bort ur grundkravet.
- Ytterligare läsbehörigheter innehåller `bodyFatPercentage` och `leanBodyMass`.
- Refresh hämtar senaste vikt, historisk vikt, kroppsfett och fettfri massa.
- Datadiagnostiken innehåller rader för Vikt, Kroppsfett och Muskelmassa.
- `weightHistory` och `historicalWeightSamples()` är viktberoenden som ska avvecklas.
- Övriga rörelsevärden (gånghastighet, steglängd, asymmetri, VO₂ max m.fl.) är inte vikt-/läkemedelsfunktioner i sig. De ska bedömas mot den beslutade kärnomfattningen innan de tas bort.

### `VITAL/Models/HealthSnapshot.swift`
- Snapshoten innehåller `latestWeight`, `latestWeightDate`, `bodyFatPercentage`, `bodyFatDate`, `leanBodyMassKG` och tillhörande textformattering.
- Dessa fält och formatters har beroenden i HealthKitStore och Health-vyn.
- Legacy-rapporttyper finns kvar för bakåtkompatibilitet enligt tidigare beslut och ska inte blandas ihop med aktiv vikt-/läkemedelsfunktionalitet.

### `VITAL/Info.plist`
- HealthKit-användningstexten nämner i nuläget vikt och kroppssammansättning. Den behöver uppdateras när HealthKit-scope har rensats.

### `VITAL.xcodeproj/project.pbxproj`
- Projektet använder explicit filreferenser och build phases. Nya Swift-filer måste registreras manuellt om projektet fortsätter använda denna projektstruktur.

## Risker och ordning för borttagning

1. Ta bort vikt-, läkemedels- och progressbildssektionerna från `HealthOverviewView`, inklusive sheets och state.
2. Avveckla journalmodeller och lokala lagrings-/notisflöden. Bevara befintliga lagrade poster tills separat migreringsbeslut; stoppa aktiv inläsning och användning.
3. Rensa HealthKitStore:s vikt- och kroppssammansättningsfrågor, historik, diagnosrader och beroenden.
4. Rensa HealthSnapshot-fält och formatters när alla aktiva referenser är borta.
5. Uppdatera HealthKit purpose string och behörighetsmängd till enbart kärnbehov.
6. Lägg regressionstester som säkerställer att puls, HRV, sömn, blodtryck, andning, temperatur och aktivitet inte påverkas.
7. Sök igenom hela repot efter identifierare och lagringsnycklar innan commit.

## Ej verifierat
- Komplett repo-wide sökning: GitHub-anslutningen i denna arbetsyta gav filhämtning men inget fungerande kodsöknings-/trädlistningsgränssnitt. Inventeringen ovan är därför begränsad till direkt hämtade filer.
- Bygg/test: inte kört i denna inventeringsinsats.
- Fysisk iPhone: inte testad i denna insats.
