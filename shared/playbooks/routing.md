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
then fall back once and report the unavailable route.

## Current roles

| Role | Model | Use |
| --- | --- | --- |
| Codex owner | GPT-5.6 Sol (`gpt-5.6-sol`) | Difficult planning, architecture, implementation, diagnosis, integration, and final judgement |
| Codex everyday | GPT-5.6 Terra (`gpt-5.6-terra`) | Scoped implementation, repository analysis, tests, and bounded support work |
| Codex efficient | GPT-5.6 Luna (`gpt-5.6-luna`) | Clear extraction, classification, transformation, and mechanical work |
| Claude owner | Fable 5.1 (`claude-fable-5-1`) | Claude-led orchestration and complex cross-cutting review |
| Claude coding/review | Opus 5 (`claude-opus-5`) | Substantive implementation, frontend/UX, and independent review |
| Claude efficient | Sonnet 5 (`claude-sonnet-5`) | Low-risk bulk reading and mechanical support after live verification |

Model availability is volatile. Reverify before changing this table. Never use
bare or `latest` aliases for pinned Opus and Fable routes.

## Choose by consequence

| Work | Owner or worker | Review |
| --- | --- | --- |
| Deterministic inventory, formatting, generation, or mechanical edit | Luna low/medium, Terra medium, or Sonnet after verification | None when checks are decisive |
| Normal scoped behavior change | Terra medium/high or Opus high; current entry owner integrates | Opposite provider when behavior, unfamiliarity, or uncertainty warrants it |
| Substantial multi-file work | Sol high or Fable high owns; bounded workers by fit | One normal strong opposite-provider review |
| Hard diagnosis or conflicting evidence | Sol/Fable xhigh for the unresolved question | Independent second opinion |
| Security, auth, permissions, funds, destructive change, data loss, migration, costly architecture | Sol/Fable xhigh; max only for the hardest remaining judgement | Mandatory strongest suitable opposite-provider review |
| Large task with truly independent workstreams | Sol ultra only when supported, or explicit bounded workers | Owner synthesis plus risk-appropriate review |

Do not launch a cheaper scout if the startup and integration cost exceeds doing
the bounded work in the active owner. Do not run the same successful task at
every tier.

## Effort

- `low`: narrow execution and mechanical support.
- `medium`: normal scoped planning, implementation, and checking.
- `high`: multiple files or real tradeoffs; default for substantial ownership.
- `xhigh`: difficult diagnosis, security, or ambiguous design; use on the small
  decisive stage.
- `max`: hardest remaining single-agent judgement, not a default.
- `ultra`: top-level automatic multi-agent work only; never nest it.

Keep one orchestrator active through integration when possible. If the entry
session cannot own the necessary judgement, make one compact strong-model call
at the decisive stage instead of automatically making separate planning and
final-synthesis calls that re-read the same repository.

## Live sources

- OpenAI model guidance: `https://developers.openai.com/api/docs/guides/latest-model`
- Codex models: `https://learn.chatgpt.com/docs/models`
- Codex CLI commands: `https://learn.chatgpt.com/docs/developer-commands?surface=cli`
- Claude pricing and models: `https://platform.claude.com/docs/en/about-claude/pricing`
