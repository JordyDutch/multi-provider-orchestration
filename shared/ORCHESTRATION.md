# Orchestration router

Use this index to load only the guidance needed for the current task. Do not
read every playbook by default.

## Select the workflow

| Task shape | Read | Default shape |
| --- | --- | --- |
| Bounded deterministic work with decisive checks | No extra playbook | One capable agent, focused verification, no automatic review |
| Normal behavioral code, diagnosis, research, or planning | [`playbooks/routing.md`](playbooks/routing.md) and [`playbooks/execution.md`](playbooks/execution.md) | One owner, bounded work, verification; review only when the risk triggers apply |
| Opposite-provider review or audit | [`playbooks/reviews.md`](playbooks/reviews.md) | Smallest relevant evidence, one independent reviewer, owner integrates |
| Security, auth, permissions, funds, destructive work, data-loss risk, migrations, or costly architecture | Routing, execution, and reviews | Strongest suitable owner and mandatory opposite-provider review |
| Global installation, refresh, portability, or model availability | [`playbooks/setup.md`](playbooks/setup.md) | Fail-closed checks and byte-for-byte verification |
| Parallel or multi-agent work | [`playbooks/execution.md`](playbooks/execution.md) | Only independent scopes, bounded fan-out, no unapproved nesting |

## Non-negotiable routes

- Codex-led difficult work is owned by GPT-5.6 Sol. Claude-led difficult work is
  owned by Fable 5.1.
- Every Opus route uses exact `claude-opus-5`; every Fable route uses exact
  `claude-fable-5-1`. Never silently substitute an older model.
- Consequential or uncertain work gets an independent opposite-provider review.
  Deterministic or primary-source-backed work with decisive evidence may skip it.
- Keep planning, integration, and final judgement with one owner. A specialist
  hand-off does not transfer ownership.
- Prefer verification and compact evidence over repeated model sampling.
