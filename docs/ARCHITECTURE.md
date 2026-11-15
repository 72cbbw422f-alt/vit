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
