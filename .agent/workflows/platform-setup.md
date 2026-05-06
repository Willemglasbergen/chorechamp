When the user asks for setup, infrastructure, monitoring, email delivery, hosting, or repository-related work in this repository:

1. Read the relevant files in `/context/` before making assumptions.

2. Assume the default stack is:
   - Flutter app
   - Firebase backend
   - Firebase SendGrid mail extension for sending emails
   - Firebase for hosting
   - Sentry for monitoring
   - GitHub for code backup and version control

3. Assume the backend uses two Firebase projects:
   - test/development
   - production

4. Assume both Firebase projects are intentionally identical in:
   - schema/collections
   - storage structure
   - security rules
   - indexes
   - extensions
   - general backend setup

5. Differences between the two environments should only be environment-specific values such as:
   - project IDs
   - credentials
   - domains
   - live data
   - deployment targets

6. For email delivery:
   - use the Firebase mail extension
   - do not use direct SMTP credentials in Flutter client code
   - prefer service/repository code that writes the correct trigger data for the extension
   - preserve existing mails collection and template structure if already present
   - keep the extension setup aligned across both environments

7. For monitoring:
   - default to Sentry
   - initialize Sentry in a production-ready way
   - capture uncaught errors where practical
   - use separate environment tagging for test/development and production

8. For hosting:
   - default to Firebase hosting-related setup when relevant to the app
   - respect the current Firebase configuration already in the repository
   - keep test/development and production hosting/deployment clearly separated

9. For repository and backup assumptions:
   - assume GitHub is the primary remote repository
   - keep changes suitable for normal GitHub-based version control workflows

10. Keep secrets out of the repository and out of client code.

11. Prefer secure, maintainable, incremental implementations over quick hacks.

12. When proposing backend or infrastructure changes, assume those changes should be applied to both Firebase environments unless explicitly requested otherwise.

13. If external memory conflicts with `/context/`, use `/context/`.
