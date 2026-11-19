# battctl：AI 工作说明

本文替代根目录 README，供后续 AI 维护项目时读取。使用标准文件名
`AGENTS.md`，不要另建不同大小写的重复文件。

## 完成修改后的固定流程

用户已要求：每次完成一批项目修改后，自动检查、添加 coauthor、commit、push 并打版本 Tag，
无需为这些常规操作重复征求确认。

1. 先检查工作区、当前分支与远端差异，保留用户已有改动。
2. 完成与改动相关的验证。代码改动运行 `make test`；纯文档改动检查
   链接、引用与 `git diff --check`，不为纯文档反复运行代码测试。
3. 更新必要的技术说明、验证记录和本文件，区分已完成与待验证事项。
4. 检查提交范围和隐私，只暂存这次工作明确涉及的文件。
5. 每个由 AI 创建的提交必须包含以下 Git trailer：

   ```text
   Co-authored-by: Codex <codex@openai.com>
   ```

6. 使用仓库已配置的作者身份，保持隐私邮箱；提交说明描述最终变更及验证。
7. Push 到当前工作分支对应的远端。当前主分支是 `main`，远端为
   `origin`（`https://github.com/chenximengyi/battctl`，公开仓库）。不要强推、
   覆盖历史，或夹带与本次任务无关的更改。
8. 确认 push 成功，报告 commit 和未完成的硬件验证。遇到认证、冲突或
   检查失败，保留成果并说明阻碍，不把本地 commit 说成已推送。

9. 为本次版本创建带注释的 `vX.Y.Z` Tag 并推送。Tag、源码版本、CLI 输出与
   安装包版本必须一致。如果该版本已存在，按变更递增版本（通常为 patch），
   不移动或覆盖已有 Tag；不要重复发布同名不同内容的二进制。
10. 用户已授权自动发布 Release：在明确机型/构建号上已有当前版本可用的实测
    证据后，直接发布，无需重复询问。未完成硬件验证时，先准备草稿和附件，
    明确待验证项；收到验证结果后更新记录与说明再发布。
11. Release 页面必须自包含：变更摘要、机型/构建号/目标值验证范围、安装及
    升级方法、hold/重启/verify 流程、恢复方法、限制、下载包与 SHA256 校验。
    区分编译测试、偏好保存、重启生效、到达目标与睡眠保持，不把旧版本实测
    自动当作新版本验收，也不把运行时检查通过说成全面兼容。

发布使用 `scripts/package-release.sh`，只包含已提交源码与二进制。
创建后核对远端 Tag 指向、Release 状态、附件与下载校验值。私有路径仍应注明
支持边界；需要时保留 GitHub prerelease 标记。不自动重启用户电脑。

## 产品范围与不可回退的设计决策

- 本项目是 macOS 原生限充 CLI。用户只输入一个目标电量。
- 流程：保存目标 → 必要时用户正常重启 → macOS 自行充放电到目标附近并保持。
- 不重新引入区间循环、适配器反复切换、SMC 控制、后台充电控制器或看护进程。
- 不关闭 SIP、不注入或修改系统进程，不用压力测试主动耗电。
- 保存成功不等于策略生效。重启前旧上限仍可能允许继续充电。
- 不承诺永久精确保持某个百分比。系统校准、供电条件与临时覆盖会影响行为。

## 源码与接口

- `Sources/main.m`：参数、遥测、冲突检测、命令入口。
- `Sources/native.m`：PowerUI 私有接口的查询、原生设置与失败恢复。
- `Sources/persistent.m`：目标保存、兼容性检查、备份、回滚与有效策略核验。
- `Sources/telemetry.h`：只读取必要电池字段，注意无符号形式的负电流。
- `Sources/version.h`：CLI 版本；同步更新 `tests/cli.sh` 的版本断言。
- `tests/`：使用模拟对象测试写入；测试不得改变本机充电设置。

命令契约：

| 命令 | 行为 |
| --- | --- |
| `sudo battctl hold TARGET` | 保存 20–99 的整数目标，核验并提示是否重启 |
| `battctl verify [TARGET] [--json]` | 默认核验已保存目标，不一致时返回非零 |
| `battctl status [--json]` | 读取电量、电流、接电及盖子状态 |
| `battctl doctor [--json]` | 查询原生选择值、有效策略与冲突 |
| `battctl monitor [TARGET] [--json]` | 每 30 秒只读核验，退出不影响限充 |
| `sudo battctl restore` | 恢复首次备份值并核验，失败时保留恢复资料 |

`hold-native` / `verify-native` 已更名；`native-limit`、`watch`、`run`、
`reset` 和 adapter 命令已删除。100% 目前使用系统设置，不接受 `hold 100`。
当前 `hold` 对原生档位也走偏好保存路径，尚未实现按档位即时设置。

## 状态与兼容性规则

- PowerUI 即时接口在既有实测中拒绝 50%；启动读取私有偏好的路径可加载 50%。
- 原生报告的档位为 80/85/90/95/100。不能从 CLI 接受参数推断任意目标已验证。
- v0.2.2 保留 `MacBookPro18,1` 机型范围，取消精确构建号白名单。
- 写入前要求原生接口可读、功能开启、偏好合法、当前选择值与实际手动策略一致，
  且原始恢复值仍受接口支持。异常时拒绝修改，不能为通过检查而伪造成功。
- 检查当前有效值，不能把“当前 80%、待设置 50%”本身误判为不兼容。
- 后续系统更新不能仅因构建号变化而被拒绝；运行时检查也不代表该版本硬件验收完成。
- v0.2.3 用 `policy_registered` 表示登记一致，用 `runtime_status` 表示当次行为。
- `verification_passed` 和兼容字段 `policy_active` 仅在登记一致、接电且当次电池
  行为符合目标时为true。高于目标仍充电或静止、遥测未知、未接电时不能报告成功。
- `system_override=unknown`：CLI 仍无可靠的实时覆盖检测，不从电流推断确定原因；
  校准类覆盖可用系统日志确认，但不能据此让 JSON 断言原因。
- 校准请求不会因充电中途重启而清除；只有满充被电量计记账后才可能解除，
  重启本身不是恢复手段。
- `hold` 必须读取真实遥测；登记匹配时不重复写入，但运行状态未验证返回1并给出
  指引，不能再一律说无需重启。新目标保存等待重启仍返回0，含义只是保存成功。
- 恢复及兼容性检查使用登记一致性，不依赖当次电流。
- `near_target` 仅表示一次读数接近目标，不能证明长期保持或深睡眠期间行为。

系统偏好：root 的 `com.apple.smartcharging.topoffprotection` 中
`mclLimitValue`。目标元数据：`/Library/Preferences/com.chenxi.battctl.plist`。
原始备份：`/Library/Application Support/battctl-reboot-test/previous-limit`。
保留历史路径；原始备份不能被后续目标覆盖。失败应恢复本次修改前的值。
缺少目标元数据的旧安装默认核验 50%，不能把当前系统值自动当作用户意图。
用户在系统设置选新上限会覆盖实际策略；此时 `verify` 非零不等于进程崩溃。

## 版本谱系

本仓库于 2026-11-12 以新身份重建并重新开始编号，首个公开版本为 `v0.1.0`。
`docs/releases/previous-lineage-v0.2.2.md`、
`docs/releases/previous-lineage-v0.2.3.md` 及 `CHANGELOG.md` 中
0.1.0 以下的历史条目来自重建前的旧仓库谱系，作为机制与验证证据保留，
不对应本仓库的版本号。旧谱系使用的偏好路径为旧标识，不适用于当前版本；
本仓库使用的标识为 `com.chenxi.battctl`，安装脚本会把旧路径的目标文件迁移过来。

## 验证记录与下一步

- `26A428`：50% 完成开盖、合盖与睡眠唤醒验证；70% 有充到目标及保持记录，
  未完成同等级睡眠验证。详见 `docs/validation.md`。
- `26A434` / macOS 27.0.1：v0.2.2已完成50%重启加载、接电放电到目标及
  重复50%/0mA读数；已公开预发布。新构建号完整睡眠验收仍未完成。
- 此后系统电量估算校准临时覆盖50%，充满后仍停在100%/0mA，登记未变；
  用户正常重启后充满请求变为0，恢复接电放电。不能保证每次重启都能恢复。
- `26B131` / macOS 27.2.1：距上次满充约21天后系统再次自行发起充满校准，
  日志明确 `Charge To Full System Level Request:1` 与
  `SOC limit policy suspend due to mitigation active:1`；PowerUI 报
  `ChargingUpForGauging`、MCL target 50%、`chargingOverrideAllowed: 0`。
  注册值、两个 manual-limit 条目与目标文件全程仍为50%。在61%与99%两次正常
  重启均未清除，开机后重新发起；充到100%后再重启，日志转为
  `Last full charge date was 0.0 days ago too recent` 与
  `charge to full requested:0`，恢复接电放电且 verify 通过。属预期维护行为，
  不是策略丢失，重复 `hold` 无效。详见 `docs/validation.md`。
- 覆盖检测调研：`smartChargingUIState:chargeLimit:chargingOverrideAllowed:withError:`
  在26B131上校准中返回18、正常放电返回16；两次返回的 chargeLimit 都是100，
  语义未验证且样本不足，暂不写入 JSON，继续保留 `system_override=unknown`。
- v0.2.3修正状态判定及提示；历史异常用脱敏回归测试复现。尚未在新版下经历
  新一轮真实校准，不能把回归测试写成新一轮硬件验收。详见 `docs/validation.md`。
- v0.2.3本机安装后，verify正确识别接电放电，hold 50读取真实遥测并报告无须
  重复写入；操作前后系统保存值仍为50%，目标文件及原始备份的校验值不变。
- 发布说明：`docs/releases/v0.1.0.md`。旧谱系的 Tag 与安装包不在本仓库。

## 构建、安装与本机记录器

`make test` 构建并运行全部测试及 shell 语法检查。

本仓库不设 CI（`.github/workflows/` 已于 2026-11-19 删除），不要重新添加。
有效验证只能在 `MacBookPro18,1` 与当前测试构建号上完成，托管 runner 无法验证
任何限充行为；此前的 macOS 工作流只重复本地 `make test`，还因 arm64 池排队
15 分钟分配不到机器而两次误判失败。要证明编译通过，用干净检出跑 `make test`。

`sudo ./scripts/install.sh` 安装至 `/Library/Application Support/battctl/battctl`，
入口为 `/usr/local/bin/battctl`；安装本身不改变目标，不创建充电控制守护进程。
卸载脚本先恢复原上限，恢复失败时保留程序与备份。

`scripts/record-test.sh start|stop|status` 管理可选的只读 LaunchAgent
`com.chenxi.battctl.monitor`。登录执行一次、清醒时每分钟运行 `verify --json`。
它与限充无关，目标不一致时会以 1 退出；不要误当成崩溃或必需的控制服务。
停止记录保留日志且不改充电设置。不要未经任务需要重新启用它。

## 隐私与补充资料

- `research/`、构建产物、原始日志、时间序列、系统转储、个人路径和设备标识
  不提交、不上传。继续使用 `.gitignore`，禁止强制加入研究目录。
- 公开验证记录只保留判断兼容性必要的脱敏信息，见 `docs/validation.md`。
- 技术机制与恢复语义见 `docs/macos-27-battery.md`；历史变更见 `CHANGELOG.md`。
- `docs/README.en.md` 保留已有英文操作参考；根目录不再维护面向用户的 README。
- `scripts/package-release.sh` 仅打包已提交的公开文件；不覆盖已有版本的 tag/产物。
- GPL-2.0；保留 `LICENSE` 和 `THIRD_PARTY.md`，不复制第三方私有实现。
