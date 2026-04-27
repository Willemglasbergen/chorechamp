When the user asks for setup, infrastructure, monitoring, email delivery, hosting, or repository-related work in this repository:

1. Assume the default stack is:
   - Flutter app
   - Firebase backend
   - Firebase Sendgrid mail extension for sending emails
   - Firebase for hosting
   - Sentry for monitoring
   - GitHub for code backup and version control

2. Assume the backend uses two Firebase projects:
   - test/development
   - production

3. Assume both Firebase projects are intentionally identical in:
   - schema/collections
   - storage structure
   - security rules
   - indexes
   - extensions
   - general backend setup

4. Differences between the two environments should only be environment-specific values such as:
   - project IDs
   - credentials
   - domains
   - live data
   - deployment targets

5. For email delivery:
   - use the Firebase mail extension
   - do not use direct SMTP credentials in Flutter client code
   - prefer service/repository code that writes the correct trigger data for the extension
   - preserve existing mails collection and template structure if already present
   - keep the extension setup aligned across both environments

6. For monitoring:
   - default to Sentry
   - initialize Sentry in a production-ready way
   - capture uncaught errors where practical
   - use separate environment tagging for test/development and production

7. For hosting:
   - default to Firebase hosting-related setup when relevant to the app
   - respect the current Firebase configuration already in the repository
   - keep test/development and production hosting/deployment clearly separated

8. For repository and backup assumptions:
   - assume GitHub is the primary remote repository
   - keep changes suitable for normal GitHub-based version control workflows

9. Keep secrets out of the repository and out of client code.

10. Prefer secure, maintainable, incremental implementations over quick hacks.

11. When proposing backend or infrastructure changes, assume those changes should be applied to both Firebase environments unless explicitly requested otherwise.
