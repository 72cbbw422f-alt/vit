# VITAL 3.0

VITAL is a SwiftUI health and recovery dashboard for iPhone, built around Apple Health / HealthKit.

## Project status
VITAL 3.0 starts from the last verified VITAL 2.2 (build 19) source baseline. The previous project is preserved in the separate private `VITAL-iOS` repository.

## Foundation
- SwiftUI dashboard with Midnight navy / lime visual system
- HealthKit read integration for steps, heart rate, resting heart rate, HRV, sleep, respiratory rate, wrist temperature, weight, blood pressure, active energy and exercise time
- Recovery and Body Battery estimates identified as VITAL estimates, not medical measurements
- Morning and evening Daily Report views with local snapshot history
- History, Training, Health and Settings tabs

## VITAL 3.0 engineering priorities
1. Coordinate HealthKit refresh with explicit completion and per-type diagnostics.
2. Distinguish unsupported types, query errors and empty result sets without claiming to know denied read permission.
3. Validate metric mappings, units, dates and sample freshness.
4. Capture immutable morning snapshots only after the intended refresh completes.
5. Keep overnight recovery separate from dynamic daytime Body Battery.
6. Build and verify after each isolated change before producing a test IPA.

## Build
GitHub Actions builds the iOS app using Xcode on macOS. The build is unsigned (`CODE_SIGNING_ALLOWED=NO`) and produces an IPA artifact for the established sideloading/signing workflow.

## Important
This app is informational and is not a medical device. HealthKit data availability depends on the device, data sources and user privacy settings. HealthKit does not reveal whether a missing read result is caused by denied permission or simply absent samples.
