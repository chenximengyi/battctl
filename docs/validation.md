# Hardware validation

Results come from one device and are not a broad compatibility claim.
Personal paths, original timestamps, device serials, raw IORegistry dumps and
individual sleep schedules are omitted. Raw session logs are not distributed.
Version numbers below 0.1.0 belong to the previous repository lineage; they are
kept as mechanism evidence and were not re-run on this repository's binaries.

| Property | Value |
| --- | --- |
| Model | MacBookPro18,1 / Apple M1 Pro |
| macOS | 27.0, build 26A428 |
| Firmware observed | 20457.1.29 |
| Backend | Native PowerUI preference loading on normal restart |

## Observed native behavior

- At 50%, PowerUI and two active manual-charge-limit entries agreed after restart.
- With AC connected, battery charge declined to 50%, then reported net current
  settled at zero. Open-lid use, closed-lid use and reopening retained the target.
- Both open-lid and closed-lid sleep/wake tests retained 50%. Power-management events
  confirmed actual sleep, including some maintenance wakes. Samples after wake
  retained the native policy and reported zero net current.
- Changing to 70% required a normal restart in the observed test. The battery then
  charged to 70% and held there during awake use. This is not a complete repeat of
  the 50% sleep/wake validation at 70%.
- After returning to 50% and restarting, both effective manual-limit entries and
  PowerUI again reported 50%; the battery was observed discharging toward it with
  AC connected and the lid closed.

The native policy continued without a battery-control daemon. No SIP changes,
protected-service restarts or sleep-setting changes were needed.

## Not established

- Other models, chips, OS builds or firmware, or every configurable target.
- Exact lower replenishment thresholds, lifetime effects or indefinite exact percentage.
- A reliable automatic recovery from every calibration override; calibration
  overriding the custom 50% target has now been observed on 26A434.
- Continuous current during deep sleep or recovery from every power-loss/update case.

## macOS 27.0.1 / 26A434

On the same MacBookPro18,1, v0.2.2 saved 50%, loaded it after reboot, discharged
from 80% to 50% with AC connected, and returned repeated 50% / 0 mA samples.
Its original 80% backup was retained. v0.2.2 was published as a prerelease.
These observations do not repeat the complete sleep/wake validation from 26A428.

A later system-requested full charge for battery gauging suspended enforcement
while PowerUI and both registered manual-limit entries still reported 50%.
Logs explicitly reported a charge-to-full request and MCL being ignored. The
battery reached 100% and remained idle; another normal reboot cleared the full
charge request and restored AC-connected discharge toward 50%. The reason the
system did not automatically clear the override is not established. This does
not prove that reboot always resolves the condition.

v0.2.3 adds runtime assessment rather than changing charging control. Regression
tests replay sanitized versions of charging-above-target and idle-at-100% states,
plus recovery, unknown telemetry, AC disconnection and near-target idle readings.
A fresh live calibration event under v0.2.3 has not been induced or observed.
On this build, installed v0.2.3 correctly reported `policy=registered`,
`runtime=consistent` and `discharging_to_target` during AC-connected discharge.
Running the unchanged `hold 50` request read actual telemetry and reported a
no-write observation. The saved system value remained 50%; target metadata and
original-backup file hashes were identical before and after installation/hold.

Tests cover configuration parsing, saved intent, replacement of pending targets,
partial writes and rollback, native API failures, policy verification and CLI argument
rejection. They use fake clients for writes and do not alter charging settings.
