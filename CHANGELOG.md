# Changelog

This repository was rebuilt on 2026-11-12 under a new maintainer identity and its
version numbering restarted at 0.1.0. Entries below 0.1.0 belong to the earlier
repository lineage and are kept as mechanism and validation evidence. They do not
correspond to versions published here, and the preference paths they mention use
the former bundle identifier.

## 0.1.0 — first release of the rebuilt repository

- Rebuild the public repository under the current maintainer identity; behavior is
  the same as the last revision of the previous lineage.
- Rename the runtime bundle identifiers to `com.chenxi.battctl`, covering the saved
  target preference, the optional monitor LaunchAgent label and legacy-daemon
  checks. The original-limit backup path is unchanged.
- `scripts/install.sh` copies a target saved under a previous bundle identifier to
  the new preference path before installing, so an upgrade keeps the saved intent.
- Update clone/release URLs, download names, documentation and the CLI version
  assertion; the workflow, write guards and command contract are unchanged.

## 0.2.3 — distinguish registration from battery behavior

- Separate registered targets from consistent/inconsistent/unknown observations.
- Stop reporting successful verification when a battery above target is charging
  or idle; unknown behavior also returns nonzero without inventing a cause.
- Read telemetry in hold and remove the unconditional no-reboot success message.
- Keep calibration override detection explicitly unknown; no calibration bypass,
  automatic restart, charging controller or new write mechanism is introduced.
- Add regression coverage for the observed override/recovery states and clarify
  JSON/exit-code semantics, including the stricter policy_active field.
- Document 26A434 target arrival, calibration override and recovery observations.

## 0.2.2 — OS update compatibility

- Replace the exact OS build allowlist with runtime API and effective-policy
  checks, retaining the MacBookPro18,1 hardware scope.
- Refuse staging if the current selection and active policy disagree, policy
  reading fails, or the original recovery limit is no longer supported.
- Keep preference readback, transaction rollback, backups and manual reboot.
- Distinguish successful staging from verified holding after an OS update.
- Replace the root README with AGENTS.md for AI maintenance context, including
  required Codex coauthor attribution and automatic commit/push after changes.
- Document automatic version tagging and evidence-based release publication;
  prepare self-contained release notes while 26A434 reboot validation is pending.

## 0.2.1 — native-only maintenance update

- Keep one workflow: `hold TARGET`, normal restart when needed, native holding.
- Remove interval cycling, its controller/guard, and legacy SMC control/probe code.
- Standardize commands: hold, status, verify, monitor, doctor and restore.
- Upgrade cleanup safely retires the old experimental service and files while
  preserving the native target and original-limit backup.
- Explicitly report the active selection and warn that the old limit can keep
  charging before restart. Treat an empty pmset limit list as unverified, not malformed.
- Refresh Chinese/English documentation, hardware observations and CLI regression checks.
- This is a new patch release; the published v0.2.0 tag and artifacts are unchanged.

## 0.2.0 — configurable experimental targets

- `hold TARGET` accepts integers 20–99, including 70; 100 remains the ordinary
  `native-limit 100` full-charge operation.
- Save requested intent separately from active policy; `verify` and `monitor`
  follow it by default or accept an explicit target. Legacy default remains 50.
- Preserve the original backup while replacing targets, including pending requests;
  roll back the previous saved preference and requested intent on partial failures.
- Update existing optional recorders when their start script is run again.
- Only 50% has completed hardware testing; all other targets remain experimental.

## 0.1.0 — experimental prerelease

- Persistent 50% preference staging with an original-limit backup and manual restart.
- Native/effective policy verification, telemetry, monitoring and restoration.
- Verified on one MacBookPro18,1 / M1 Pro / macOS 27.0 build 26A428, including
  discharge to target and open/closed-lid sleep/wake retention.
- Model/build write guard, readback checks and fake-client regression tests.
- Chinese/English installation and recovery guides, sanitized validation summary,
  optional local recorder, macOS CI and source-inclusive arm64 release packaging.

Other models/builds, multi-day stability, recharge threshold and calibration
charging are not established. This release is not Developer ID signed or notarized.
