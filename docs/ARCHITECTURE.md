# VITAL 3.0 – Teknisk arkitektur

## Nuvarande struktur

```
VITAL/
  App/
    VITALApp.swift
  Design/
    VITALDesignSystem.swift
  Health/
    HealthKitStore.swift
  Models/
    HealthSnapshot.swift
  Views/
    RootView.swift
    DashboardView.swift
  Info.plist
  VITAL.entitlements
VITAL.xcodeproj/
  project.pbxproj
docs/
  PROJECT_LOG.md
  DECISIONS.md
  ROADMAP.md
  BUILD_AND_TEST_LOG.md
  ARCHITECTURE.md
```

## Ansvar
- `VITALApp`: SwiftUI-appens startpunkt och delning av HealthKitStore.
- `VITALDesignSystem`: färgtoken, spacing och gemensamma kort.
- `HealthKitStore`: begär read-only-behörighet och hämtar hälsodata.
- `HealthSnapshot`: sammanhållen ögonblicksbild av senast hämtade mätvärden.
- `RootView`: fyra huvudflikar.
- `DashboardView`: dagens hälsostatus och översikt.

## HealthKit-data i första implementationen
- Sömnanalys
- Vilopuls
- HRV SDNN
- Steg
- Aktiv energi
- Kroppsvikt

Blodtryck, träningspass, andningsfrekvens, syremättnad och andra datatyper är ännu inte inkopplade i första kodsteget.

## Arkitekturprinciper framåt
- Håll datainsamling, beräkningar och presentation separerade.
- Beräkningar ska vara testbara utan HealthKit.
- Använd en tidsstämplad snapshot för morgonrapporten.
- Håll kroppsbatteriets löpande tillstånd separat från nattlig återhämtning.
- Låt UI visa datakälla, tidsstämpel och datatillgänglighet.
- Ge inte UI ansvar för att hitta på eller uppskatta saknade mätvärden.


## CI och Xcode-projekt
- Delad scheme finns i `VITAL.xcodeproj/xcshareddata/xcschemes/VITAL.xcscheme`.
- GitHub Actions-workflow finns i `.github/workflows/ios-build.yml`.
- Workflow kör på macOS och bygger appmålet mot iOS Simulator med kodsignering avstängd.
- Denna CI-build verifierar kompilering och projektkonfiguration, inte HealthKit-funktionalitet på en fysisk enhet.


## Fristående beräkningskärna
- `VITAL/Models/RecoveryEngine.swift` innehåller den rena återhämtningsfunktionen utan beroende till HealthKit eller SwiftUI.
- `Package.swift` exponerar modellen som Swift Package så att den kan testas separat.
- `Tests/VITALCoreTests/RecoveryEngineTests.swift` innehåller tester för baslinjekrav, saknade värden, normalisering och begränsning av komponentpoäng.
- Modellen är ännu inte kopplad till HealthKitStore eller dashboarden. Det är avsiktligt tills baslinje- och sömnperiodslogiken är implementerad och verifierad.


## Sömnperiodsberäkning
- `VITAL/Models/SleepSessionCalculator.swift` slår ihop överlappande sömnintervall och grupperar sammanhängande segment.
- `HealthKitStore.latestSleepDuration()` läser sömnsegment från de senaste 36 timmarna och skickar endast sömnklassade intervall till kalkylatorn.
- Första prototypen grupperar segment med högst 90 minuters mellanrum. Tröskeln är konfigurerbar och ska valideras mot verkliga data.
