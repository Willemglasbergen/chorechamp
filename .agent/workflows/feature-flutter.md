When the user asks for a new feature in this repository:

1. Read the relevant files in `/context/` before making assumptions.
2. Assume the feature must be implemented in Flutter and Dart.
3. Generate Dart code only unless explicitly requested otherwise.
4. Treat this as an existing codebase:
   - inspect current patterns first
   - prefer incremental changes
   - avoid unnecessary rewrites
5. Follow the project's existing stack where it is already defined.
6. For backend features, use Firebase and the official FlutterFire packages.
7. The project uses two Firebase environments:
   - test/development
   - production
8. Assume both Firebase environments are intentionally identical in structure and should remain aligned.
9. Keep changes environment-aware and avoid mixing production and test/development configuration.
10. For email features, use the Firebase mail extension rather than direct email provider integrations.
11. For monitoring, prefer Sentry.
12. For hosting-related work, prefer Firebase.
13. For code backup and repository assumptions, prefer GitHub.
14. For non-Firebase external API calls, use http unless a feature clearly needs something more advanced.
15. Use the project's existing routing and state-management approach if one is already established.
16. If there is no clear project standard for shared state or routing, use Riverpod for state management and go_router for routing.
17. Place screens, widgets, services, repositories, models, and helpers in the correct project structure.
18. Keep business logic out of widgets.
19. Keep direct backend calls out of presentation widgets when possible.
20. Reuse existing widgets and patterns where possible.
21. Ensure responsive behavior for the platforms already targeted by the project.
22. Prefer well-maintained pub.dev packages over custom implementations for common functionality.
23. Keep the implementation production-ready and maintainable.
24. If external memory conflicts with `/context/`, use `/context/`.

Additional step for existing generated codebases:
- While implementing features, clean up nearby code:
  - remove unused imports
  - eliminate dead code
  - simplify obvious redundancies
- Keep changes scoped and safe.
