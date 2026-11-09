# Fable 5.2 owner and specialist

Use Fable 5.2 (`claude-fable-5-2`) where its strengths decide the result:
planning and orchestrating other models, long unattended scopes, loosely
defined problems across repositories, hard diagnosis, conflicting evidence, and
cross-cutting review. Keep everyday bounded coding with Opus 5.5 or Sol and
mechanical work with the efficient tiers under [routing.md](routing.md).

Fable owns direct Claude-led sessions; under Astra it is a specialist or
reviewer. Launch it with [delegation.md](delegation.md) and pin it with
[claude-native.md](claude-native.md). A hand-off never transfers ownership.

## Effort

[routing.md](routing.md) chooses the effort for each route; this section only
describes how Fable 5.2 responds to it.

- Start at `high` and set it explicitly. Most of the gain is present there.
  Claude Code starts a Fable 5.2 session at `medium`, and an older top-level
  `effortLevel` does not apply to it: an owner session runs `/effort high`.
  The helpers and `fable-specialist` already pin `high`.
- Above `high`, gains are uneven and token use rises sharply. Use xhigh where
  routing.md or [reviews.md](reviews.md) selects it; max only for the hardest
  remaining judgement.
- Routing gives Fable no worker route below `high`. An interactive owner
  session may plan at `medium`. Below `high` it ends turns early more often,
  so the brief asks for the whole scope and for real blockers only.
- Instructions to think less have no effect at `medium` and above; lower the
  effort instead. Recheck an effort level tuned on Fable 5.1 before reusing it.

## Briefs

Fable 5.2 applies instructions as written, including stale ones.

- State who owns the code. A worker changes only what the scope needs; hand
  over the structure explicitly when merging or restructuring is wanted.
- Name the exact actions that need approval and the safe steps that need none,
  such as rerunning a read-only check. Write an exception into the rule it
  qualifies.
- Leave out cautions, notes, and reviewer conditions whose reason no longer
  holds; they accumulate across agents and hold back routine work.
- Give the goal and acceptance criteria once. Do not write a token budget into
  the brief or ask it to print its reasoning.
- Inspect the complete diff. Its closing summary can omit small changes.

## Orchestration

- As owner it delegates readily where prompts invite that. Name the workers and
  scopes in the plan and keep to [execution.md](execution.md); subagents can
  dominate a session's cost.
- As owner at xhigh or max it may start subagents to review its own work. Route
  them through the pinned agent types. A self-review never replaces a review
  required by [reviews.md](reviews.md).
- It suits asynchronous work where the user returns for the result. Ask for a
  one-line update every few tool calls when someone is watching, and for a
  self-contained closing report: findings, changes, checks run, blockers.

## Limits

- Safety classifiers can decline benign security or life-sciences content. If a
  Fable task or review is declined, report it and retry that scope once on
  Opus 5.5 at xhigh, only when Opus has not already failed that scope and is
  adequate for its risk. Opus 5.5 runs its own classifiers; if the retry is
  also declined, stop and report the scope as blocked. A run that reports
  another model follows [routing.md](routing.md): report it and retain the
  scope. Do not rephrase to pass the classifier, and keep the opposite-provider
  review that [reviews.md](reviews.md) requires.
- Advisor pairing and the pins that move together are in
  [claude-native.md](claude-native.md).
- Do not move a running conversation back to Fable 5.1 or to Opus; the earlier
  reasoning is not carried over. Start a fresh session with a compact brief.
- Fable needs 30-day data retention and can bill to usage credits.

## Official guidance

Anthropic documents the model in the
[Fable 5.2 overview](https://platform.claude.com/docs/en/models/fable-5-2/overview),
its behavior in
[Prompting Claude Fable 5.2](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-2),
and the pairing and switching rules in the
[migration guide](https://platform.claude.com/docs/en/models/fable-5-2/migration-guide).
These are vendor statements; calibrate a route change with the
[calibration record](https://github.com/JordyDutch/multi-provider-orchestration/blob/main/docs/model-calibration.md)
before relying on it.
