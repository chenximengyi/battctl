# battctl v0.1.0 — native macOS charge limit

Save one target, restart normally if prompted, and let macOS charge or discharge
toward it and maintain it. No battery-control daemon, adapter switching or interval
cycling is included. Small normal fluctuations remain possible.

The private preference path is restricted to MacBookPro18,1, without an exact OS
build allowlist. Each write checks the native API, preferences, current effective
policy and recovery backup. Failed checks prevent writing. Passing these checks
does not establish successful boot loading or holding on a new OS version.
On 26A428, 50% completed open-lid, closed-lid and sleep/wake validation. 70% has observed
charging-to-target and holding results. Other configurable values remain unverified.

## Install and use

```sh
git clone https://github.com/chenximengyi/battctl.git
cd battctl
make test
sudo ./scripts/install.sh
sudo battctl hold 50
# Save work and restart normally if the requested policy is not active.
battctl verify
```

For first use, stop other battery tools, enable native Charge Limit in Battery
settings, select 80%, and finish temporary charging overrides. The first supported
limit is backed up before changes. Installation alone does not change that limit.

**A saved target is not necessarily active. Until restart, macOS still uses the old
limit and may continue charging to it.** No reboot is performed automatically.
Keep AC connected and use the Mac normally; no CLI process or stress load is needed.
An unchanged saved/requested/active target needs no further restart.

## Commands

| Command | Purpose |
| --- | --- |
| `sudo battctl hold TARGET` | Save integer target 20–99 and report whether restart is needed |
| `battctl status [--json]` | Read battery percentage, current, power, AC and lid state |
| `battctl verify [TARGET] [--json]` | Verify saved or explicit native target; nonzero on failure |
| `battctl monitor [TARGET] [--json]` | Verify every 30 seconds; Ctrl-C does not affect the policy |
| `battctl doctor [--json]` | Native selection, effective limits, supported values and conflicts |
| `sudo battctl restore` | Restore the original backed-up limit and verify recovery |
| `battctl --help` / `battctl --version` | Help / version |

`policy_registered` only confirms matching system records. `runtime_status`
separately reports consistent/inconsistent/unknown battery behavior. `verify`
returns 0 only for matching registration and a consistent AC-connected sample;
otherwise 1. `policy_active` in JSON now uses this stricter meaning.
A 100% idle battery with a registered 50% target is not successful verification.
`hold` reads telemetry too and will not claim that a matching target needs no reboot.
A new target saved for reboot still reports staging success separately.

macOS can temporarily override limits to charge fully for battery gauging, roughly
every three weeks when a charge limit keeps the battery away from full. The CLI
cannot identify that cause directly (`system_override=unknown`) and does not cancel
calibration. Let the battery reach 100% and stay connected while the gauge records
the full charge; restarting before that point re-issues the request after boot. In
observed cases a restart taken after the battery had reached 100% restored discharge
to the target, but this is not a guaranteed recovery method. Check again afterwards.

Use macOS Battery settings for temporary full charging. `near_target` describes
one sample, not proof of continuous holding. Unplugging allows normal battery use.

## Downloads and upgrades

[Releases](https://github.com/chenximengyi/battctl/releases) provide
`battctl-v0.1.0-macos-arm64.tar.gz` and `SHA256SUMS`:

See the release page for the exact tested model/build and remaining validation limits.

```sh
shasum -a 256 -c SHA256SUMS
tar -xzf battctl-v0.1.0-macos-arm64.tar.gz
cd battctl-v0.1.0-macos-arm64
sudo ./scripts/install.sh
```

The binary is not Developer ID signed or notarized. Build from source if blocked;
do not disable Gatekeeper or SIP. Installation provides `/usr/local/bin/battctl`.
v0.2.0 targets and original backups are preserved; an upgrade from an older bundle
identifier copies the saved target to the current preference path before installing. The installer also removes the
experimental controller from the abandoned development version, using its existing
recovery executable before deleting files. Restoring AC can resume charging under
the old native ceiling. Native preferences remain unchanged during cleanup.

Commands are now `hold` and `verify`; `hold-native` and `verify-native` only report
the new names. `watch`, `native-limit`, `run`, `reset` and adapter commands are removed.
Run `battctl doctor` after upgrading. No restart is required merely to upgrade the CLI.

## Restore, recording and uninstall

```sh
sudo battctl restore
./scripts/record-test.sh stop   # if enabled
sudo ./scripts/uninstall.sh
```

Keep the original backup at
`/Library/Application Support/battctl-reboot-test/previous-limit` for recovery.
The requested target is stored in `/Library/Preferences/com.chenxi.battctl.plist`.
Uninstall restores first; failure preserves the executable and recovery information.

Optional `./scripts/record-test.sh start|status|stop` provides read-only local
samples each minute while awake after login. It never controls charging or sleep.
Run `start` again after upgrading to update its binary. Logs remain in
`~/Library/Logs/battctl/`; remove private details before sharing them. No telemetry
is uploaded.

See [hardware validation](validation.md) and [technical notes](macos-27-battery.md).
Calibration, power supply limits, temporary charging overrides, OS updates and
other tools can change behavior. GPL-2.0; see [attribution](../THIRD_PARTY.md).
