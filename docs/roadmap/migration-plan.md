# Migration Plan

## v1.0 → v1.1 (ERF only, no migration)
- Add export, filters, severity, summary to existing ERF
- No data migration needed
- Rollback: revert to v1.0 ERF

## v1.1 → v1.2 (ERF + CFE)
1. Install CFE `KontrolKachestvaNSI.cfe` in target base
2. Initialize registers (default rules, profiles)
3. Migrate hardcoded checks → rule records
4. ERF detects CFE → uses managed engine
5. ERF without CFE → uses embedded fallback
6. Rollback: uninstall CFE, revert ERF

## v1.2 → v1.3 (CFE data migration)
1. Add scoring fields to rule records
2. Initialize default weights
3. Enable history recording
4. First run captures baseline quality index
5. Rollback: disable feature flags, keep history

## v1.3 → v1.4 (CFE configuration)
1. Configure scheduled job schedule
2. Set notification thresholds
3. Set archive retention period
4. Enable monitoring feature flag
5. Rollback: disable scheduled job

## Data Migration Checklist
- [ ] Backup base before CFE install
- [ ] Verify read-only behavior post-install
- [ ] Test ERF standalone (no CFE) after CFE install
- [ ] Verify rule count matches hardcoded check count
- [ ] Verify history recording doesn't impact performance
