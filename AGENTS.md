# Current milestone and scope

Updated user instruction on 16 October 2026: retain isolated debug-only demo access for development while shared backend accounts are suspended. This supersedes the earlier instruction to remove demo before the 3:00 PM viva. When supervisors restore backend access, verify the real integrations and remove demo entry points, service/provider, local photo state and demo-dependent tests. Never use demo roles as real authorization, automatically fall back to demo after login failure, or change real credentials to bypass suspension. Real backend integration stays connected throughout.

The user explicitly authorized Day 5 on 15 October 2026: real backend authentication, session management, password recovery and profiles.

- Follow the supplied API integration guide, Backend API Report, Postman collection and Day 5 task plan.
- Preserve the green theme, onboarding illustrations and three role dashboard shells. Dashboard course data remains a clearly labelled preview until its later milestone.
- Public login must authenticate against the backend; protected routes use the returned role. Never restore local preview login or expose a role switcher as authorization.
- Keep passwords, OTPs and tokens out of source, tests, documentation and logs. Store session tokens only through secure storage.
- Do not advance into Day 6 business features unless requested.
- Do not change suspended accounts or backend/database configuration to bypass authentication rules.
- Keep sample data separate from reusable UI and feature services/providers.
- Git commits and pushing remain manual unless explicitly requested.
