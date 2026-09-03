# Model routing

Read this guide when selecting models, effort, or the owning orchestrator.

## Availability

Verify availability before changing pinned routes, after a provider failure, or
when the daily setup check has not yet established the current environment. Do
not repeat a separate authentication preflight immediately before a helper that
already performs it.

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

Never load raw `codex debug models` output into model context. Authentication
does not prove entitlement; let the first meaningful routed task confirm access,
then fall back once and report the unavailable route. If an effort is unsupported,
use a lower effort only when adequate; otherwise choose a stronger route and
report the fallback.

## Current roles

| Role | Model | Starting effort | Use |
| --- | --- | --- | --- |
| Codex owner | GPT-5.6 Sol (`gpt-5.6-sol`) | `high` | Difficult planning, architecture, implementation, diagnosis, integration, and final judgement |
| Codex everyday | GPT-5.6 Terra (`gpt-5.6-terra`) | `medium` | Scoped implementation, repository analysis, tests, and bounded support work |
| Codex efficient | GPT-5.6 Luna (`gpt-5.6-luna`) | `low` | Clear extraction, classification, transformation, and mechanical work |
| Claude owner | Fable 5.1 (`claude-fable-5-1`) | `high` | Claude-led orchestration and complex cross-cutting review |
| Claude coding/review | Opus 5 (`claude-opus-5`) | `high` | Substantive implementation, frontend/UX, and independent review |
| Claude efficient | Sonnet 5 (`claude-sonnet-5`) | `low` | Low-risk bulk reading and mechanical support after live verification |

These are workflow starting efforts, not catalog defaults. Use the lowest
effort that meets the confidence need.

Model availability is volatile. Reverify before changing this table. Never use
bare or `latest` aliases for pinned Opus and Fable routes.

## Choose by consequence

| Work | Owner or worker | Review |
| --- | --- | --- |
| Deterministic inventory, extraction, formatting, transformation, or mechanical edit | In Codex-led work, Luna low for one clear pass, Luna medium for several items or checks, or Terra medium when criteria require judgement; in Claude-led work, keep the active owner or use verified Sonnet low/medium when the hand-off is worthwhile | None when checks are decisive |
| Normal scoped behavior change | Terra medium; Terra high for multiple files or real tradeoffs; Opus high when Claude is the better implementation fit; current entry owner integrates | Review provider follows the implementation author when behavior, unfamiliarity, or uncertainty warrants it; use `reviews.md` |
| Substantial multi-file work | Sol high or Fable high owns; bounded workers by fit | One normal strong opposite-provider review |
| Hard diagnosis or conflicting evidence | Sol/Fable xhigh for the unresolved question | Independent second opinion |
| Security, auth, permissions, funds, destructive change, data loss, migration, costly architecture | Sol/Fable xhigh; max only for the hardest remaining judgement | Mandatory strongest suitable opposite-provider review |
| Large task with truly independent workstreams | Sol ultra only when supported, or explicit bounded workers | Owner synthesis plus risk-appropriate review |

`Bounded` means named scope, known success criteria and checks, and no unresolved
architecture or cross-cutting integration. Otherwise promote ambiguous Codex
work to Sol high or Claude-led work to Fable high.

Do not launch a cheaper scout if the startup and integration cost exceeds doing
the bounded work in the active owner. Do not run the same successful task at
every tier.

## Effort

- `low`: narrow, single-pass execution and mechanical support, normally Luna or
  a live-verified Claude efficient tier.
- `medium`: normal scoped planning, implementation, and checking, normally
  Terra; use Luna or a Claude efficient tier only while work stays mechanical.
- `high`: multiple files, real tradeoffs, or substantial ownership; use Terra
  only while the work remains bounded, otherwise use Sol, Fable, or Opus by role.
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

Keep one orchestrator active through integration when possible. If the entry
session cannot own the necessary judgement, make one compact strong-model call
at the decisive stage instead of automatically making separate planning and
final-synthesis calls that re-read the same repository.

## Live sources

- OpenAI model guidance: `https://developers.openai.com/api/docs/guides/latest-model`
- Codex models: `https://learn.chatgpt.com/docs/models`
- Codex CLI commands: `https://learn.chatgpt.com/docs/developer-commands?surface=cli`
- Claude pricing and models: `https://platform.claude.com/docs/en/about-claude/pricing`
