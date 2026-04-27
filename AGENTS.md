# Project instructions

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
- Use the Firebase Sendgrid mail extension for sending emails.
- Use Firebase for hosting the app where hosting is relevant.
- Use Sentry for monitoring and error tracking.
- Use GitHub for code backup and version control.

Important security rules:
- Never send emails directly from the Flutter client using embedded credentials.
- Never expose secrets or privileged Firebase configuration in client code.
- Respect the existing Firebase extension and project setup already present in the repository.
