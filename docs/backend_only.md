# Backend-only application

On 21 October 2026, the user confirmed restored account access for all roles and requested removal of every demo mode.

Removed login demo entry, role selector, local account/learning/assessment/instructor services, simulated media uploads, local profile photo state, seeded dashboards, unused preview models and screens, sample screenshots and tests that depended on application demo services. Empty folders were removed as well.

Student and instructor screens now always use AccountService and authenticated backend sessions. The administrator screen loads GET `/api/v1/dashboard/admin` instead of sample totals, with loading, error, retry and empty states. Admin management features beyond the dashboard still follow their planned milestone; no fake management queues remain.

Backend lesson `isPreview` access is retained: it controls legitimate course preview lessons before enrollment. It does not create a local demo account or sample content. UI labels, styling, validation and backend enum values remain ordinary application constants.

Regression tests use test-only API adapters or a test-only account service. Production code contains no demo transport. Profile combined-save failure handling remains covered. New dashboard tests exercise Student, Instructor and Admin through the normal AuthProvider and API client.

Verification: Flutter analysis passed and all 49 retained/replacement tests passed. Earlier milestone reports describe historical demo verification and are not current usage instructions. The cleanup does not delete backend courses, accounts or learning records.

Live admin dashboard acceptance requires signing in with an authorized Admin account; no administrative credentials were supplied for this cleanup.
