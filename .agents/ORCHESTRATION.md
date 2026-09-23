# Orchestration router

Use this index to load only the guidance needed for the current task. Do not
read every playbook by default.

## Select the workflow

| Task shape | Read | Default shape |
| --- | --- | --- |
| Bounded deterministic work with decisive checks | No extra playbook | Active owner or provider-appropriate efficient tier; focused verification; no automatic review |
| Normal behavioral code, diagnosis, research, or planning | [`rules/routing.md`](rules/routing.md) and [`rules/execution.md`](rules/execution.md) | One provider-appropriate owner, bounded work, and risk-appropriate review |
| Opposite-provider review or audit | [`rules/reviews.md`](rules/reviews.md) | Smallest relevant evidence, one independent reviewer, owner integrates |
| Security, auth, permissions, funds, destructive work, data-loss risk, migrations, or costly architecture | Routing, execution, and reviews | Strongest suitable owner and mandatory opposite-provider review |
| Global installation, refresh, portability, or model availability | [`rules/setup.md`](rules/setup.md) | Fail-closed checks and byte-for-byte verification |
| Parallel or multi-agent work | [`rules/execution.md`](rules/execution.md) | Only independent scopes, bounded fan-out, no unapproved nesting |

## Canonical rules

- `rules/routing.md` is the canonical model and effort ladder; the active
  baseline summarizes the no-playbook deterministic route.
- `rules/reviews.md` determines when review is required and selects its
  provider and effort. Task size alone does not require review.
