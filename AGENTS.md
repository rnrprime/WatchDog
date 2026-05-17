# WatchDog Project Notes

## Project Overview

WatchDog is a SwiftUI iOS app for tracking appliance warranties, documents, reminders, and expiry items. It helps users keep receipts, warranty dates, renewals, and notifications in one place, with OCR support for scanning receipt details.

## Architecture Decisions

- SwiftUI drives the UI, with screens organized by feature under `Views/`.
- View models live in `ViewModels/` and keep form/list state out of views.
- Domain models live in `Models/` and represent appliances, warranties, documents, expiry items, reminders, and user profile data.
- Services live in `Services/` and isolate integrations such as OCR, notifications, storage, Supabase, sync, and nonce generation.
- App-level setup is grouped under `App/`, including the app entry point, delegate, environment, and root content view.

## Conventions

- Prefer SwiftUI-native patterns and async/await over callback-heavy APIs.
- Keep `@State` private and local to the view that owns it.
- Use explicit `Color` values when mixing semantic and concrete foreground styles in ternary expressions.
- Keep reusable UI primitives in `Views/Components/`.
- Keep feature-specific components close to their feature folders.

## Build And Run

1. Open the WatchDog project in Xcode.
2. Select the `WatchDog` scheme.
3. Build with Product > Build, or use the configured Xcode build action.
4. Run on an iOS simulator or device with the required app capabilities configured.

## Quirks And Gotchas

- SwiftUI style inference can pick `HierarchicalShapeStyle` for values like `.secondary`; mix it with `Color.orange` only after making both branches explicit `Color` values.
- OCR confirmation state is initialized from immutable OCR results, then edited locally before confirmation.
- Supabase and storage behavior depend on `Config.plist` and app entitlements being correctly configured.
