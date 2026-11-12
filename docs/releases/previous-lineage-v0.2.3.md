> 本文件属重建前的旧仓库谱系，作为机制与验证证据保留；其中的版本号与偏好路径不对应本仓库。

# v0.2.3 — 修正校准充满后的限充状态误判

当50%目标仍登记在系统中，但系统校准使电池充到100%并停留时，旧版仍会显示
`policy=active`，且 `hold 50` 会提示无需重启。此版本分别检查策略登记和真实
电池读数，报告运行状态不符或未知，并提供处理指引。

## 变更

- `hold` 使用与 `verify` 相同的真实电池遥测，不再拿空电池数据判断成功。
- 目标相同且已登记时不重复写入；高于目标仍充电或静止时，返回1并提示核查
  系统覆盖，不再承诺“无需重启”。
- `verify` / `doctor` 仅在登记一致且当次接电行为符合目标时返回0。
- 保留原生偏好保存、备份与正常重启流程，不取消系统校准，不增加后台控制。

## 使用范围与证据

| 环境或测试 | 结果与边界 |
| --- | --- |
| MacBookPro18,1 / M1 Pro / macOS 27.0.1 / 26A434 | v0.2.3本机查询正确识别50%登记目标及接电放电；同目标hold读取真实状态且未修改偏好或备份 |
| 旧版v0.2.2，同构建号 | 已观察重启加载50%、放电至目标及短时保持；后来系统校准覆盖上限、充满停留，正常重启后重新放电 |
| 回归测试 | 覆盖高于目标仍充电、100%静止、正常放电、目标附近静止、遥测缺失、未接电和低于目标的状态 |
| 尚未验证 | v0.2.3下新一轮真实校准及完整睡眠/长期保持；其他机型、构建号和全部目标值 |

写入仍限于MacBookPro18,1，配置范围20–99%。不按精确构建号拒绝，仍进行
运行时兼容性检查。运行检查通过不是所有系统版本可用的保证。

## 新输出与兼容性

正常放电示例：

```text
target=50% registered_limit=50% policy=registered runtime=consistent phase=discharging_to_target
```

100%停止放电但登记目标仍为50%时：

```text
target=50% registered_limit=50% policy=registered runtime=inconsistent phase=above_target_idle
```

- `policy_registered`：仅确认目标与系统登记一致。
- `runtime_status`：`consistent` / `inconsistent` / `unknown`，只描述当次读数。
- `verification_passed`：登记一致、没有读取错误、当次行为符合目标。
- **JSON兼容性变化**：保留的 `policy_active` 现在等同 `verification_passed`，
  不再仅表示登记一致。脚本若只关心登记，请改读 `policy_registered`。
- `system_override=unknown`：没有经验证的实时校准检测；不能单凭电流判断
  是否校准。异常提示给出可能原因，不把猜测当成确定诊断。
- `verify`/`doctor` 对未接电、未知遥测、目标以下静止等状态也返回1，表示
  当次无法验证，不一定是设备异常。短时状态可能变化，可稍后重新查询。
- `hold` 新目标保存成功、等待重启时仍返回0；同目标已登记但当次行为不符或
  未知时返回1。注意区分“已保存等待重启”和“行为核验通过”。

## 下载与安装

从本页附件下载 `battctl-v0.2.3-macos-arm64.tar.gz` 和 `SHA256SUMS`，
放在同一目录执行：

```sh
shasum -a 256 -c SHA256SUMS
tar -xzf battctl-v0.2.3-macos-arm64.tar.gz
cd battctl-v0.2.3-macos-arm64
sudo ./scripts/install.sh
battctl --version
```

安装到 `/Library/Application Support/battctl/battctl`，命令入口为
`/usr/local/bin/battctl`。安装保留原目标和备份，本身不改变充电设置。
升级用户也使用上述安装步骤。

安装包包含对应Tag的源码和 `SOURCE_COMMIT`。程序未做Developer ID签名或公证；
如被系统阻止，可在已安装Apple Command Line Tools的Mac上从包内源码执行
`make test` 后再安装，不要求关闭Gatekeeper或SIP。

## 设置与确认

首次使用前，在系统设置启用原生充电上限并选择80%，结束临时充满覆盖，
停用其他电池控制程序。然后执行：

```sh
sudo battctl hold 50
# 若提示策略尚未生效：保存工作，由你正常重启Mac
battctl verify 50
battctl status
```

插着电源正常使用即可，不需要CLI常驻或压力测试耗电。修改目标可执行
`sudo battctl hold 70` 并按提示重启；已保存且已生效的同一目标无需重复重启。
核验通过仅代表登记一致、当次接电读数符合目标；仍需观察到达目标、合盖与睡眠唤醒。电量可能正常小幅波动。

`battctl doctor --json` 用于排查。`verify` 返回非零表示目标尚未核验通过，
不一定是程序崩溃；例如系统设置改成80%、CLI目标仍为50%时就会发生。
当前 `hold 80/85/90/95` 也只走保存路径；临时充满或100%请使用系统设置。

## 恢复与卸载

```sh
sudo battctl restore
# 仅在以前启用过记录器时执行；不要加sudo
./scripts/record-test.sh stop
sudo ./scripts/uninstall.sh
```

`restore` 恢复首次备份的系统上限，未必是80%；根据输出确认恢复是否生效。
原备份位于 `/Library/Application Support/battctl-reboot-test/previous-limit`，
不要手动删除。恢复失败时保留程序和备份，根据提示检查或正常重启。

## 校准后的处理与限制

系统可能偶尔充满以校准电量估算，50%登记值不代表系统一定正在执行它。
先让系统完成校准；若已充满但持续不向目标放电，可保存工作、正常重启后
再次核验。本机曾观察重启恢复，但这不是通用保证。本版本不会强制结束
校准、自动重启、设置循环充放电，也不会持续后台监控。

使用Apple私有接口与偏好；后续更新可能改变行为。单次成功不能证明长期
锁电或排除所有覆盖。系统校准、适配器供电能力、临时充满及其他电池工具
均可能影响行为。拔电后正常消耗电池。无需关闭SIP或修改系统二进制。
GPL-2.0，详见包内LICENSE与THIRD_PARTY.md。
