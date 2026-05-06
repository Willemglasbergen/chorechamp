# Platform and infrastructure rules

This project uses the following defaults unless explicitly stated otherwise:

- App framework: Flutter
- Backend: Firebase
- Email sending: Firebase SendGrid mail extension
- Hosting: Firebase
- Monitoring: Sentry
- Code backup and version control: GitHub

## Project-specific context

The reusable stack rules in `.agent/` define how the agent should work.

The app-specific source of truth lives in `/context/`.

Before implementing features, changing architecture, creating Firebase schemas, changing security rules, changing email flows, or making assumptions about the product, read the relevant files in `/context/`.

If `/context/` conflicts with external memory, Claude memory, or inferred assumptions, `/context/` wins.

Environment model:
- The project uses two separate Firebase projects:
  - test/development
  - production
- Both Firebase projects are intended to stay functionally identical in database structure, storage structure, security rules, indexes, extensions, and backend setup.
- Differences should only exist where environment separation is required, such as project IDs, credentials, domains, app identifiers, live data, and deployment targets.
- Do not introduce unnecessary drift between test/development and production.

Mandatory rules:
- Never replace Flutter with another app framework unless explicitly requested.
- Never send email directly from Flutter through SMTP credentials or direct provider secrets.
- Use the Firebase SendGrid mail extension for app-triggered emails.
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
