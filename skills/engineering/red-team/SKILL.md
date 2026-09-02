---
name: red-team
description: Take apart any target — an app, a feature, a plan, a document, a decision — with parallel adversarial agents. A blue-team rebuttal pass then kills the weak findings, and only the survivors reach the user. Use when the user says "red team this", "attack this", "tear this apart", "stress-test this", or asks for an adversarial review of anything.
---

Run an adversarial review in two waves. An **attack wave** of tailored red-team agents takes the target apart. A **defense wave** tries to kill every finding. Report only what survives, ranked, in chat. After scoping, the run is unattended end-to-end. Assume it runs overnight and the user reads the result in the morning.

## 1. Pin the target

The argument is free-form: a path, a branch, a URL, a running app, "the plan we just discussed", anything. If there is no argument, take the target from what the conversation was just working on. If the target is not clear from context, ask. Never guess a target.

## 2. Front-load every question

Ask everything **once, up front, in a single round**. A run that pauses at 10% on a question wastes the whole night. Clarify as needed:

- Is hands-on testing in scope (agents execute or drive the target), or argumentative only?
- Is the target live and stateful? Is a disposable instance available, or can you create one?
- Is destructive testing sanctioned? What exactly is off-limits?
- What does the user consider out of scope or already known?

Skip this round when the answers are obvious. Example: a plan document is argumentative only, with nothing to break. After this point, **do not pause until the run is over**. See §7 for mid-run surprises.

## 3. Draft the attack angles

Classify the target. Then draft **3–6 attack angles** shaped to it. [PERSONAS.md](PERSONAS.md) is inspiration and a quality bar, not a roster. A plan gets an assumption attacker and a premortem. An app gets an input fuzzer and a security attacker. Echo a one-paragraph run statement to the user: target, mode, envelope, and the drafted angles. Then start. Do not wait for approval unless §2 raised something that needs consent.

## 4. Safety envelope

- **Argumentative is the baseline** for every target. Run hands-on attacks (execute the code, drive the UI, send malformed input) only against a runnable target. The user must have sanctioned them in §2.
- **Read and probe only, by default**: no deletes, no config writes, no data sent to third parties, no irreversible actions. Put this line verbatim into every hands-on attacker prompt.
- Run **destructive tests** only against disposable instances, or where necessary and explicitly sanctioned. Before any destructive work, establish a restore mechanism: a snapshot, a backup, or a fresh instance. Restore between sequential hands-on agents, so each starts from a clean baseline. Restore again when the run ends.
- **Concurrency**: attackers run in parallel by default. Hands-on agents that share one mutable instance (one UI, one running app, one device) run **sequentially**. Static-analysis agents can run next to a single driver. Two drivers need two instances.

## 5. Brief and spawn the attack wave

Write one **briefing file** to the session scratchpad. It contains: the target statement, how to reach the target (path, URL, instance, credentials pointer), and the safety envelope. For a conversation-borne target, include the full plan or decision text, because agents cannot see the conversation. All waves read the same frozen briefing.

Spawn the attackers in one message. Respect the §4 concurrency rules. Run each agent on **opus** unless the user said otherwise. Each prompt contains the briefing path, the agent's persona charter, and the finding schema:

- **Claim** — one sentence: what breaks or is wrong.
- **Attack path** — a concrete scenario: inputs, state, steps, and the bad outcome. **No scenario, no finding.** An attacker who cannot state the steps to the bad outcome does not get to file it.
- **Evidence** — a file:line reference, reproduced output, or quoted target text. A hands-on finding must state what the agent observed.
- **Severity** — `critical` / `major` / `minor`, by impact if the attack lands.

## 6. Defense wave

First merge overlapping findings across attackers, so no claim gets rebutted twice. Then spawn **one defender per attacker's findings batch**. An attacker with zero findings gets no defender. Keep the total run at 12 agents or fewer. A defender gets the briefing and the findings only — **not** the attacker's reasoning. Its job is to kill each finding: "X already handles this", "that input cannot occur", "the scenario contradicts the stated constraints". Each finding leaves with a verdict: `confirmed` / `contested` / `killed`.

## 7. Mid-run surprises

Agents can discover mid-run that they need an unsanctioned action. Example: only a destructive test can settle a finding. **Do not stop the world.** Finish all sanctioned work first. Then surface the blocked avenue: as a question if the user is present, otherwise as an *untested avenues* section in the report.

## 8. Report

Deliver in **chat**. The usual follow-up is a fix round, and chat is where that starts. Structure:

1. Confirmed findings, ranked by severity.
2. Contested findings, each with the strongest rebuttal attached. The user is the final judge. Never silently drop a contested finding.
3. One line: how many findings the defense killed.
4. Untested avenues, if any (§7).

Keep intermediate artifacts in the scratchpad. Write a persistent report file only on demand, and then into the repo.

Close with an offer — an offer only — to plan fixes for the confirmed findings.
