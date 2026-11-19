# HealthKit metric mapping — VITAL 3.0

Implementation commit: `62a14c7246cf81643d537f9e4a6394688ae5d612`

The HealthKit types below are now requested, queried, stored in `HealthSnapshot`, and presented in the Hälsa view.

| HealthKit type | Query window | Unit in VITAL | Presentation |
|---|---|---|---|
| `appleExerciseTime` | Current local day, cumulative | minutes | Träningstid idag |
| `distanceWalkingRunning` | Current local day, cumulative | km | Gång & löpning idag |
| `distanceCycling` | Current local day, cumulative | km | Cykling idag |
| `flightsClimbed` | Current local day, cumulative | count | Trappor idag |
| `walkingHeartRateAverage` | Latest sample | bpm | Gångpuls |
| `vo2Max` | Latest sample | mL/kg/min | VO₂ max |
| `bodyFatPercentage` | Latest sample | percent | Kroppsfett |
| `leanBodyMass` | Latest sample | kg | Fettfri massa |
| `walkingSpeed` | Latest sample | m/s | Gånghastighet |
| `walkingStepLength` | Latest sample | cm | Steglängd |
| `walkingAsymmetryPercentage` | Latest sample | percent | Gångasymmetri |

## Data integrity
- Missing samples remain unavailable and display as an em dash.
- Defensive value ranges prevent non-finite or clearly implausible values from being presented.
- Daily totals are explicitly labeled as today's values; latest-sample metrics are not described as real-time.
- Existing HealthKit diagnostics continue to count samples independently of the dashboard's display model.
- This is a code-level integration. Actual availability depends on supported hardware, iOS version, Health app sources and user privacy settings.

## Verification status
The commit adds unit coverage for metric formatting and defensive bounds. GitHub Actions must pass core tests and the iOS Simulator build before this mapping is considered CI-verified. Real HealthKit values still require testing on a physical iPhone.


## Additional metrics added 2026-11-19

| HealthKit type | VITAL unit | Display meaning |
|---|---|---|
| `oxygenSaturation` | percent | Latest oxygen saturation |
| `appleSleepingWristTemperature` | °C | Deviation from the user's personal wrist-temperature baseline; not core body temperature |

Both metrics are requested as optional read types, queried as latest samples, displayed in the respiratory section, and included in the 30-day diagnostics list. Missing values remain unavailable. Actual sample availability and units must still be confirmed on a supported physical Apple Watch/iPhone setup.


## Sample timestamps
All latest-sample metrics now retain their own HealthKit sample end date in `HealthSnapshot`. The Hälsa tiles show the local formatted sample date/time individually. This avoids implying that one metric's timestamp applies to neighboring metrics. A missing sample is explicitly labeled as unavailable; it is not assigned a synthetic timestamp.
