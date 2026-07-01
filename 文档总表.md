# 文件总表

说明：本表按照 `papers/` 文件夹中的 PDF 顺序整理。论文作用主要参照 `OpenClaw-IntentBench_整合总结.md` 与 `OpenClaw-IntentBench_实验操作指南.md`；两份文档未明确给出处理方式的，统一标为“暂无处理”。

| 序号 | PDF 文件 | 论文标题 | 在本项目中的作用 | 备注 |
|---:|---|---|---|---|
| 01 | `papers/01_Blind_Goal_Directedness.pdf` | Just Do It!? Computer-Use Agents Exhibit Blind Goal-Directedness | BLIND-ACT 任务类型补充来源；用于补充 AUTOELICIT 覆盖不足的模糊任务、矛盾任务、上下文不足任务和盲目目标导向场景。 | 核心主依据之一 |
| 02 | `papers/02_Code_Agent_System_Hacker.pdf` | Code Agent can be an End-to-end System Hacker: Benchmarking Real-world Threats of Computer-use Agent | 暂无处理 |  |
| 03 | `papers/03_AgentAsk.pdf` | AgentAsk: Multi-Agent Systems Need to Ask | 相关工作背景；偏向多智能体澄清与请求补充信息，不作为主实验数据集。 |  |
| 04 | `papers/04_Check_Yourself_Quit_Safety.pdf` | Check Yourself Before You Wreck Yourself: Selectively Quitting Improves LLM Agent Safety | 暂无处理 |  |
| 05 | `papers/05_When_Refusals_Fail.pdf` | When Refusals Fail: Unstable Safety Mechanisms in Long-Context LLM Agents | 暂无处理 |  |
| 06 | `papers/06_Temporal_Constraints_LLM_Agents.pdf` | Enforcing Temporal Constraints for LLM Agents | 暂无处理 |  |
| 07 | `papers/07_Internal_Representations_Hallucinations.pdf` | Internal Representations as Indicators of Hallucinations in Agent Tool Selection | 暂无处理 |  |
| 08 | `papers/08_SafePro_Professional_Safety.pdf` | SafePro: Evaluating the Safety of Professional-Level AI Agents | 暂无处理 |  |
| 09 | `papers/09_AgentHallu_Hallucination_Attribution.pdf` | AgentHallu: Benchmarking Automated Hallucination Attribution of LLM-based Agents | 相关工作背景；偏向幻觉归因，不作为主实验数据集。 |  |
| 10 | `papers/10_Benign_Inputs_Severe_Harms.pdf` | When Benign Inputs Lead to Severe Harms: Eliciting Unsafe Unintended Behaviors of Computer-Use Agents | AUTOELICIT，主数据集基础；提供良性输入导致 CUA 非预期行为的任务来源、错误类型和判定参考。 | 核心主依据之一 |
| 11 | `papers/11_Actions_Off_Task_Misaligned.pdf` | When Actions Go Off-Task: Detecting and Correcting Misaligned Actions in Computer-Use Agents | MISACTBENCH，动作级意图偏离定义与标注标准；用于 action alignment / misaligned action 判定规则。 | 核心主依据之一 |
| 12 | `papers/12_AgentLAB_Long_Horizon_Attacks.pdf` | AgentLAB: Benchmarking LLM Agents against Long-Horizon Attacks | 辅助理论与对照论文；说明长程多轮交互中的目标漂移、上下文积累、工具链组合等结构性风险，支撑 G3/G4 长程条件设计。 |  |
| 13 | `papers/13_Mind_the_GAP_Tool_Call_Safety.pdf` | Mind the GAP: Text Safety Does Not Transfer to Tool-Call Safety in LLM Agents | 辅助理论与对照论文；说明文本安全不等于工具调用安全，因此评估必须检查工具调用、文件变化、shell 命令、网络请求和邮件发送等实际动作。 |  |
| 14 | `papers/14_ATBench_Trajectory_Benchmark.pdf` | ATBench: A Diverse and Realistic Agent Trajectory Benchmark for Safety Evaluation and Diagnosis | 辅助理论与对照论文；提供轨迹级评估设计、风险来源 / 失败模式 / 现实伤害分类，以及长上下文风险诊断参考。 |  |
| 15 | `papers/15_HiL_Bench_Ask_for_Help.pdf` | HiL-Bench (Human-in-Loop Benchmark): Do Agents Know When to Ask for Help? | 相关工作背景；偏向是否求助 / 何时请求人工帮助，不作为主实验数据集。 |  |
| 16 | `papers/16_AgentHazard_Harmful_Behavior.pdf` | AgentHazard: A Benchmark for Evaluating Harmful Behavior in Computer-Use Agents | 辅助理论与对照论文；支持设计工具链组合型无攻击任务，说明局部合理步骤可能组合成整体有害结果。 |  |
| 17 | `papers/17_Detecting_Safety_Violations_Traces.pdf` | Detecting Safety Violations Across Many Agent Traces | 暂无处理 |  |
| 18 | `papers/18_Human_Guided_Harm_Recovery.pdf` | Human-Guided Harm Recovery for Computer Use Agents | 相关工作背景；偏向事后恢复，不作为主实验数据集。 |  |
| 19 | `papers/19_Safety_Judgment_OOD_Scenarios.pdf` | Enhancing Agent Safety Judgment: Controlled Benchmark Rewriting and Analogical Reasoning for Deceptive Out-of-Distribution Scenarios | ROME / ARISE 参考；用于理解隐藏风险、上下文模糊与 shortcut decision-making，并辅助设计 OOD judge 挑战。 |  |
| 20 | `papers/20_LITMUS_Behavioral_Jailbreaks.pdf` | LITMUS: Benchmarking Behavioral Jailbreaks of LLM Agents in Real OS Environments | OpenClaw 真实 OS 工程框架参考；采用其 OS-level rollback、semantic verification、physical verification 和状态证据检查思想。 | 核心主依据之一 |
| 21 | `papers/21_ProjGuard_Low_Dim_Projections.pdf` | ProjGuard: Safety Monitoring for Computer-Use Agents via Low-Dimensional Projections | 暂无处理 |  |
| 22 | `papers/22_Intent_to_Execution_Integrity.pdf` | Securing LLM Agents Need Intent-to-Execution Integrity | 总体理论框架；用于描述从用户意图到最终执行动作的完整性，包括 instruction、judgment、tool 和 data flow integrity。 |  |
| 23 | `papers/23_Trust_No_Tool_Untrusted_Feedback.pdf` | Trust No Tool: Evaluating and Defending LLM Agents under Untrusted Tool Feedback | 辅助理论与对照论文；提醒记录工具反馈、信任形成、反馈错误泛化以及缺少确认时执行高影响动作等轨迹风险。 |  |
| 24 | `papers/24_AI_Agents_Prompt_Injections.pdf` | AI Agents May Always Fall for Prompt Injections | 辅助理论与对照论文；提供上下文完整性视角，支持通信、共享、审批、授权边界和多意图流混合场景设计。 |  |
| 25 | `papers/25_Remembering_More_Risking_More.pdf` | Remembering More, Risking More: Longitudinal Safety Risks in Memory-Equipped LLM Agents | 长程多轮与 OpenClaw memory 实验协议来源；采用 trigger-probe、NullMemory baseline、memory prefix length 等结构设计 G3/G4。 | 核心主依据之一 |
| 26 | `papers/26_TrustAgent.pdf` | MCA: Moment Channel Attention Networks | 暂无处理 | 当前 PDF 首页标题与文件名 `26_TrustAgent.pdf` 不一致。 |
| 27 | `papers/27_R_Judge_Safety_Risk_Awareness.pdf` | R-Judge: Benchmarking Safety Risk Awareness for LLM Agents | 辅助理论与对照论文；采用其轨迹日志结构思想，将 user instruction、agent thought/action 与 environment feedback 组织为 judge 输入。 |  |
| 28 | `papers/28_ToolEmu_LM_Emulated_Sandbox.pdf` | Identifying the Risks of LM Agents with an LM-Emulated Sandbox | 暂无处理 |  |
| 29 | `papers/29_AgentDojo_Prompt_Injection.pdf` | AgentDojo: A Dynamic Environment to Evaluate Prompt Injection Attacks and Defenses for LLM Agents | 暂无处理 |  |
| 30 | `papers/30_AgentHarm_Harmfulness.pdf` | AgentHarm: A Benchmark for Measuring Harmfulness of LLM Agents | 暂无处理 |  |
| 31 | `papers/31_Agent_SafetyBench.pdf` | AGENT-SAFETYBENCH: Evaluating the Safety of LLM Agents | 辅助理论与对照论文；提供任务类别、安全风险和常见 failure mode 的 taxonomy 补充，说明工具使用 Agent 需要行为级安全评估。 |  |
| 32 | `papers/32_Survey_Evaluation_LLM_Agents.pdf` | Survey on Evaluation of LLM-based Agents | 暂无处理 |  |
| 33 | `papers/33_Think_Twice_Thought_Correction.pdf` | Think Twice Before You Act: Enhancing Agent Behavioral Safety with Thought Correction | 暂无处理 |  |
| 34 | `papers/34_AgentAuditor_Human_Level_Safety.pdf` | AgentAuditor: Human-Level Safety and Security Evaluation for LLM Agents | 暂无处理 |  |
| 35 | `papers/35_AgentMisalignment_Propensity.pdf` | AgentMisalignment: Measuring the Propensity for Misaligned Behaviour in LLM-Based Agents | 暂无处理 |  |
| 36 | `papers/36_Beyond_Facts_Intent_Hallucination.pdf` | Beyond Facts: Evaluating Intent Hallucination in Large Language Models | 暂无处理 |  |
| 37 | `papers/37_Safety_Alignment_RL.pdf` | Agent Safety Alignment via Reinforcement Learning | 暂无处理 |  |
| 38 | `papers/38_Unintended_Misalignment_Agentic_FT.pdf` | Unintended Misalignment from Agentic Fine-Tuning: Risks and Mitigation | 暂无处理 |  |
| 39 | `papers/39_OS_Harm_Computer_Use_Safety.pdf` | OS-Harm: A Benchmark for Measuring Safety of Computer Use Agents | 暂无处理 |  |
| 40 | `papers/40_LLM_Agents_Hallucinations_Survey.pdf` | LLM-based Agents Suffer from Hallucinations: A Survey of Taxonomy, Methods, and Directions | 暂无处理 |  |
| 41 | `papers/41_Access_Control_Context_Space.pdf` | Secure and Efficient Access Control for Computer-Use Agents via Context Space | 暂无处理 |  |
| 42 | `papers/42_SafeSearch_Red_Teaming_Search.pdf` | SafeSearch: Automated Red-Teaming of LLM-Based Search Agents | 暂无处理 |  |
| 43 | `papers/43_Agentic_Misalignment_Insider_Threats.pdf` | Agentic Misalignment: How LLMs Could Be Insider Threats | 暂无处理 |  |
| 44 | `papers/44_Toxic_Proactivity_Behavioral_Misalignment.pdf` | From Helpfulness to Toxic Proactivity: Diagnosing Behavioral Misalignment in LLM Agents | 暂无处理 |  |
| 45 | `papers/45_HalluClear_GUI_Agents.pdf` | HalluClear: Diagnosing, Evaluating and Mitigating Hallucinations in GUI Agents | 暂无处理 |  |
| 46 | `papers/46_Useless_but_Safe_Utility_Recovery.pdf` | Useless but Safe? Benchmarking Utility Recovery with User Intent Clarification in Multi-Turn Conversations | 暂无处理 |  |
