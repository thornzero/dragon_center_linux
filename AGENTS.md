# Agent Guidelines for Dragon Center Linux

This document is the canonical guide for agentic contributors working in this repository. Follow it carefully to keep builds stable, follow styles, and deploy updates safely.

## 1. Build, Lint & Test Commands

### Build
- **Linux debug run:** `flutter run -d linux`
- **Linux release bundle:** `flutter build linux`
- **Generate any build artifacts (codegen):** `dart run build_runner build --delete-conflicting-outputs`

### Analysis & Linting
- **Static analysis:** `flutter analyze`
- **Apply fixes:** `dart fix --apply`
- **Ensure the analyzer config (analysis_options.yaml) stays aligned with flutter_lints. Do not disable lints globally unless absolutely necessary.`

### Testing
- **Run all tests:** `flutter test`
- **Run the widget smoke test:** `flutter test test/widget_test.dart`
- **Run a single test by name:** `flutter test --plain-name "Description"`
- **Targeting a directory:** `flutter test test/features/fan_control` (if more targeted suites exist in future)

## 2. Code Style & Conventions

### General Dart/Flutter
- Dart formatting (2-space indentation) is enforced—run `dart format` when uncertain.
- Prefer trailing commas in widget constructors/layouts to trigger multi-line formatting automatically.
- Avoid unnecessary `!`; prefer nullable types with defensive checks.
- Keep method bodies short and descriptive; return early if validation fails.
- All top-level/public-facing interfaces should have doc comments when the behavior is non-obvious.

### Imports
- Use absolute package imports, e.g. `import 'package:dragon_center_linux/core/utils/logger.dart';`
- Imports should be grouped: Dart/Flutter SDK first, third-party packages next, local packages last.
- Within each group, order alphabetically.
- Avoid `relative` imports across large directory jumps unless the file shares a tight feature boundary.

### Naming
- **Classes:** PascalCase (e.g., `DragonControlProvider`).
- **Methods/variables:** camelCase (e.g., `loadConfig`, `fanAddresses`).
- **Private members:** prefixed with `_`.
- **Constants:** prefer `const`/`final` naming that describes their purpose; uppercase is acceptable for true constants but use lowerCamelCase for config constants stored in objects.

### Architecture & Organization
- `lib/features/` holds feature modules (fan_control, battery, etc.).
- `lib/core/` stores shared services, utils, and presentation layers.
- `lib/shared/` is for shared widgets, models, and helpers not tied to a single feature.
- `lib/models/` holds pure data/config models.
- Maintain separation between UI widgets, state (ViewModels), and services for hardware access.
- Use Provider for state management (see `DragonControlProvider`). Widgets should consume state via `Consumer`/`Provider.of` and not instantiate providers directly.

### Error Handling & Logging
- Wrap hardware/IO calls (`ECHelper`, file reads, platform channels) in `try/catch` and log failures with `logger.severe(...)`. Use `logger.warning` / `logger.info` for softer notices.
- Avoid swallowing exceptions; rethrow if the caller must react.
- Use `logger.fine` for verbose diagnostics when debugging hardware layers.
- Always include contextual info in logs (e.g., register address, model name).

### Async & Futures
- Prefer `async`/`await` over `.then()` chains for readability.
- Always declare `Future` return types explicitly (e.g., `Future<void>`).
- Cancel timers/streams in `dispose()` to avoid leaks (see `DragonControlProvider`).

### Models & Serialization
- Use `final` fields where possible to keep data immutable.
- Implement `toStorageString()`/`fromStorageString()` for shared_preferences serialization when needed (see `FanCurve`).
- Keep parsing logic defensive; `int.tryParse` and fallback defaults are preferred over letting exceptions bubble up.

## 3. Configuration & Runtime Behavior

### MSI Configuration
- The JSON config (`assets/config/config.json`) is authoritative for model parameters. Access it through `MSIConfig`. Do not hardcode register addresses.
- `FanConfig` should load defaults from `MSIConfig` to keep fan/address values model-aware.
- The `availableModels` getter filters out system sections; use it to populate UI dropdowns.

### Preferences & Persistence
- Saved settings live in `SharedPreferences`. Use helper functions in `FanConfig` and `ModelSelectionDialog` to read/write cleanly.
- Always call `FanConfig.loadConfig()` before referencing static fields to guarantee configuration is initialized.
- When updating the saved model or fan curves, persist the stringified values and reload configs so the runtime state reflects user choices.

## 4. Deployment & Installation

### Installer Script (`install_dragon_service.sh`)
- Run with sudo: `sudo ./install_dragon_service.sh`.
- The script can install:
  1. ACPI EC driver (`install_driver_only` option)
  2. The `.deb` package (`install_deb_only` option)
  3. Systemd service only (`install_service` option)
  4. Everything together (`install` -> `full_install` pathway)
- It validates dependencies (`whiptail`, `git`, `x11-xserver-utils`) before creating the service.
- The service file (`/etc/systemd/system/dragon-service.service`) runs as root but sources the GUI environment of the original user.

### Service Management
- After replacing the binary, restart the service to load the new executable:
  ```bash
  sudo systemctl restart dragon-service
  ```
- To inspect the service state:
  ```bash
  sudo systemctl status dragon-service
  ```
- Tail logs:
  ```bash
  journalctl -u dragon-service -f
  ```
- To stop/disable the service before making manual changes:
  ```bash
  sudo systemctl stop dragon-service
  sudo systemctl disable dragon-service
  ```
- Use the `uninstall_dragon` pathway to clean up driver, service, and optionally `/usr/local/lib/dragoncenter`.

### Binary Updates
- The installer does not automatically swap the in-memory process. Always `systemctl restart` after overwriting `/usr/local/lib/dragoncenter/dragon` (or whichever binary path the service points to).
- A reboot is not required unless the ACPI EC driver installation explicitly instructs you to reboot.

## 5. Cursor/Copilot Rules
- No cursor rules were found under `.cursor/rules/`.
- No Copilot instructions exist in `.github/copilot-instructions.md`.

## 6. Miscellaneous
- Keep flutter assets (`assets/config/`, `assets/images/`) referenced in `pubspec.yaml` in sync with the directory tree.
- `analysis_options.yaml` extends `flutter_lints`; do not alter it without a compelling lint reason.
- When adding new packages, update `pubspec.lock` via `flutter pub get` and avoid committing generated build artifacts (e.g., files under `.dart_tool`).

---
*Generated by agent on Mon Mar 02 2026*
