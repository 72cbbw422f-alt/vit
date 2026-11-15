# VITAL 3.0

Native iOS health and recovery app built with SwiftUI and HealthKit.

## Approved design
- Midnight Navy foundation
- Vital Teal: #70D9D1
- Soft Violet: #A9A0F5
- Warm Amber: #E9BD70
- Cloud White: #F1F4F8

## Product principles
- Swedish interface; read health information from Apple Health.
- No nutrition tracking.
- Separate overnight recovery from dynamic body energy.
- Morning report is a frozen snapshot and must not be rewritten during the day.
- Distinguish measured data, calculated estimates, and unavailable data.
- Never fabricate health values.

## Current foundation
Initial SwiftUI source, design tokens, four-tab navigation, dashboard layout, and read-only HealthKit data layer.

## Build status
The Xcode project file, target configuration, signing, and device build are still required before an installable IPA can be produced.

## Documentation

Project history, decisions, roadmap, architecture, and build/test status are maintained in `docs/`:

- [Project log](docs/PROJECT_LOG.md)
- [Decision log](docs/DECISIONS.md)
- [Roadmap](docs/ROADMAP.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Build and test log](docs/BUILD_AND_TEST_LOG.md)
- [Recovery model](docs/RECOVERY_MODEL.md)

Update the relevant documentation whenever code, design, behavior, requirements, or test status changes.
