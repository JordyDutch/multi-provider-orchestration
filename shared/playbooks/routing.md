# Model routing

Read this guide when selecting models, effort, or the owning orchestrator.

## Availability

Verify availability before changing routes or after a provider failure. Helpers
preflight authentication themselves; do not duplicate their checks.

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
| Codex strongest | GPT-6 Astra (`gpt-6-astra`) | `high` | Hardest end-to-end work, cross-system architecture, hard diagnosis, conflicting evidence, and critical judgement |
| Codex owner | GPT-5.6 Sol (`gpt-5.6-sol`) | `high` | Difficult planning, architecture, implementation, diagnosis, integration, and final judgement |
| Codex everyday | GPT-5.6 Terra (`gpt-5.6-terra`) | `medium` | Scoped implementation, repository analysis, tests, and bounded support work |
| Codex efficient | GPT-5.6 Luna (`gpt-5.6-luna`) | `low` | Clear extraction, classification, transformation, and mechanical work |
| Claude owner | Fable 5.1 (`claude-fable-5-1`) | `high` | Claude-led orchestration and complex cross-cutting review |
| Claude coding/review | Opus 5 (`claude-opus-5`) | `high` | Substantive implementation, frontend/UX, and independent review |
| Claude efficient | Sonnet 5 (`claude-sonnet-5`) | `low` | Low-risk bulk reading and mechanical support after live verification |

These are workflow starting efforts, not catalog defaults. Use the lowest
effort that meets the confidence need.

Never use bare or `latest` aliases for pinned Opus and Fable routes.

## Choose by consequence

| Work | Owner or worker | Review |
| --- | --- | --- |
| Deterministic inventory, extraction, formatting, transformation, or mechanical edit | In Codex-led work, Luna low for one clear pass, Luna medium for several items or checks, or Terra medium when criteria require judgement; in Claude-led work, keep the active owner or use verified Sonnet low/medium when the hand-off is worthwhile | None when checks are decisive |
| Normal scoped behavior change | Terra medium; Terra high for multiple files or real tradeoffs; Opus high when Claude is the better implementation fit; current entry owner integrates | Review provider follows the implementation author when behavior, unfamiliarity, or uncertainty warrants it; use `reviews.md` |
| Substantial multi-file work | Sol high or Fable high owns; bounded workers by fit | One normal strong opposite-provider review |
| Hardest cross-system work, hard diagnosis, or conflicting evidence | Astra high; xhigh for the unresolved question; Fable xhigh when Claude-led | Independent second opinion |
| Security, auth, permissions, funds, destructive change, data loss, migration, costly architecture | Astra/Fable xhigh; max only for the hardest remaining judgement | Mandatory strongest suitable opposite-provider review |
| Large task with truly independent workstreams | Sol or Astra by complexity; ultra only when supported, or bounded workers | Owner synthesis plus risk-appropriate review |

`Bounded` means named scope, known success criteria and checks, and no unresolved
architecture or cross-cutting integration. Otherwise promote ambiguous Codex
work to Sol high or Claude-led work to Fable high.

Use Astra for a concrete complexity or consequence, not task size alone. Keep Sol
for ordinary complex work. Skip scouts that cost more than doing the work; never
rerun a successful task at every tier.

## Effort

- `low`: narrow, single-pass execution and mechanical support, normally Luna or
  a live-verified Claude efficient tier.
- `medium`: normal scoped planning, implementation, and checking, normally
  Terra; use Luna or a Claude efficient tier only while work stays mechanical.
- `high`: multi-file tradeoffs or ownership; Terra for bounded work, otherwise
  Sol, Astra, Fable, or Opus by role.
- `xhigh`: difficult diagnosis, security, or ambiguous design; use on the small
  decisive stage.
- `max`: hardest remaining single-agent judgement, not a default.
- `ultra`: top-level automatic multi-agent work only; never nest it.

Review routes in `reviews.md` choose effort separately by authorship and risk.

When a Luna task starts needing open-ended planning or behavioral judgement,
prefer Terra over raising Luna above medium. When a Terra task starts needing
work outside the bounded definition, prefer Sol over compensating with `xhigh`
or `max`. Reclassify and promote the model when the task changes class. If a
strong current owner already has the full context and the remaining scope is
tiny, do not create a hand-off solely to move down a tier.

Escalate Sol to Astra for unresolved hard or critical judgement. Keep one owner
through integration; when escalation is necessary, use one compact hand-off at
the decisive stage instead of repeated planning and synthesis calls.

## Live sources

- OpenAI model guidance: `https://developers.openai.com/api/docs/guides/latest-model`
- Codex models: `https://learn.chatgpt.com/docs/models`
- Codex CLI commands: `https://learn.chatgpt.com/docs/developer-commands?surface=cli`
- Claude pricing and models: `https://platform.claude.com/docs/en/about-claude/pricing`
