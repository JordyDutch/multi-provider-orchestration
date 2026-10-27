# Model routing

Select models, effort, and the owner here.

## Availability

Verify availability before the first hand-off, route changes, or provider retries.

```sh
codex debug models | jq -r '
  .models[]
  | select(
      .slug == "gpt-6-astra"
      or .slug == "gpt-6.1-sol"
      or .slug == "gpt-6-luna"
      or .slug == "gpt-6.1-terra"
    )
  | [
      .slug,
      ("default=" + .default_reasoning_level),
      ("efforts=" + ([.supported_reasoning_levels[].effort] | join(",")))
    ]
  | @tsv
'
```

Catalog presence and login do not prove access; confirm the first meaningful
routed task. If Astra cannot own it, report
that and fall back once to Sol high/xhigh only when adequate; otherwise stop
the affected scope. Never silently substitute models. Use supported effort only.

## Current roles

| Role | Model | Starting effort | Use |
| --- | --- | --- | --- |
| Codex owner | GPT-6 Astra (`gpt-6-astra`) | `high` | Planning, task allocation, integration, and final judgement |
| Codex implementation specialist | GPT-6.1 Sol (`gpt-6.1-sol`) | `high` | Scoped implementation and behavioral code; xhigh for difficult diagnosis |
| Codex efficient | GPT-6 Luna (`gpt-6-luna`) | `low` | Clear extraction, classification, transformation, and mechanical work |
| Codex writing/visual/app specialist | GPT-6.1 Terra (`gpt-6.1-terra`) | `low` | Source-grounded writing, image/chart interpretation, visual QA, bounded app work; medium for multiple sources/screens or steps; [terra.md](terra.md) |
| Claude owner/specialist | Fable 5.1 (`claude-fable-5-1`) | `high` | Complex work assigned by Astra, direct Claude-led orchestration, and cross-cutting reviews |
| Claude coding/review | Opus 5.5 (`claude-opus-5-5`) | `high` | Substantive implementation, frontend/UX, and independent review |
| Claude efficient | Sonnet 5.5 (`claude-sonnet-5-5`) | `low` | Mechanical edits via `sonnet-task` or the medium-pinned `sonnet-worker`; medium for batches |
| Claude fast | Haiku 5.5 (`claude-haiku-5-5`) | `low` | Read-only search and extraction via `haiku-scout` or `haiku-task`; no tallies |

Use the lowest sufficient effort. Never use bare or `latest` Claude aliases.
Pin native Claude workers and the advisor with
[claude-native.md](claude-native.md).

## Choose by consequence

| Work | Owner or worker | Review |
| --- | --- | --- |
| Deterministic inventory, extraction, formatting, transformation, or mechanical edit | Luna low for one clear pass, medium for batches; Sol medium for bounded judgement; Haiku low for read-only search; Sonnet low/medium for edits. Either entry owner may choose by fit and savings | None when checks are decisive |
| Normal scoped behavior change | Sol high or Opus high by task fit; current entry owner integrates | Review provider follows the implementation author when behavior, unfamiliarity, or uncertainty warrants it; use `reviews.md` |
| Substantial multi-file work | Astra/Fable owns by entry provider; Sol high or Claude specialists execute named scopes | Apply the risk triggers in `reviews.md`; size alone does not require review |
| Hardest cross-system work, hard diagnosis, or conflicting evidence | Astra/Fable owns at high; xhigh for the unresolved question, with Sol or Claude analysis as useful | Independent second opinion |
| Security, auth, permissions, funds, destructive change, data loss, migration, costly architecture | Astra/Fable xhigh; max only for the hardest remaining judgement | Mandatory strongest suitable opposite-provider review |
| Large task with truly independent workstreams | Astra/Fable owns; bounded workers, or ultra only when supported | Owner synthesis plus risk-appropriate review |

For table counts, groups, or totals, use Luna medium. Brief: compute with code
or CLI tools and return command and output. Never tally mentally. The owner
checks the result.

`Bounded` means named scope, decisive checks, and resolved architecture and
integration. Promote difficult diagnosis to Sol xhigh or Fable
high for analysis; the owner decides architecture and integrates.

Delegate with known scope, sufficient capability, decisive checks, and expected
net savings; otherwise keep the owner. Mandatory reviews still apply. Either
entry owner may choose any listed worker; consider Opus for frontend/UX.
Claude is not limited to reviewing Codex. A hand-off never transfers ownership.
Keep tiny work with the owner or shell.

Launch workers using [delegation.md](delegation.md).

Launch with live-verified model and effort and fresh compact context where
supported. Instructions do not switch models. If routing is unavailable, report
it and retain the scope. Never silently substitute or inherit owner effort.

## Effort

- `low`: single-pass support by Luna, Haiku, Sonnet, or Terra writing/inspection.
- `medium`: Sol bounded judgement, Luna/Sonnet batches, Terra multi-source/step work.
- `high`: Sol implementation, multi-file tradeoffs, or orchestration by role.
- `xhigh`: difficult diagnosis, security, or ambiguous design; use on the small
  decisive stage.
- `max`: hardest remaining single-agent judgement, never a default.
- `ultra`: top-level multi-agent work only; never nest it.

Review routes in `reviews.md` choose effort separately by authorship and risk.

For Luna planning or behavioral judgement,
use Sol medium for bounded analysis or Sol high for implementation.
If Sol exceeds its scope, return architecture and
integration decisions to the calling owner.

## Live sources

- OpenAI model guidance: `https://developers.openai.com/api/docs/guides/latest-model`
- GPT-6.1 Sol: `https://developers.openai.com/api/docs/models/gpt-6.1-sol`
- Codex models: `https://learn.chatgpt.com/docs/models`
- Codex CLI commands: `https://learn.chatgpt.com/docs/developer-commands?surface=cli`
- Codex subagents: `https://learn.chatgpt.com/docs/agent-configuration/subagents`
- Claude models: `https://platform.claude.com/docs/en/models/overview`
