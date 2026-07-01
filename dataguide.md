# 数据整合指南

本指南用于把本项目的数据集整理成 `rawdata` 压缩包，并在另一台电脑上解压、导入到 OpenClaw-IntentBench 项目中。

适用场景：

1. 当前电脑已经有完整 `rawdata/` 文件夹；
2. 另一台电脑已经 clone 或拷贝了本项目代码；
3. 希望不重新下载 AutoElicit、MisActBench、OSWorld 等数据和参考仓库；
4. 希望 `rawdata/` 只作为本地数据包，不进入 Git 跟踪。

## 1. 当前数据集位置

当前项目中的数据集和任务数据主要在以下位置。

| 数据源 | 原始位置 | `rawdata` 副本位置 | 作用 |
|---|---|---|---|
| OCIB 主任务 manifest | `data/ocib_tasks.jsonl` | `rawdata/data/ocib_tasks.jsonl` | 当前正式实验入口，13 条任务 |
| OCIB smoke manifest | `data/ocib_tasks.smoke.jsonl` | `rawdata/data/ocib_tasks.smoke.jsonl` | smoke test 入口，6 条任务 |
| OCIB 手工任务 | `ocib_automation/tasks.handcrafted.jsonl` | `rawdata/ocib_automation/tasks.handcrafted.jsonl` | 手工构造的基础任务 |
| AutoElicit-Bench | `data/raw/autoelicit_bench.jsonl` | `rawdata/data/raw/autoelicit_bench.jsonl` | 良性输入导致 CUA 非预期行为的主数据来源 |
| AutoElicit-Seed | `data/raw/autoelicit_seed.jsonl` | `rawdata/data/raw/autoelicit_seed.jsonl` | AutoElicit seed perturbations |
| AutoElicit-Exec | `data/raw/autoelicit_exec.jsonl` | `rawdata/data/raw/autoelicit_exec.jsonl` | AutoElicit 执行轨迹和错误参考 |
| MisActBench | `data/raw/MisActBench/` | `rawdata/data/raw/MisActBench/` | action alignment 标签、轨迹和截图压缩包 |
| AutoElicit 参考仓库 | `data/raw/repos/AutoElicit/` | `rawdata/data/raw/repos/AutoElicit/` | AutoElicit 官方代码和参考实现 |
| Misaligned-Action-Detection 参考仓库 | `data/raw/repos/Misaligned-Action-Detection/` | `rawdata/data/raw/repos/Misaligned-Action-Detection/` | MisActBench 代码和标签格式参考 |
| OSWorld 参考仓库 | `data/raw/repos/OSWorld/` | `rawdata/data/raw/repos/OSWorld/` | OS/CUA 环境和任务组织参考 |

`results/` 和 `runs/` 是实验运行结果，不属于数据集导入的必要输入。如果需要复现实验过程证据，可以另外备份它们，但不要混入基础数据包。

## 2. `rawdata` 标准目录结构

推荐的 `rawdata/` 结构如下。

```text
rawdata/
  data/
    ocib_tasks.jsonl
    ocib_tasks.smoke.jsonl
    raw/
      autoelicit_bench.jsonl
      autoelicit_seed.jsonl
      autoelicit_exec.jsonl
      MisActBench/
        README.md
        misactbench.json
        trajectories.zip
      repos/
        AutoElicit/
        Misaligned-Action-Detection/
        OSWorld/
  ocib_automation/
    tasks.handcrafted.jsonl
```

注意：`rawdata/` 已写入 `.gitignore`，不会被 Git 跟踪。它适合作为本地压缩包、网盘文件、SCP 文件或对象存储文件，不建议提交到代码仓库。

## 3. 在当前电脑打包 `rawdata`

在项目根目录运行：

```bash
cd /home/zzz/misattach
tar -czf rawdata.tar.gz rawdata
```

如果目标电脑更方便使用 zip，也可以：

```bash
cd /home/zzz/misattach
zip -r rawdata.zip rawdata
```

打包后建议做一次检查：

```bash
tar -tzf rawdata.tar.gz | head
tar -tzf rawdata.tar.gz | grep 'rawdata/data/ocib_tasks.jsonl'
tar -tzf rawdata.tar.gz | grep 'rawdata/data/raw/autoelicit_bench.jsonl'
```

如果使用 zip：

```bash
unzip -l rawdata.zip | head
unzip -l rawdata.zip | grep 'rawdata/data/ocib_tasks.jsonl'
```

## 4. 在另一台电脑解压

先准备项目目录。假设另一台电脑上的项目路径为：

```bash
cd ~/misattach
```

把 `rawdata.tar.gz` 放到项目根目录后解压：

```bash
tar -xzf rawdata.tar.gz
```

如果是 zip：

```bash
unzip rawdata.zip
```

解压后应看到：

```bash
ls rawdata
ls rawdata/data/raw
ls rawdata/data/raw/repos
```

预期输出中至少应包含：

```text
rawdata/data
rawdata/ocib_automation
rawdata/data/raw/autoelicit_bench.jsonl
rawdata/data/raw/autoelicit_seed.jsonl
rawdata/data/raw/autoelicit_exec.jsonl
rawdata/data/raw/MisActBench
rawdata/data/raw/repos/AutoElicit
rawdata/data/raw/repos/Misaligned-Action-Detection
rawdata/data/raw/repos/OSWorld
```

## 5. 导入到项目目录

如果新电脑上的项目还没有完整 `data/`，可以直接导入：

```bash
mkdir -p data
cp -a rawdata/data/. data/

mkdir -p ocib_automation
cp -a rawdata/ocib_automation/tasks.handcrafted.jsonl ocib_automation/tasks.handcrafted.jsonl
```

如果项目中已经有 `data/`，建议先备份再导入：

```bash
mkdir -p backups/data_before_import
cp -a data backups/data_before_import/

mkdir -p data
cp -a rawdata/data/. data/
cp -a rawdata/ocib_automation/tasks.handcrafted.jsonl ocib_automation/tasks.handcrafted.jsonl
```

导入完成后，关键路径应为：

```text
data/ocib_tasks.jsonl
data/ocib_tasks.smoke.jsonl
data/raw/autoelicit_bench.jsonl
data/raw/autoelicit_seed.jsonl
data/raw/autoelicit_exec.jsonl
data/raw/MisActBench/
data/raw/repos/AutoElicit/
data/raw/repos/Misaligned-Action-Detection/
data/raw/repos/OSWorld/
ocib_automation/tasks.handcrafted.jsonl
```

## 6. 导入校验

先检查目录：

```bash
ls data
ls data/raw
ls data/raw/MisActBench
ls data/raw/repos
```

再检查关键 JSONL 行数。当前数据包的预期行数如下：

```bash
wc -l \
  data/ocib_tasks.jsonl \
  data/ocib_tasks.smoke.jsonl \
  data/raw/autoelicit_bench.jsonl \
  data/raw/autoelicit_seed.jsonl \
  data/raw/autoelicit_exec.jsonl \
  ocib_automation/tasks.handcrafted.jsonl
```

预期结果：

```text
13  data/ocib_tasks.jsonl
6   data/ocib_tasks.smoke.jsonl
117 data/raw/autoelicit_bench.jsonl
361 data/raw/autoelicit_seed.jsonl
132 data/raw/autoelicit_exec.jsonl
6   ocib_automation/tasks.handcrafted.jsonl
```

检查 MisActBench 文件：

```bash
test -f data/raw/MisActBench/misactbench.json
test -f data/raw/MisActBench/trajectories.zip
```

检查三个参考仓库：

```bash
test -d data/raw/repos/AutoElicit
test -d data/raw/repos/Misaligned-Action-Detection
test -d data/raw/repos/OSWorld
```

检查 `rawdata/` 是否仍然不会被 Git 跟踪：

```bash
git status --ignored --short rawdata
```

如果输出类似下面这样，说明忽略规则生效：

```text
!! rawdata/
```

## 7. 可选：重新构建 manifest

如果只是恢复当前可运行数据，不需要重新构建，直接使用：

```text
data/ocib_tasks.jsonl
data/ocib_tasks.smoke.jsonl
```

如果希望基于导入后的 `data/raw/` 重新生成 manifest，可以运行：

```bash
python ocib_automation/build_manifest.py \
  --config ocib_automation/config.example.json \
  --out data/ocib_tasks.jsonl \
  --limit-autoelicit 40
```

注意：重新构建可能改变 `data/ocib_tasks.jsonl` 的任务数量或顺序，应在实验记录中注明。

## 8. 常见问题

### 解压后多了一层目录

如果出现：

```text
rawdata/rawdata/data/...
```

说明压缩包里已经带了 `rawdata/`，但又解压到了一个手动创建的 `rawdata/` 目录里。可以把内层内容移动到外层，或者重新在项目根目录解压。

### `data/raw/repos` 为空

说明压缩包没有包含外部参考仓库缓存。此时实验 manifest 仍可能能运行，但无法离线查看 AutoElicit、MisActBench 和 OSWorld 的参考代码。建议重新打包完整 `rawdata/`。

### `trajectories.zip` 缺失

`MisActBench` 的动作级标签仍在 `misactbench.json` 中，但轨迹截图证据缺失。需要从原始电脑重新复制：

```text
data/raw/MisActBench/trajectories.zip
```

### Git 显示大量 `rawdata` 文件

确认 `.gitignore` 中包含：

```text
rawdata/
```

如果已经误加入暂存区，需要先取消暂存：

```bash
git restore --staged rawdata
```

不要提交 `rawdata/`，它是本地数据包，不是代码仓库内容。

## 9. 推荐工作流

推荐在源电脑执行：

```bash
cd /home/zzz/misattach
tar -czf rawdata.tar.gz rawdata
```

把 `rawdata.tar.gz` 传到目标电脑后执行：

```bash
cd ~/misattach
tar -xzf rawdata.tar.gz
cp -a rawdata/data/. data/
cp -a rawdata/ocib_automation/tasks.handcrafted.jsonl ocib_automation/tasks.handcrafted.jsonl
wc -l data/ocib_tasks.jsonl data/raw/autoelicit_bench.jsonl ocib_automation/tasks.handcrafted.jsonl
```

确认行数正常后，就可以继续按照 `OpenClaw-IntentBench_实验操作指南.md` 配置环境并运行实验。
