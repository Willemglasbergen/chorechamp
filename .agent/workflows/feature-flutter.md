When the user asks for a new feature in this repository:

1. Assume the feature must be implemented in Flutter and Dart.
2. Generate Dart code only unless explicitly requested otherwise.
3. Treat this as an existing codebase:
   - inspect current patterns first
   - prefer incremental changes
   - avoid unnecessary rewrites
4. Follow the project's existing stack where it is already defined.
5. For backend features, use Firebase and the official FlutterFire packages.
6. The project uses two Firebase environments:
   - test/development
   - production
7. Assume both Firebase environments are intentionally identical in structure and should remain aligned.
8. Keep changes environment-aware and avoid mixing production and test/development configuration.
9. For email features, use the Firebase mail extension rather than direct email provider integrations.
10. For monitoring, prefer Sentry.
11. For hosting-related work, prefer Firebase.
12. For code backup and repository assumptions, prefer GitHub.
13. For non-Firebase external API calls, use http unless a feature clearly needs something more advanced.
14. Use the project's existing routing and state-management approach if one is already established.
15. If there is no clear project standard for shared state or routing, use:
   - Riverpod for state management
   - go_router for routing
16. Place screens, widgets, services, repositories, models, and helpers in the correct project structure.
17. Keep business logic out of widgets.
18. Keep direct backend calls out of presentation widgets when possible.
19. Reuse existing widgets and patterns where possible.
20. Ensure responsive behavior for the platforms already targeted by the project.
21. Prefer well-maintained pub.dev packages over custom implementations for common functionality.
22. Keep the implementation production-ready and maintainable.

Additional step for existing generated codebases:
- While implementing features, clean up nearby code:
  - remove unused imports
  - eliminate dead code
  - simplify obvious redundancies
- Keep changes scoped and safe.
