# Model routing

Read this guide when selecting models, effort, or the owning orchestrator.

## Availability

Verify availability before changing routes or after a provider failure.
Helpers preflight authentication; do not duplicate their checks.

```sh
codex debug models | jq -r '
  .models[]
  | select(
      .slug == "gpt-6-astra"
      or .slug == "gpt-5.6-sol"
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

Never load raw catalog output into model context. Catalog presence and login do
not prove entitlement; confirm access with the first meaningful routed task.
If Astra cannot own the task, report it and fall back once to Sol high/xhigh only
when adequate; otherwise stop the affected scope. Never silently substitute a
model. Use only efforts supported by the current client.

## Current roles

| Role | Model | Starting effort | Use |
| --- | --- | --- | --- |
| Codex owner | GPT-6 Astra (`gpt-6-astra`) | `high` | Planning, task allocation, integration, and final judgement |
| Codex complex specialist | GPT-5.6 Sol (`gpt-5.6-sol`) | `high` | Complex execution, design analysis, diagnosis, and normal or complex Claude-code reviews |
| Codex everyday | GPT-5.6 Terra (`gpt-5.6-terra`) | `medium` | Scoped implementation, repository analysis, tests, and bounded support work |
| Codex efficient | GPT-5.6 Luna (`gpt-5.6-luna`) | `low` | Clear extraction, classification, transformation, and mechanical work |
| Claude owner/specialist | Fable 5.1 (`claude-fable-5-1`) | `high` | Claude-led orchestration, complex Claude implementation and analysis, and cross-cutting Codex-code reviews |
| Claude coding/review | Opus 5 (`claude-opus-5`) | `high` | Substantive implementation, frontend/UX, and independent review |
| Claude efficient | Sonnet 5 (`claude-sonnet-5`) | `low` | Low-risk bulk reading and mechanical support after live verification |

Efforts are workflow choices; use the lowest sufficient level.

Never use bare or `latest` aliases for pinned Opus and Fable routes.

## Choose by consequence

| Work | Owner or worker | Review |
| --- | --- | --- |
| Deterministic inventory, extraction, formatting, transformation, or mechanical edit | In Codex-led work, Luna low for one clear pass, Luna medium for several items or checks, or Terra medium when criteria require judgement; in Claude-led work, keep the active owner or use verified Sonnet low/medium when the hand-off is worthwhile | None when checks are decisive |
| Normal scoped behavior change | Terra medium; Terra high for multiple files or real tradeoffs; Opus high when Claude is the better implementation fit; current entry owner integrates | Review provider follows the implementation author when behavior, unfamiliarity, or uncertainty warrants it; use `reviews.md` |
| Substantial multi-file work | Astra/Fable owns by entry provider; Sol high or Claude specialists execute named scopes | Apply the risk triggers in `reviews.md`; size alone does not require review |
| Hardest cross-system work, hard diagnosis, or conflicting evidence | Astra/Fable owns at high; xhigh for the unresolved question, with Sol or Claude analysis as useful | Independent second opinion |
| Security, auth, permissions, funds, destructive change, data loss, migration, costly architecture | Astra/Fable xhigh; max only for the hardest remaining judgement | Mandatory strongest suitable opposite-provider review |
| Large task with truly independent workstreams | Astra/Fable owns; bounded workers, or ultra only when supported | Owner synthesis plus risk-appropriate review |

`Bounded` means named scope, known success criteria and checks, and no unresolved
architecture or integration. Promote ambiguous execution to Sol high or Fable
high for analysis; the calling owner decides architecture and integrates.

Choose specialists across providers under either owner: prefer Opus for
frontend/UX and substantive Claude implementation, Fable for complex Claude
tasks, and verified Sonnet low/medium for useful mechanical Claude work.
Claude is not limited to reviewing Codex. A hand-off never transfers ownership.
Do not add an orchestration call for a small task or rerun success at every tier.

## Effort

- `low`: narrow, single-pass execution and mechanical support, normally Luna or
  a live-verified Claude efficient tier.
- `medium`: normal scoped planning, implementation, and checking, normally
  Terra; use Luna or a Claude efficient tier only while work stays mechanical.
- `high`: multi-file tradeoffs, complex execution, or orchestration by role.
- `xhigh`: difficult diagnosis, security, or ambiguous design; use on the small
  decisive stage.
- `max`: hardest remaining single-agent judgement, not a default.
- `ultra`: top-level automatic multi-agent work only; never nest it.

Review routes in `reviews.md` choose effort separately by authorship and risk.

When a Luna task starts needing open-ended planning or behavioral judgement,
prefer Terra over raising Luna above medium. When a Terra task starts needing
work outside the bounded definition, prefer Sol over compensating with `xhigh`
or `max`. Reclassify and promote the model when the task changes class. The
active owner can finish tiny scopes directly when a hand-off costs more.

Return unresolved hard decisions to the calling owner in one compact hand-off.
Ownership does not mean writing every patch: use Sol and other specialists for
meaningful execution scopes.

## Live sources

- OpenAI model guidance: `https://developers.openai.com/api/docs/guides/latest-model`
- Codex models: `https://learn.chatgpt.com/docs/models`
- Codex CLI commands: `https://learn.chatgpt.com/docs/developer-commands?surface=cli`
- Claude pricing and models: `https://platform.claude.com/docs/en/about-claude/pricing`
