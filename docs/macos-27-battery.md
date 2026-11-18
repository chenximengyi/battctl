# Native charge-limit implementation

## One workflow

`hold TARGET` saves an integer target from 20 to 99 into the system's native
manual-charge-limit preference. When the running service has not loaded that target,
a normal user-initiated restart is required. Before that restart the old policy
remains in effect, including any charging it permits.

On the tested MacBookPro18,1 / 26A428, loading experimental sub-80 targets at boot
works even though the ordinary PowerUI setter advertises only 80/85/90/95/100.
This is a private preference path, not a supported Apple API contract. Writing a
preference alone is never considered proof that the policy is active.

The CLI does not control adapter power, access AppleSMC, install a charging daemon,
prevent sleep, restart protected services or require SIP changes. Once loaded,
macOS owns the policy independently of the CLI. Current source contains only the
native backend; the installer retains a cleanup path for an earlier development
controller and calls that old controller's recovery executable before removing it.

## Persistence and recovery

Root writes `mclLimitValue` in `com.apple.smartcharging.topoffprotection`.
The native feature must already be enabled and temporary overrides finished.
Writes retain the tested model restriction (MacBookPro18,1), but no longer require
an exact OS build string. Before any preference write, the native API must be
readable, Charge Limit enabled, preferences valid, and the current native selection
consistent with all active manual-limit entries. This check uses the current
selection so a saved pending target does not falsely fail compatibility checks.
The original recovery value must remain supported by the native API. Missing,
malformed or inconsistent policy data fails closed. A passing preflight only
permits staging; reboot loading and sustained holding still need verification on
each new OS version. Private preference compatibility is not guaranteed.

The first supported original value is stored in the root-only file
`/Library/Application Support/battctl-reboot-test/previous-limit` and never replaced
by later experimental targets. Keep that historical path for existing installations.
The user-requested target is stored separately in
`/Library/Preferences/com.chenxi.battctl.plist`, root-owned and readable by ordinary
users. Absence preserves the v0.1.0 default target of 50; malformed metadata fails
verification instead of silently adopting the running native limit.

A preference lock serializes updates. A target change writes and verifies the system
preference, then atomically saves and reads back the requested-target metadata.
Failure attempts to restore both immediately previous values, not the original
backup. A system crash between the two files is not an atomic cross-file transaction;
re-running the intended `hold` request repairs saved intent. A pending target can
be replaced before restart, including cancellation back to the active target.

`restore` saves the original supported value and uses the native setter, then checks
actual policy readback before clearing requested-target metadata. The original
backup is retained for retries. Failed restoration leaves recovery information intact.

## Charge-to-full calibration

A registered manual limit does not stop macOS from occasionally charging to full.
The decision belongs to powerd's battery-gauging path, not to the CLI and not to the
Charge Limit switch in Battery settings. A periodic timer compares the last
full-charge date with a hard-coded 1,814,400-second (21-day) threshold in the
current build's powerd. When that threshold is exceeded, or when the gauge needs an
OCV or QMax update, powerd raises a system-level charge-to-full request,
PowerUIAgent reports `ChargingUpForGauging`, and the charging layer suspends the
SOC-limit policy. The manual-limit preference, its entries and the saved target keep
reading the requested value throughout.

Observed sequence on 26B131:

- The battery charged above the 50% target with the lid closed while registration
  still read 50.
- powerd logged `Last full charge date was 21.4 days ago, try and charge to full`,
  `Charge To Full System Level Request:1` and
  `SOC limit policy suspend due to mitigation active:1`.
- PowerUI logged `ChargingUpForGauging`, optimized limit 100, MCL target 50 and
  `chargingOverrideAllowed: 0`.
- Restarts taken at 61% and at 99% during that charge did not clear the request; it
  was issued again after each boot.
- After the battery reached 100%, a further restart was followed by
  `Last full charge date was 0.0 days ago too recent` and
  `chargeControl charge to full requested:0`. The SOC-limit policy resumed and the
  battery discharged toward 50% with AC connected.

Apple documents occasional charging to 100% with Charge Limit enabled as expected
behavior for accurate state-of-charge estimates. Consequences for the CLI: `hold`
cannot cancel the request, a matching target writes nothing, and a restart only
helps after the gauge has recorded the full charge. The CLI still reports
`system_override=unknown`; an opaque PowerUI state value observed during this event
(18, versus 16 while discharging at the target) is not a validated detector. A
single battery sample cannot distinguish calibration from a user-set limit or
another override, and no recovery is guaranteed.

## Verification

Registration and runtime observations are separate in v0.2.3:

- `policy_registered`: PowerUI selection/enabled state and every non-terminated
  manual-limit entry match the target. This does not detect system overrides.
- `runtime_status`: `consistent`, `inconsistent`, or `unknown`. An AC-connected
  sample is consistent when discharging above target, idle within one percentage
  point of target, or charging below target (outside that tolerance).
- `verification_passed`: matching registration and a consistent sample, with no
  read/configuration errors. `policy_active` remains as a compatibility field but
  now aliases this stricter result. JSON consumers must account for this change.
- `system_override=unknown`: the CLI does not have a validated live detector of
  calibration or other overrides. It never infers a definite cause from current.

Charging above target reports `charging_above_target`; being above target with
zero current reports `above_target_idle`. Both are inconsistent observations and
return exit 1 from `verify`/`doctor`. Missing telemetry, AC disconnection, or idle
below target (which may be normal hysteresis) is unverified/unknown, also exit 1;
this is not necessarily a malfunction. Near-target charging/discharging is
conservatively unverified. A single consistent sample is not proof of sustained
holding and cannot rule out all overrides.

`hold` reads fresh telemetry via the same reader as `verify`, including after a
write. If intent and registration already match, it makes no preference write:
exit 0 requires a consistent sample; otherwise exit 1 and runtime guidance.
It no longer promises that reboot is unnecessary. A new target successfully
saved but not yet registered still exits 0 with a clear pending-reboot message;
that success means staging only. `restore` verifies restoration of registration,
not runtime behavior, so it can recover while unplugged or without telemetry.

Compatibility preflight likewise checks registration independently of runtime:
a system override must not turn into a misleading API-incompatibility failure.
`No battery level limits set` is a valid empty result, not a parsing error.
Other malformed or unsupported output remains an error.

Telemetry reads IORegistry without dumping identifying battery data. Current is
interpreted as signed even when represented by an unsigned NSNumber. Power is
estimated from current × voltage, not measured directly at the adapter. Readings can
lag, and deep sleep suspends sampling. `near_target` describes a single observation.

## Primary references

- [Apple: Charge Limit and Optimized Battery Charging](https://support.apple.com/en-us/102338)
- [macOS 27 release notes](https://developer.apple.com/documentation/macos-release-notes/macos-27-release-notes)
- [IOPowerSources](https://developer.apple.com/documentation/iokit/iopowersources_h)

[Sanitized validation](validation.md) · [Attribution](../THIRD_PARTY.md)
