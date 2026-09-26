# Model routing

Read this guide when selecting models, effort, or the owning orchestrator.

## Availability

Verify availability before the first hand-off, route changes, or provider retries.
Helpers preflight authentication; do not duplicate their checks.

```sh
codex debug models | jq -r '
  .models[]
  | select(
      .slug == "gpt-6-astra"
      or .slug == "gpt-6-sol"
      or .slug == "gpt-6-luna"
    )
  | [
      .slug,
      ("default=" + .default_reasoning_level),
      ("efforts=" + ([.supported_reasoning_levels[].effort] | join(",")))
    ]
  | @tsv
'
```

Use compact catalog output. Catalog presence and login do not prove access;
confirm it with the first meaningful routed task. If Astra cannot own it, report
that and fall back once to Sol high/xhigh only when adequate; otherwise stop
the affected scope. Never silently substitute models. Use supported effort only.

## Current roles

| Role | Model | Starting effort | Use |
| --- | --- | --- | --- |
| Codex owner | GPT-6 Astra (`gpt-6-astra`) | `high` | Planning, task allocation, integration, and final judgement |
| Codex implementation specialist | GPT-6 Sol (`gpt-6-sol`) | `high` | Scoped implementation and behavioral code; xhigh for difficult diagnosis; review effort follows `reviews.md` |
| Codex efficient | GPT-6 Luna (`gpt-6-luna`) | `low` | Clear extraction, classification, transformation, and mechanical work |
| Claude owner/specialist | Fable 5.1 (`claude-fable-5-1`) | `high` | Complex work assigned by Astra, direct Claude-led orchestration, and cross-cutting reviews |
| Claude coding/review | Opus 5.5 (`claude-opus-5-5`) | `high` | Substantive implementation, frontend/UX, and independent review |
| Claude efficient | Sonnet 5 (`claude-sonnet-5`) | `low` | Low-risk bulk reading and mechanical support after live verification |

Use the lowest sufficient effort. Never use bare or `latest` aliases for
pinned Opus and Fable routes.

## Choose by consequence

| Work | Owner or worker | Review |
| --- | --- | --- |
| Deterministic inventory, extraction, formatting, transformation, or mechanical edit | Luna low for one clear pass, medium for batches; Sol medium for bounded judgement; verified Sonnet low/medium when suitable. Either entry owner may choose by fit and savings | None when checks are decisive |
| Normal scoped behavior change | Sol high or Opus high by task fit; current entry owner integrates | Review provider follows the implementation author when behavior, unfamiliarity, or uncertainty warrants it; use `reviews.md` |
| Substantial multi-file work | Astra/Fable owns by entry provider; Sol high or Claude specialists execute named scopes | Apply the risk triggers in `reviews.md`; size alone does not require review |
| Hardest cross-system work, hard diagnosis, or conflicting evidence | Astra/Fable owns at high; xhigh for the unresolved question, with Sol or Claude analysis as useful | Independent second opinion |
| Security, auth, permissions, funds, destructive change, data loss, migration, costly architecture | Astra/Fable xhigh; max only for the hardest remaining judgement | Mandatory strongest suitable opposite-provider review |
| Large task with truly independent workstreams | Astra/Fable owns; bounded workers, or ultra only when supported | Owner synthesis plus risk-appropriate review |

For tabular counts, groups, or totals across rows, use Luna medium. Put in the
brief: compute with code or CLI tools and return the command and output. Never
rely on a mental tally, at any effort. The owner checks the result.

`Bounded` means named scope, known success criteria and checks, and no unresolved
architecture or integration. Promote difficult diagnosis to Sol xhigh or Fable
high for analysis; the owner decides architecture and integrates.

Delegate execution only with known scope, sufficient capability, decisive checks,
and expected net savings; otherwise keep the strong owner. Mandatory reviews
apply regardless of savings. Both entry owners can choose Sol, Luna, or Opus by
task fit. Consider Opus for frontend/UX before authoring.
Claude is not limited to reviewing Codex. A hand-off never transfers ownership.
Use the owner or shell for tiny deterministic tasks.

Launch workers using [delegation.md](delegation.md).

Set both model and effort in each worker launch after live verification. Use
fresh compact context when supported; model names in instructions do not switch
the runtime. If explicit routing is unavailable, report it and keep the scope
with the owner. Never silently substitute or inherit the owner's effort.

## Effort

- `low`: narrow, single-pass execution and mechanical support, normally Luna or
  a live-verified Claude efficient tier.
- `medium`: bounded judgement by Sol or mechanical batches by Luna or a
  live-verified Claude efficient tier.
- `high`: Sol implementation, multi-file tradeoffs, or orchestration by role.
- `xhigh`: difficult diagnosis, security, or ambiguous design; use on the small
  decisive stage.
- `max`: hardest remaining single-agent judgement, never a default.
- `ultra`: top-level multi-agent work only; never nest it.

Review routes in `reviews.md` choose effort separately by authorship and risk.

When Luna needs planning or behavioral judgement,
use Sol medium for bounded analysis or Sol high for implementation.
If Sol exceeds its scope, return architecture and
integration decisions to the calling owner. Choose effort by consequence;
do not compensate with `xhigh` or `max` by default.

## Live sources

- OpenAI model guidance: `https://developers.openai.com/api/docs/guides/latest-model`
- Codex models: `https://learn.chatgpt.com/docs/models`
- Codex CLI commands: `https://learn.chatgpt.com/docs/developer-commands?surface=cli`
- Codex subagents: `https://learn.chatgpt.com/docs/agent-configuration/subagents`
- Claude pricing and models: `https://platform.claude.com/docs/en/about-claude/pricing`
