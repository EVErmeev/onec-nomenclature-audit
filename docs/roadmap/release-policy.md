# Release Policy

## Versioning
- `MAJOR.MINOR.PATCH`
- 1.0.0 = baseline
- 1.x.0 = feature release
- 1.x.y = bugfix

## Per-Release Requirements
1. Full commit SHA
2. ERF/CFE SHA-256
3. Git blob
4. Release manifest updated
5. Release notes (`docs/releases/v1.x/release-notes.md`)
6. Migration notes
7. Known issues updated
8. Rollback plan
9. Evidence (MCP + manual smoke-test)
10. verify-release.ps1 exit 0

## Branching
- `main` — stable releases
- `feature/*` — feature development
- `fix/*` — bugfix branches

## PR Policy
- 1 PR per feature release
- Draft until acceptance
- Must include evidence
- Must pass verify-release

## Release Cadence
- v1.1: Week 2–3
- v1.2: Week 5–6
- v1.3: Week 8–9
- v1.4: Week 12–14
- v1.4.1: Week 15–16
