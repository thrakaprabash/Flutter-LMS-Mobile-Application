# Current milestone and scope

Updated user instruction on 21 October 2026: backend access is restored for all roles. Remove all demo entry points, services, sample dashboards, local photo state and demo-only tests. All application roles use authenticated backend accounts. Tests may use test-only API adapters; production code must not include demo modes or authentication bypasses.

The user explicitly authorized Day 5 on 15 October 2026: real backend authentication, session management, password recovery and profiles.

- Follow the supplied API integration guide, Backend API Report, Postman collection and Day 5 task plan.
- Preserve the green theme, onboarding illustrations and three role dashboard shells. Dashboard data must come from the backend; never substitute sample counts.
- Public login must authenticate against the backend; protected routes use the returned role. Never restore local preview login or expose a role switcher as authorization.
- Keep passwords, OTPs and tokens out of source, tests, documentation and logs. Store session tokens only through secure storage.
- Do not advance into Day 6 business features unless requested.
- Do not change suspended accounts or backend/database configuration to bypass authentication rules.
- Keep sample data separate from reusable UI and feature services/providers.
- Git commits and pushing remain manual unless explicitly requested.
