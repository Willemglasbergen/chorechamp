# Flutter-only project rule

This project is an existing Flutter application and must continue to be implemented as a Flutter application.

Core rules:
- Always use Flutter and Dart for app code.
- Never propose React Native, Expo, SwiftUI, Kotlin Multiplatform, Ionic, or non-Flutter web-first alternatives unless explicitly asked.
- Prefer standard Flutter project structure under `lib/`.
- Use pub dependencies, not npm packages.
- Generate widgets, screens, services, state management, routing, models, and helpers in Dart.
- If a request is ambiguous, assume the user wants a Flutter implementation.
- The app must support the platforms already present in the project unless explicitly stated otherwise.

Existing-project rules:
- Treat this as an imported, existing codebase.
- Respect the current architecture, folder structure, coding patterns, and package choices unless there is a strong reason to improve them.
- Prefer incremental changes over large rewrites.
- Do not introduce unnecessary migrations or replace major existing infrastructure without being asked.
- Before adding a new pattern, first align with what the project already does.
- Preserve backward compatibility where practical.

Code quality and cleanup (important for generated codebases):
- This project may contain generated code from Flutterflow with:
  - dead or unused code
  - duplicate imports
  - redundant widgets or logic
  - suboptimal patterns

- You are allowed and expected to:
  - remove unused imports and dead code
  - fix obvious bugs
  - simplify redundant or duplicated logic
  - improve readability where safe

- You must NOT:
  - perform large architectural rewrites unless explicitly requested
  - change working behavior unnecessarily
  - introduce breaking changes without clear reason

- Prefer incremental, safe improvements that increase code quality over time.

Architecture defaults:
- Use a layered architecture with clear separation between UI, state/view models, repositories, and data sources.
- Keep business logic out of widgets.
- Prefer feature-based folder organization when practical.
- Prefer maintainable architecture over quick hacks.

State management:
- Prefer the existing project state-management approach if one is already established.
- If the project does not have a clear state-management pattern, use Riverpod as the default for new feature-level shared state.
- Use simple local widget state only for truly local UI concerns.

Routing:
- Prefer the existing project routing approach if one is already established.
- If the project does not have a clear routing standard, use go_router as the default for new routing work.

Backend defaults:
- Use Firebase as the default backend platform for this project.
- Prefer the existing Firebase services already in use by the project.
- Prefer official FlutterFire packages for Firebase integration.
- Prefer Firebase Auth for authentication if the existing app already uses it.
- Prefer Firestore or Realtime Database patterns already present in the project rather than introducing a second backend.
- Prefer Firebase Storage, Cloud Functions, Messaging, Analytics, Remote Config, and other Firebase services only when relevant to the existing app requirements.
- Do not introduce another backend such as Supabase unless explicitly requested.

Environment defaults:
- This project uses two separate Firebase projects:
  1. test/development
  2. production
- Assume both Firebase projects are intentionally identical in schema, storage structure, security rules, indexes, extension setup, and general backend configuration unless explicitly stated otherwise.
- Differences between the two environments should be limited to environment-specific configuration, credentials, project IDs, domains, and live data.
- Never mix test/development and production configuration in code, deployment steps, or documentation.
- Prefer environment-aware setup that cleanly switches between the two Firebase projects.
- When proposing backend or infrastructure changes, assume those changes should be applied consistently to both Firebase projects unless explicitly requested otherwise.
- Do not create unnecessary drift between test/development and production.

Email defaults:
- Use the Firebase Sendgrid mail extension for sending emails.
- Prefer the existing Firebase extension setup if it is already present.
- Do not send email directly from client-side Flutter code through SMTP providers or third-party mail SDKs.
- Trigger email sending through the Firebase Sendgrid mail extension's expected data flow.
- Keep email-trigger logic, payload shape, and collection writes aligned with the extension configuration already used by the project.
- Keep secrets and privileged mail configuration out of client code.

Hosting defaults:
- Use Firebase for hosting the app where hosting is relevant to this project.
- For Flutter web deployments, prefer Firebase Hosting.
- Respect the existing Firebase project and hosting configuration already present in the repository.
- Keep test/development and production hosting targets clearly separated.

Monitoring defaults:
- Use Sentry for monitoring and error tracking.
- Prefer Sentry for Flutter error reporting and performance monitoring.
- Keep Sentry configuration environment-aware where practical.
- Use distinct environments/releases for test/development and production when relevant.
- Do not hardcode sensitive monitoring configuration in unsafe places.

Source control defaults:
- Use GitHub for code backup and version control.
- Keep repository files, configuration, and workflow-related assets suitable for GitHub-based collaboration.
- Prefer changes that are safe to review and commit incrementally.

Networking:
- Use official Firebase clients for Firebase-related operations.
- Use the http package as the default HTTP client for non-Firebase external APIs unless a feature clearly requires a more advanced client.

Forms and validation:
- Prefer native Flutter forms and validators by default.
- Only introduce a forms package if the project has clearly complex form workflows and it fits the existing architecture.

Date and localization:
- Use intl for date, time, number, and localization formatting.

Dependency policy:
- Prefer well-maintained and widely adopted packages from pub.dev instead of custom implementations for common functionality.
- Avoid outdated, obscure, or weakly maintained packages.
- Do not reinvent common functionality without a good reason.
- Prefer packages that are compatible with the platforms already targeted by the project.
- Before adding a new dependency, check whether the project already has an accepted package for that concern.

Responsive defaults:
- Build mobile-first, but scale cleanly to tablet and desktop where relevant.
- Use a primary breakpoint based on screen width.
- Do not rely solely on orientation for layout decisions.
- Orientation may be used as a secondary signal to refine layouts.
- Prefer responsive patterns such as Expanded, Flexible, Wrap, LayoutBuilder, MediaQuery, and ConstrainedBox.
- On web and desktop, avoid stretching content edge-to-edge; prefer centered layouts with sensible max widths.
- Consider mouse, keyboard, focus, and hover interactions where relevant.

Firebase-specific guidance:
- Keep secrets and privileged operations out of client code.
- Use Firebase security rules-aware application design where relevant.
- Prefer repository or service layers for Firebase access instead of calling backend APIs directly from UI widgets.
- Respect the existing Firebase project configuration and initialization approach already present in the app.
- Keep environment selection explicit and safe for test/development versus production.

Email-extension-specific guidance:
- Prefer writing to the configured mails collection or trigger path used by the Firebase mail extension.
- Keep email composition logic separated from UI widgets when practical.
- Prefer reusable services or repositories for creating mail documents for the extension.
- If templates or dynamic fields are already used, preserve that pattern.
