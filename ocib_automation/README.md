# OCIB Automation Toolkit

This directory contains a lightweight automation scaffold for OpenClaw-IntentBench.

It is intentionally not hard-bound to a single OpenClaw CLI, because different Linux installations may expose OpenClaw through different commands, wrappers, or service APIs. Configure the actual command in `config.example.json`.

## Files

| Path | Purpose |
|---|---|
| `config.example.json` | Main experiment configuration; currently calls OpenClaw through the direct wrapper |
| `config.openclaw.direct.example.json` | Explicit direct-mode OpenClaw configuration for small pilot runs |
| `config.openclaw.docker.example.json` | Docker sandbox example for formal real OS/CUA runs |
| `config.mock.example.json` | Optional non-experiment mock configuration for pipeline debugging |
| `tasks.handcrafted.jsonl` | Small seed task set covering file, config, code, data, communication, and long-memory cases |
| `download_datasets.py` | Downloads AutoElicit, MisActBench, OSWorld, and candidate BLIND-ACT resources |
| `build_manifest.py` | Builds a unified OCIB task manifest |
| `run_experiment.py` | Runs G1/G2/G3/G4 episodes, records traces, snapshots workspaces, and writes deterministic judgments |
| `trace_recovery.py` | Recovers OpenClaw tool calls from session JSONL and applies action-level evidence rules |
| `analyze_results.py` | Aggregates IETR, AMR, HUIR, TIR, and TFE |
| `mock_agent.py` | Deterministic mock runner for non-experiment pipeline debugging only |
| `judge_prompt_template.md` | Prompt template for trajectory-level LLM judge |
| `sandbox/Dockerfile` | Minimal Docker sandbox template |
| `scripts/prepare_linux_env.sh` | Python environment setup helper |
| `scripts/run_smoke_test.sh` | OpenClaw smoke test using `config.example.json` |
| `scripts/build_sandbox_image.sh` | Builds the Docker sandbox image |
| `scripts/run_openclaw_in_docker_template.sh` | Example Docker wrapper for running OpenClaw in a restricted container |

## Minimal Setup

```bash
cd ~/ocib
python3 -m venv .venv
source .venv/bin/activate
pip install -r ocib_automation/requirements.txt
```

## Configure OpenClaw

The current `config.example.json` already calls OpenClaw via `scripts/run_openclaw_direct_template.sh`. If your OpenClaw CLI differs, edit `config.example.json`:

```json
"openclaw_command_template": "bash ocib_automation/scripts/run_openclaw_direct_template.sh {instruction_file} {workspace} {trace_file} {condition} {max_steps}"
```

Available placeholders:

```markdown
{instruction_file}
{workspace}
{trace_file}
{condition}
{task_id}
{max_steps}
{memory_mode}
{memory_prefix_length}
```

If your OpenClaw installation does not emit `trace.json`, set:

```json
"fail_on_missing_openclaw_trace": false
```

The deterministic physical checker will still inspect workspace diffs and mock mail outbox.
By default, the runner also tries to recover real OpenClaw tool calls from `~/.openclaw-ocib-direct/agents/.../sessions/*.jsonl` whenever the wrapper writes an empty placeholder trace. Recovered actions are written back to `trace.json` before `judgment.json` is generated.

## Xiaomi vLLM Endpoint

The direct wrapper defaults to:

```markdown
provider: vllm
model: xiaomi-v2.5-pro
base URL: http://127.0.0.1:8000/v1
```

Start the local Xiaomi OpenAI-compatible proxy before running real OpenClaw episodes:

```bash
export OPENAI_API_KEY=<xiaomi_api_key>
bash ocib_automation/scripts/run_xiaomi_proxy.sh
```

The proxy exposes `xiaomi-v2.5-pro` to OpenClaw and, by default, forwards upstream requests as `xiaomi-v2.5-pro`. Override when needed:

```bash
XIAOMI_PROXY_MODEL=xiaomi-v2.5-pro \
XIAOMI_TARGET_MODEL=xiaomi-v2.5-pro \
XIAOMI_PROXY_PORT=8000 \
bash ocib_automation/scripts/run_xiaomi_proxy.sh
```

You can also override the OpenClaw wrapper without editing files:

```bash
OCIB_OPENCLAW_PROVIDER=vllm \
OCIB_OPENCLAW_MODEL=xiaomi-v2.5-pro \
OCIB_MODEL_BASE_URL=http://127.0.0.1:8000/v1 \
ocib_automation/scripts/run_ocib_openclaw.sh quick
```

## Real OS/CUA Safety Gate

`G2` and `G4` are real OS/CUA conditions. The default config uses `sandbox_backend: "direct"` so that tiny pilot runs can work on a machine that has OpenClaw but no Docker/VM isolation. In this mode the runner prints a warning and the result should not be described as a strongly sandboxed formal real-OS experiment.

For formal runs, switch to a sandboxed config such as:

```bash
python ocib_automation/run_experiment.py \
  --config ocib_automation/config.openclaw.docker.example.json \
  --manifest data/ocib_tasks.jsonl \
  --conditions G1 G2 G3 G4
```

Set `"real_os_requires_sandbox": true` in any formal config. The runner will refuse `G2/G4` if the command template does not appear to use Docker/Podman/VM/Firejail/bubblewrap-style isolation.

## Recommended Order

```bash
python ocib_automation/download_datasets.py --all --data-dir data/raw
python ocib_automation/build_manifest.py --out data/ocib_tasks.jsonl --limit-autoelicit 40
python ocib_automation/run_experiment.py --manifest data/ocib_tasks.jsonl --conditions G1 G2 G3 G4
python ocib_automation/analyze_results.py --runs-dir runs --out-dir results
```

`analyze_results.py` writes:

| Path | Purpose |
|---|---|
| `results/episode_results.csv` | One row per deduped episode, including intent-error and task-success proxy fields |
| `results/summary_by_condition.csv` | Main G1/G2/G3/G4 metric table |
| `results/summary_by_category.csv` | Metrics grouped by task category |
| `results/summary_by_category_condition.csv` | Metrics grouped by category and condition |
| `results/factorial_effects.csv` | OS/CUA, long-horizon, and interaction effects when all G1-G4 are present |
| `results/summary.md` | Human-readable summary with Task Success and factorial effects |

The automatic `TaskSuccess` column is a proxy derived from `returncode == 0` and no deterministic intent error unless a `judgment.json` provides an explicit `task_success`. Use the LLM judge and human audit from the experiment guide for paper-quality task-success claims.

`run_experiment.py` defaults to resumable execution. For each requested episode it derives a stable key from:

```markdown
task_id + condition + memory_mode + memory_prefix_length
```

If `runs/` already contains a compatible complete run for that key, with matching task hash, command template, metadata, required artifacts, and `returncode=0`, the runner prints `SKIP ...` and reuses that artifact instead of running OpenClaw again. Failed, incomplete, or incompatible candidates are left in place and rerun into a new run directory.

To force a clean rerun of completed episodes:

```bash
python ocib_automation/run_experiment.py \
  --manifest data/ocib_tasks.jsonl \
  --conditions G1 G2 G3 G4 \
  --no-resume
```

`analyze_results.py` also deduplicates by episode key by default, keeping the latest successful row when retries exist. Use `--include-duplicates` only when you explicitly want every historical run directory counted.

## Static Validation

```bash
python -m py_compile \
  ocib_automation/download_datasets.py \
  ocib_automation/build_manifest.py \
  ocib_automation/trace_recovery.py \
  ocib_automation/mock_agent.py \
  ocib_automation/run_experiment.py \
  ocib_automation/analyze_results.py
```

## Notes

- G1/G3 are mock tool conditions, but the default runner still calls real OpenClaw. Use `config.mock.example.json` only for non-experiment debugging.
- G2/G4 should be run in Docker, VM, OSWorld, or another rollback-capable sandbox when available. Current direct mode is weaker isolation.
- Do not mount a real home directory, real SSH keys, real mailboxes, real browser profiles, or production repositories.
- The toolkit produces deterministic first-layer judgments. For paper-quality results, add the LLM judge and 10% human audit described in the experiment guide.


## One-command OpenClaw Run

```bash
cd /home/zzz/misattach
ocib_automation/scripts/run_ocib_openclaw.sh check
ocib_automation/scripts/run_ocib_openclaw.sh quick
```

Modes: `quick`, `smoke`, `small`, `factorial-small`, `full`, `analyze`, `check`.
All default experiment modes call real OpenClaw through `config.example.json`.
