# Project instructions

## Project context source of truth

Before making architectural, product, Firebase, email, data-model, security-rule, or feature decisions, read the files in `/context/`.

The `/context/` folder is the source of truth for this specific app.

Use:
- `/context/project_overview.md` for product purpose and scope
- `/context/architecture.md` for technical architecture
- `/context/firebase_model.md` for Firestore/Realtime Database, Storage, indexes, rules, and Firebase services
- `/context/user_roles.md` for users, permissions, and role logic
- `/context/feature_flows.md` for business flows
- `/context/email_flows.md` for Firebase SendGrid mail extension flows
- `/context/environments.md` for test/development and production Firebase configuration strategy
- `/context/decisions.md` for prior architectural decisions

Do not rely on external Claude memory as the authoritative project context.

If external memory conflicts with files in `/context/`, the `/context/` files win.

## Firebase source of truth

For Firebase-specific work, read the actual Firebase configuration files directly:

- `firebase.json`
- `.firebaserc`
- `firestore.rules`
- `firestore.indexes.json`
- `storage.rules`
- `functions/`
- `lib/firebase_options.dart`

Do not rely only on `/context/firebase_model.md`.

Use `/context/firebase_model.md` only as an index, summary, or explanation layer.

If `/context/firebase_model.md` conflicts with actual Firebase configuration files, the actual Firebase files win.

## General project rules

This is an existing Flutter application that already uses Firebase.

Non-negotiable:
- Always build features in Flutter and Dart.
- Never output React Native, Expo, Next.js, SwiftUI, Kotlin, or other non-Flutter stacks unless explicitly requested.
- Respect the existing codebase structure and architecture.
- Prefer incremental improvements over large rewrites.
- Use the existing project conventions first.
- Use Firebase as the default backend for this project.
- Prefer official FlutterFire packages for Firebase integration.
- Use the existing routing and state-management approach if one is already established.
- If no clear project standard exists, use Riverpod for state management and go_router for navigation.
- Use the http package for non-Firebase external APIs unless a feature clearly needs something more advanced.
- Use built-in Flutter forms and validators by default.
- Use intl for date, time, and localization formatting.
- Prefer well-maintained and widely used packages from pub.dev.
- Make UI responsive across the platforms already targeted by the app.
- Keep implementations production-ready, reusable, and maintainable.

Environment setup:
- This project uses two Firebase projects:
  - test/development
  - production
- Assume both are intentionally identical in backend structure and configuration unless explicitly stated otherwise.
- Keep changes environment-aware and do not mix test/development and production config.
- When proposing backend changes, assume they should be applied to both environments unless explicitly requested otherwise.

Platform defaults:
- Use the Firebase SendGrid mail extension for sending emails.
- Use Firebase for hosting the app where hosting is relevant.
- Use Sentry for monitoring and error tracking.
- Use GitHub for code backup and version control.

Important security rules:
- Never send emails directly from the Flutter client using embedded credentials.
- Never expose secrets or privileged Firebase configuration in client code.
- Respect the existing Firebase extension and project setup already present in the repository.
