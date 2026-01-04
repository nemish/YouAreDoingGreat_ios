# Standard Issue Template

## Context

Explain the surrounding information: why is this change needed, what is the problem, what is the current situation.

*Example: Users are experiencing slow page loads on the dashboard (>5s), impacting daily workflow. Analytics show 40% drop-off when load time exceeds 3s. Current implementation fetches all data on mount without caching.*

## Requirements & Definition of Done

Describe the solution to the problem above, and include a checklist to verify the task is complete. Each item should be specific to this task.

*Example:*

*Implement data caching and lazy loading to reduce dashboard load time to under 2 seconds.*

- [ ] React Query implemented for API data caching
- [ ] Chart components lazy loaded with Suspense
- [ ] Loading skeleton displayed while data fetches
- [ ] Error boundary shows retry button on failure
- [ ] Load time measured at <2s on staging
- [ ] No regressions in existing functionality

## Technical

Implementation details, architecture decisions, and technical considerations.

*Example: Use React Query with 5-minute stale time, implement code splitting for ChartJS components, add pagination to /api/metrics endpoint (50 items/page).*

## Extra Sources

- [Figma mockups](link)
- [API documentation](link)
- [Related PRs or issues](link)
