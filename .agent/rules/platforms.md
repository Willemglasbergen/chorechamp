# Platform and infrastructure rules

This project uses the following defaults unless explicitly stated otherwise:

- App framework: Flutter
- Backend: Firebase
- Email sending: Firebase Sendgrid mail extension
- Hosting: Firebase
- Monitoring: Sentry
- Code backup and version control: GitHub

Environment model:
- The project uses two separate Firebase projects:
  - test/development
  - production
- Both Firebase projects are intended to stay functionally identical in:
  - database schema and collections
  - storage structure
  - security rules
  - indexes
  - extensions
  - general backend setup
- Differences should only exist where environment separation is required, such as:
  - Firebase project IDs
  - credentials and secrets
  - domains/URLs
  - app identifiers where needed
  - live data
  - deployment targets
- Do not introduce unnecessary drift between test/development and production.

Mandatory rules:
- Never replace Flutter with another app framework unless explicitly requested.
- Never send email directly from Flutter through SMTP credentials or direct provider secrets.
- Use the Firebase Sendgrid mail extension for app-triggered emails.
- Use Firebase for hosting-related deployment targets relevant to this project.
- Use Sentry for monitoring rather than ad-hoc logging-only approaches when monitoring is requested.
- Use GitHub as the default remote repository and code backup platform.

Security rules:
- Never commit secrets, private keys, tokens, SMTP passwords, or privileged configuration to the repository.
- Never expose privileged Firebase or email configuration in client code.
- Keep mail-extension-related secrets and sensitive configuration in Firebase-managed backend configuration or other secure server-side mechanisms.
- Prefer least-privilege access patterns.
- Keep test/development and production credentials clearly separated.

Implementation rules:
- Prefer repository/service abstractions for Firebase access.
- Prefer small, safe, reviewable changes over broad rewrites.
- Respect existing extension, hosting, and project configuration already present in the repo.
- When backend changes are proposed, assume they must be mirrored across both Firebase environments unless explicitly stated otherwise.
