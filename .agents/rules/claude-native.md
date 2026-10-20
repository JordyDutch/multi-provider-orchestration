# Claude-native routing and advisor

Read this guide in Claude-led sessions before spawning native subagents or
workflow agents, and when configuring the advisor.

## Why workers stay on the main model

Claude Code runs a native worker on the session's main model unless a model is
chosen for it, and forks always reuse that model. Without explicit routing, an
Opus- or Fable-led session runs every worker on its own model, including
`general-purpose` and untyped Agent calls; do not use those for delegated work.

For a non-fork worker, the first match wins: the `model` passed at spawn, the
`model` in its agent definition (`inherit` is the main model),
`CLAUDE_CODE_SUBAGENT_MODEL`, then the main model. Leave
`CLAUDE_CODE_SUBAGENT_MODEL_FORCE` and `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL`
unset; either one can override a worker's own model. `CLAUDE_CODE_EFFORT_LEVEL`
overrides every effort pin. See
[subagent models](https://code.claude.com/docs/en/sub-agents#choose-a-model)
and [model aliases](https://code.claude.com/docs/en/model-config#model-aliases).

## Pinned agent types

The installer copies these definitions from `.claude/agents/` to
`~/.claude/agents/`, or to `$CLAUDE_CONFIG_DIR/agents/` when that variable is
set. Claude Code reloads changed definitions within seconds;
restart a session that started before that directory existed.

| Agent type | Model and effort | Use |
| --- | --- | --- |
| `haiku-scout` | `claude-haiku-5-5`, low | Read-only search, inventory, extraction, classification |
| `sonnet-worker` | `claude-sonnet-5-5`, medium | Mechanical edits and batches with a decisive check |
| `opus-worker` | `claude-opus-5-5`, high | Scoped behavioral code, tests, frontend/UX |
| `fable-specialist` | `claude-fable-5-1`, high | Architecture input, hard diagnosis, complex work |

Spawn them by `subagent_type` and omit the Agent tool's `model`; a passed model
overrides the pin. That parameter accepts only aliases, so use it only after
confirming the alias target. The Agent tool's `effort` overrides the pinned
effort for one call, such as `sonnet-worker` at low for a single pass. In
workflow scripts, give every `agent()` call an exact model ID such as
`claude-haiku-5-5` plus `effort`, or a pinned `agentType`. Choose a worker with
[routing.md](routing.md) and brief it with [delegation.md](delegation.md).
Haiku miscounted lines in a probe; route counts and totals to a command.

## Advisor

The advisor lets the calling model consult a stronger model at decision points,
with the full conversation. The installer pins it in
`~/.claude/settings.json`:

```json
{ "advisorModel": "claude-fable-5-1" }
```

`/advisor fable` saves the alias instead; the next installer run, such as the
next day's refresh, restores the pin, as does `/advisor claude-fable-5-1`. An advisor must rank at or above the model
calling it. Fable 5.1 qualifies for every Claude main model; a Fable-led
session can only pair it with itself. See
[advisor pairings](https://code.claude.com/docs/en/advisor#choose-an-advisor-model).

- Fable 5.1 owns Claude-led sessions under [routing.md](routing.md). An Opus
  5.5 or Sonnet 5.5 session keeps the Fable advisor on for routine decisions;
  before work that routing assigns to the Fable owner, switch with
  `/model claude-fable-5-1` or hand off. Advice neither owns the work nor
  replaces a review required by [reviews.md](reviews.md).
- Subagents inherit the advisor when their own model passes the pairing check.
  There is no per-agent switch; each call reads that worker's whole context at
  Fable rates, billed to usage credits on some plans.
- Claude decides when to call it. For long tasks, ask in the brief for a
  consultation before fixing an approach and before reporting completion. It
  adds little to short tasks.
- It requires the Anthropic API and feature-flag fetching. `DISABLE_TELEMETRY`,
  `DO_NOT_TRACK`, `DISABLE_GROWTHBOOK`, and
  `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` turn it off, as does
  `CLAUDE_CODE_DISABLE_ADVISOR_TOOL`. Fable may need one-time usage-credit
  consent through `/model fable`.

The task helpers use restricted mode, which loads only managed settings and
`--settings`. Pass `--advisor` to attach the pinned Fable 5.1 advisor through
`--settings`. Before inference, the helper rejects a disabling variable in its
environment, then runs a local `/advisor` check under the same restricted
settings. It stops unless that check reports Fable 5.1 as an allowed advisor,
which also covers managed `env`, `advisorModel`, and `availableModels`
settings. It accepts usage from the executor plus optionally
`claude-fable-5-1` and reports whether the advisor was called; missing Fable
consent may still show only as `(not called)`. The helper never enables a
fallback model; a managed fallback to Fable 5.1 would look like advisor use.

## Verify

Confirm the runtime model on the first meaningful task: the `modelUsage` keys
of a `claude -p --output-format json` result, or the worker's report of the
model ID in its own system prompt. A requested model is not proof of use.
