# Architecture

## Stack
- Frontend: Flutter
- Backend: Firebase
- Auth: Firebase Auth
- Database: Firestore or Realtime Database
- Storage: Firebase Storage
- Email: Firebase SendGrid mail extension
- Hosting: Firebase Hosting
- Monitoring: Sentry
- Source control: GitHub

## Existing project status
This is an existing Flutter/Firebase codebase.

## Architecture principles
- Respect existing patterns first.
- Prefer incremental changes over large rewrites.
- Keep business logic out of widgets where practical.
- Prefer repositories/services for Firebase access.
- Keep privileged logic out of client code.
- Keep test/development and production environments aligned.

## Folder structure
TODO: Document the current folder structure and preferred locations for new code.

## Important existing patterns
TODO: Document existing routing, state management, Firebase initialization, services, helpers, and generated-code patterns.
