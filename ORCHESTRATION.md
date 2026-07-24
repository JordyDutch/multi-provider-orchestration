<!-- markdownlint-configure-file { "MD013": false } -->

# ORCHESTRATION.md

How AI coding assistants should combine Claude Code and OpenAI Codex for the
strongest reliable result with focused, task-appropriate delegation.

This is the detailed, read-on-demand playbook. `AGENTS.md` contains the short
rules that load for both engines. Read this file before a substantial, risky,
multi-model, or multi-agent task; do not load it for every trivial edit.

## Principles

1. **Use a strong orchestrator for substantial work.** Codex-led work routes
   planning, delegation, integration, and final synthesis through GPT-5.6 Sol;
   Claude-led work routes those stages through Fable. The entry engine remains
   responsible for the result, and exactly one orchestrator owns the final
   decisions. Ownership does not make the other orchestrator unavailable: Sol
   may use Fable as a bounded complex-code or architecture reviewer, and Fable
   may use Sol for the corresponding Codex-side expert judgement.
2. **Use both providers from either entrypoint.** The orchestrator assigns the
   opposite provider at least one meaningful implementation, diagnosis, UX, or
   adversarial-review task. Both providers participate in every substantial
   task when available; entrypoint changes ownership, not the quality bar.
3. **Delegate by task fit.** The owning Sol/Fable tier plans and judges; the
   non-owning orchestrator can take a bounded expert or review task. Sol or Opus
   handles the hardest implementation; Terra handles normal scoped coding and
   read-heavy work; Luna/Sonnet handles mechanical support. The owner verifies
   every returned result before integrating it.
4. **Cross-check substantial work.** A second provider is required for
   consequential read-only analysis as well as non-trivial code and user-facing
   changes because independence catches a different class of mistakes. Skip it
   only for bounded deterministic work with no behavioral or factual consequence,
   or when the provider is unavailable.
5. **Verification beats extra sampling.** Run the relevant tests and inspect the
   actual diff before asking the reviewer to judge the result.
6. **Bound parallelism.** Fan out only independent work with clear ownership,
   small return formats, and a fixed stopping condition.

## Step 0: verify what is available

Binary presence is not enough. Check the active path, version, authentication,
and model catalog before writing commands that pin a model:

```sh
command -v claude
command -v codex
claude --version
codex --version
claude auth status
codex login status
codex debug models | jq -r '
  .models[]
  | select(
      .slug == "gpt-5.6-sol"
      or .slug == "gpt-5.6-terra"
      or .slug == "gpt-5.6-luna"
    )
  | [
      .slug,
      ("default=" + .default_reasoning_level),
      ("efforts=" + ([.supported_reasoning_levels[].effort] | join(",")))
    ]
  | @tsv
'
```

The filter keeps the live catalog check compact; raw `codex debug models` output
can include large base instructions and must not be loaded into agent context.
The command is currently an experimental diagnostic, so fall back to the
interactive `/model` selector when `jq` or a compatible CLI is unavailable. If
multiple Codex binaries exist, also run `which -a codex`; an app-bundled binary
can lag behind the one on `PATH`.

Authentication status alone does not prove model entitlement. Confirm access
through the first meaningful routed task and fall back once if the provider
rejects it; do not add a separate paid probe.

Treat a route as available only when the CLI is installed, authenticated, and
the requested model appears for that account. Do not repeatedly probe paid
models after an access failure. Fall back once and report the skipped route.

For a substantial task, check the orchestrator before planning:

- **Started in Codex:** switch the session to Sol for the full workflow. If the
  host cannot switch, invoke Sol once to plan and route, then invoke Sol again
  after worker/reviewer results to integrate and synthesize. Sol assigns
  Claude/Opus a meaningful normal task, or Fable a bounded complex review or
  expert-judgement task, and reconciles the cross-provider results.
- **Started in Claude:** switch to Fable for the full workflow. If the host
  cannot switch, invoke Fable once to plan and route, then invoke Fable again
  after worker/reviewer results to integrate and synthesize. Fable assigns
  Codex/Terra/Sol a meaningful task and reconciles the cross-provider results.
- **Switching or delegation unavailable:** use the strongest available active
  model, keep the workflow single-driver, and state which orchestration or review
  step could not run. Never claim that a hand-off happened when it did not.

Only bounded, deterministic tasks with no behavioral or factual consequence may
skip the separate orchestrator and second-provider call. The baseline applies
automatically as instruction policy; actual switching and cross-provider calls
still depend on the capabilities and entitlements of the host tool.

Both engines inherit `AGENTS.md`: Codex reads it natively and Claude receives it
through `CLAUDE.md`. A hand-off therefore needs only the task-specific context,
not a restatement of the full shared baseline.

## Current model routing

The GPT-5.6 baseline below was live-verified on 2026-07-10. Use full model IDs so
the selected capability tier is explicit, and reverify the catalog when a newer
family or Codex version ships.

| Tier | Model | Best use | Avoid as default for |
| ------ | ------- | ---------- | ---------------------- |
| **Frontier** | GPT-5.6 Sol (`gpt-5.6-sol`) | Codex orchestrator; hardest implementation, diagnosis, architecture, security, integration, and final judgement. | Inventory, extraction, formatting, or other mechanical support work. |
| **Everyday** | GPT-5.6 Terra (`gpt-5.6-terra`) | Repository mapping, read-heavy analysis, normal scoped implementation workstreams, tests, and supporting reviews. | Orchestration or final judgement on important work when Sol is available. |
| **Efficient** | GPT-5.6 Luna (`gpt-5.6-luna`) | Clear, repeatable, low-risk work with explicit success criteria: extraction, classification, transformation, structured summaries, and mechanical edits. | Ambiguous architecture, security decisions, or final review of critical changes. |
| **Claude orchestrator** | Fable 5 (`claude-fable-5`) | Claude orchestrator for planning, decomposition, integration, and final synthesis; bounded complex-code, architecture, or conflicting-findings review in a Sol-led workflow. | Mechanical execution or silently taking final ownership from Sol. |
| **Claude coding/review** | Opus 5 (`claude-opus-5`) | Substantive implementation, frontend/UX work, and independent review of GPT-authored changes. | Mechanical bulk work. |
| **Claude efficient** | Sonnet 5 (`claude-sonnet-5`) | Low-risk bulk reading, extraction, renames, and formatting. | Architecture or final judgement of important work. |

Claude model names and availability are also volatile. `claude-opus-5` was
live-verified on 2026-07-24 against Claude Code 2.1.219. Verify the other Claude
rows in the installed Claude Code environment before pinning them.

### Default routes by task

| Work | Codex route | Claude route | Opposite-provider review |
| ------ | ------------- | -------------- | -------------------------- |
| Bounded deterministic inventory, extraction, or mechanical edit with no behavioral/factual consequence | Luna `low`; Terra `medium` if judgement is needed | Sonnet `low`/`medium` | No |
| Substantial audit, research, repository analysis, or planning | Terra `high` workers; Sol orchestrates and synthesizes | Opus `high` workers; Fable orchestrates and synthesizes | Required |
| Small, well-tested implementation | Terra `medium`/`high`; Sol integrates | Opus `medium`/`high`; Fable integrates | Required unless bounded, deterministic, and without behavioral/factual consequence |
| Substantive implementation, tests, or debugging | Terra `medium` for normal scoped work, `high` when difficult; Sol `high` for the hardest scope | Opus `high`; Fable integrates | Required |
| Planning, routing, integration, or synthesis for a substantial task | Sol `high` | Fable `high` | Required |
| Contracts, permissions, funds, auth, security, migrations, costly architecture | Sol `xhigh`; `max` for the hardest remaining question | Fable or Opus at the strongest verified effort | Required at the strongest suitable tier |
| Hard diagnosis after failed attempts or conflicting reviews | Sol `xhigh`; exceptionally `max` | Strongest verified Claude tier at high effort | Required independent second opinion |
| Complex review of Codex-authored code, architecture, or conflicting findings | Sol owns integration | Fable `high`/`xhigh` as bounded independent reviewer | Required; Sol retains final ownership |
| Large task that divides into independent workstreams | Sol `ultra`, only when supported and quality benefits from fan-out | Explicit bounded workflow | Required synthesis and opposite-provider final review |

Claude remains the preferred frontend design and UX implementation engine when
both providers are available, unless the user requests another route.

## Codex reasoning effort

Current GPT-5.6 Codex catalogs expose `low`, `medium`, `high`, `xhigh`, `max`,
and, on supported models/accounts, `ultra`. The active catalog verified for this
kit exposes `ultra` for Sol and Terra but not Luna. Treat that detail as model-,
plan-, account-, and Codex-version-dependent rather than a permanent guarantee.

| Effort | Use it when | Guardrail |
| -------- | ------------- | ----------- |
| `low` | The task is narrow, well-scoped, or mostly tool execution. | Use for Luna scouts and mechanical support, not substantial final work. |
| `medium` | The task needs normal planning and checking. | Starting point for bounded Terra workers and limited Sol support work. |
| `high` | Multiple files, constraints, or tradeoffs require deeper reasoning. | Default for complex implementation and consequential planning. |
| `xhigh` | A difficult diagnosis, security review, or ambiguous design needs an extra-deep pass. | Use on a small, decisive stage rather than the entire workflow. |
| `max` | The hardest quality-first single-agent problem needs maximum depth. | Compare with `xhigh`; most tasks do not benefit enough to justify it. |
| `ultra` | A large task splits cleanly into meaningful independent subproblems. | This invokes automatic subagents. Use only at the top level, cap scope, and never nest it. |

These are Codex controls. The OpenAI API has a separate reasoning interface;
notably, API `reasoning.effort` supports exactly `none`, `low`, `medium`, `high`,
`xhigh`, and `max`, while Codex `ultra` is a multi-agent execution mode rather
than ordinary single-model reasoning. Do not copy API-only values into Codex CLI
examples without checking the live catalog.

### Escalation rules

- Repeatable support work: Luna `low` -> Luna `medium` -> Terra `medium`.
- Normal scoped coding: Terra `medium` -> Terra `high`, under the Sol/Fable
  orchestrator. Move the hardest implementation scope to Sol `high`.
- Critical judgement: Sol `high` -> Sol `xhigh` -> Sol `max` when additional
  depth can materially improve the decision.
- `ultra` is not the next rung after `max`. Choose it only when parallel
  decomposition is the reason for the escalation.
- Change one axis at a time. Do not jump from Luna `low` straight to Sol
  `ultra`, and do not rerun a successful task at every tier.

OpenAI recommends comparing representative GPT-5.6 tasks at the same effort and
one level lower. Treat that as an optional evaluation after the workflow works,
not as a blanket instruction to down-route; quality remains the constraint.

## Global installation

When the user asks to make this setup available in every repo, run:

```sh
./scripts/install-global.sh
```

The installer stores `AGENTS.md` and this playbook under `~/.codex`, installs
`claude-review`, `fable-review`, and `sol-review` under `~/.local/bin`, and adds
the shared Codex rules import to `~/.claude/CLAUDE.md` exactly once. It preserves
existing Claude-only instructions and backs up differing global Codex context
and helper files before replacement. Verify the installed copies and fresh-shell
helper resolution; do not merely return these commands to the user.

## Configuration and commands

A quality-first Codex default for general software work is Sol at high:

```toml
# ~/.codex/config.toml
model = "gpt-5.6-sol"
model_reasoning_effort = "high"
```

Keep Sol at `high` or raise it to `xhigh` for consequential tasks. Keep Luna,
Terra, `max`, and `ultra` as explicit per-task routes. `max` is deep single-agent
reasoning; `ultra` is automatic delegation, so neither is a universal quality
switch.

Start an interactive substantial workflow on its orchestrator tier and keep that
session active through integration and final synthesis:

```sh
# Codex-led workflow.
codex -m gpt-5.6-sol -c 'model_reasoning_effort="high"'

# Claude-led workflow.
claude --model claude-fable-5 --effort high
```

When the host can only make headless calls, invoke the same orchestrator before
and after delegation. Supply the second call with the compact worker/reviewer
findings and verification evidence:

```sh
# Claude-led planning and routing.
claude -p --model claude-fable-5 --effort high \
  "Plan this substantial task, assign bounded Codex and Claude scopes, and define verification."

# Claude-led final integration and synthesis after the delegated work.
claude -p --model claude-fable-5 --effort high \
  "Re-open the current diff and verification evidence, reconcile the supplied worker and review findings, and make the final judgement."

# Codex-led planning and routing.
codex exec -m gpt-5.6-sol -c 'model_reasoning_effort="high"' \
  "Plan this substantial task, assign bounded Codex and Claude scopes, and define verification."

# Codex-led final integration and synthesis after the delegated work.
codex exec -m gpt-5.6-sol -c 'model_reasoning_effort="high"' \
  "Re-open the current diff and verification evidence, reconcile the supplied worker and review findings, and make the final judgement."
```

From Claude Code, call Codex headlessly with an explicit route:

```sh
# Focused scout or mechanical pass.
codex exec -m gpt-5.6-luna -c 'model_reasoning_effort="low"' \
  "Inventory the relevant files and return paths plus one-line roles. Do not edit."

# Bounded supporting worker; raise to high when the scope is difficult.
codex exec -m gpt-5.6-terra -c 'model_reasoning_effort="medium"' \
  "Implement only the named bounded scope, add focused tests, and report verification."

# Substantive implementation worker.
codex exec -m gpt-5.6-sol -c 'model_reasoning_effort="high"' \
  "Implement the scoped change, add focused tests, inspect the diff, and report verification."

# Independent review of a critical Claude-authored change.
sol-review \
  "Review the current diff adversarially for bugs, regressions, and missing tests."

# Exceptional single-agent diagnosis.
codex exec -m gpt-5.6-sol -c 'model_reasoning_effort="max"' \
  "Diagnose the root cause from the supplied minimal evidence. Do not edit."

# Large, cleanly divisible task. Confirm support and scope first.
codex exec -m gpt-5.6-sol -c 'model_reasoning_effort="ultra"' \
  "Audit the named modules with at most three independent subagents; return one deduplicated report."
```

From Codex, call Claude as the independent provider:

```sh
# Orchestration-grade review of complex Codex-authored code. Sol remains the
# owning orchestrator and integrates Fable's findings.
fable-review \
  "Review the current change for cross-cutting code and architecture defects."

# Preferred: preflight authentication, pin Opus/high, and keep the review
# read-only. Pass a focused prompt when the default current-diff review is not
# enough.
claude-review
claude-review \
  "Review the affected auth flow for concrete bugs and missing tests."

# Repo-local fallback when the global helper is not installed.
./scripts/claude-review.sh
CLAUDE_REVIEW_MODEL=claude-fable-5 ./scripts/claude-review.sh \
  "Perform a bounded complex review; Sol retains final ownership."

# Minimal direct fallback when neither helper is installed. Supply the relevant
# diff or file paths in the prompt because this form does not collect evidence.
claude -p --model claude-opus-5 --effort high \
  --permission-mode dontAsk \
  "Review the current change for concrete bugs, regressions, and missing tests."

# Frontend and UX judgement.
claude -p --model claude-opus-5 --effort high \
  "Review the affected flow for UX, responsive behavior, and accessibility."

# Bounded bulk work.
claude -p --model claude-sonnet-5 --effort low \
  "Extract only the requested structured inventory. Do not edit files."
```

Bare `codex exec` and `codex review` inherit the user's global defaults. Use an
explicit model and effort when predictable routing matters; otherwise allow the
orchestrator's verified default to avoid noisy command repetition.

The review helper exits before making a model call when `claude` is missing or
`claude auth status` does not report `loggedIn: true`. It falls back to
`$HOME/.local/bin/claude` when Codex's non-interactive shell has a narrower
`PATH`, captures status plus staged and unstaged diffs itself with read-only Git
commands, and gives Claude only Read, Grep, and Glob tools. A model entitlement
or API failure is returned unchanged by Claude Code, so do not misreport it as a
completed review. Override the pinned route only after verifying availability:

```sh
CLAUDE_REVIEW_MODEL=claude-opus-5 \
CLAUDE_REVIEW_EFFORT=xhigh \
  claude-review "Review this security-sensitive change."
```

`fable-review` uses the same read-only evidence wrapper but defaults to
`claude-fable-5`. It is a specialist hand-off, not a transfer of orchestration
ownership. The active Sol orchestrator must validate and integrate its findings.
If Fable access is rejected, fall back once to `claude-review` and report that
the Fable route was skipped.

`sol-review` is the symmetric Fable-to-Sol hand-off. It captures the same Git
evidence, pins `gpt-5.6-sol` at high effort, runs Codex with
`--sandbox read-only`, and encodes that Fable retains final ownership.

## When to use the opposite provider

Use a cross-provider review after local verification. This is the default for
every substantial task, including read-only audits, research, diagnosis,
planning, substantial code changes, and important user-facing flows. It is an
independent review, not an automatic duplicate implementation.

**Required at the strongest suitable tier:** smart contracts; controller or
permission logic; funds or signing; authentication and authorization; security
boundaries; destructive migrations; data-loss risk; production infrastructure;
or architecture that is expensive to reverse.

**Required at normal strong effort:** feature work, bug fixes with behavioral
impact, meaningful refactors, unfamiliar code, repeated failed diagnoses, and
substantial instruction or workflow changes.

**Usually skip:** only bounded, deterministic typo fixes, formatting, mechanical
renames, generated files, and tiny documentation edits with no behavioral or
factual consequence. Scale alone can make an otherwise mechanical task
substantial.

If GPT/Codex implemented, use Opus at high effort for a normal independent
review. Use Fable at `high` or `xhigh` when the review spans complex code,
architecture, multiple workstreams, or conflicting findings; this is valid even
inside a Sol-led workflow, and Sol retains final integration ownership. If
Claude implemented, use Sol `high`, raising it to `xhigh` for critical work.
Terra, Luna, and Sonnet do not count as the final independent reviewer when a
stronger available model could materially improve the result.

When both providers authored different scopes, cross-review each scope: Claude
reviews the GPT-authored portion and Codex reviews the Claude-authored portion.
Neither provider's self-review is sufficient. The Sol/Fable orchestrator then
reconciles both review streams and owns final synthesis.

Ask the reviewer for findings ordered by severity with file/line evidence,
behavioral impact, and a missing-test assessment. "Looks good" without evidence
is not a useful cross-check.

## Quality-first efficiency

1. **Protect decisive stages.** Use strong planning, implementation, diagnosis,
   and final review; optimize the supporting work around them.
2. **Scout only as much as needed.** Use efficient tiers for paths, symbols, and
   narrow extraction. Do not feed every raw file to the orchestrator.
3. **Verify before escalating.** A failing test or concrete diff is better input
   than a broad request to rethink everything.
4. **Send compact hand-offs.** Include the goal, constraints, relevant paths or
   diff, exact failure, and required return format. Remove secrets and unrelated
   logs first.
5. **Reuse one good scout result.** Do not ask multiple agents to rediscover the
   same repository map.
6. **Use duplicate implementation selectively.** It is useful when competing
   designs or a hard diagnosis could materially improve the outcome;
   otherwise prefer one implementation plus one adversarial review.
7. **Cap fan-out.** Name the maximum workers and their non-overlapping scopes.
   More agents are not automatically more coverage.
8. **Never nest automatic delegation.** An `ultra` run must not launch another
   `ultra` run, and a delegated worker must not silently widen its own scope.
9. **Choose speed separately from quality.** A faster service tier reduces
   latency but does not replace stronger reasoning or review; opt in when the
   quicker turnaround is worth its usage cost.
10. **Stop when the evidence is decisive.** Passing focused tests, a clean diff,
    and a strong opposite-provider review are a completion signal, not a reason
    to sample every model tier.

## Parallel work safety

- Multiple read-only scouts or reviewers may share a worktree.
- Parallel writers must use separate worktrees or explicitly non-overlapping
  file ownership. Never let two agents edit the same file concurrently.
- Give each worker a bounded output contract. Prefer a short findings list,
  patch, schema, or test result over a prose transcript.
- The entrypoint's Sol/Fable orchestrator alone integrates overlapping ideas,
  resolves disagreements, and runs final verification for substantial work.

## Workflow shapes

### Trivial or mechanical change

1. Active engine inspects and edits with Luna/Terra or Sonnet at low or medium
   effort.
2. Run the focused check.
3. Skip the second provider only while the change remains factually and
   behaviorally trivial.

### Normal implementation

1. The owning Sol/Fable orchestrator scopes the task and assigns
   non-overlapping work.
2. Terra `medium`/`high` or Opus `high` implements normal scoped work; Sol or
   Opus handles the hardest scope. The opposite provider receives at least one
   meaningful task, at minimum the adversarial review.
3. The orchestrator inspects the integrated diff and runs project verification.
4. If one provider authored the change, the opposite provider reviews it at high
   effort. Use Fable for complex cross-cutting review of Sol/Codex-authored work
   when its orchestration-grade judgement adds value. If both authored scopes,
   each provider reviews the other's scope.
5. The orchestrator resolves findings and reruns affected verification.

### Critical or hard change

1. The owning Sol or Fable tier plans at `xhigh` or the strongest equivalent
   effort with a bounded task graph.
2. Sol/Opus implements the decisive scopes; Terra handles bounded supporting
   workstreams, and Luna/Sonnet handles only mechanical support work.
3. Run focused and broader verification.
4. Each provider reviews the other provider's authored scopes adversarially at
   `xhigh` or the strongest equivalent effort. In a Sol-led run, Fable can own
   this bounded review without taking over final synthesis.
5. The original owning orchestrator reconciles findings and makes the final
   evidence-based judgement at `xhigh` or the strongest equivalent effort. Use
   `max` only for a remaining hard single-agent question; use `ultra` only if the
   work genuinely benefits from bounded parallelism.

## Live sources

Model names, access, effort controls, and prices are volatile. Recheck official
sources and the live CLI catalog before changing this baseline:

- OpenAI model guidance: `https://developers.openai.com/api/docs/guides/latest-model`
- OpenAI Codex model routing: `https://learn.chatgpt.com/docs/models`
- OpenAI Codex CLI commands: `https://learn.chatgpt.com/docs/developer-commands?surface=cli`
- OpenAI GPT-5.6 availability: `https://help.openai.com/en/articles/20001354`
- Claude pricing and current models: `https://platform.claude.com/docs/en/about-claude/pricing`

Do not hardcode prices, quotas, entitlement rules, or release dates into this
portable playbook.
