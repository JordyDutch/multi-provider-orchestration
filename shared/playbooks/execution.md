# Execution and parallelism

Read this guide for substantial implementation, multi-agent work, or final
integration.

## Quality-first efficiency

1. Protect decisive planning, implementation, diagnosis, and final judgement.
2. Use efficient tiers only for bounded support work with explicit success
   criteria.
3. Prefer tests, a concrete diff, and primary sources over extra model sampling.
4. Reuse one good repository map; do not ask multiple workers to rediscover it.
5. Send compact hand-offs and return findings or patches, not transcripts.
6. Stop when verification and the required independent review are decisive.

## Parallel work safety

- Identify dependencies before fan-out. Parallelize only two or more meaningful
  independent scopes when concurrency shortens the critical path.
- Use the smallest useful fan-out. Startup context and integration work are real
  costs, so keep short or sequential tasks with one driver.
- Workers receive explicit ownership and a bounded return format. They do not
  spawn more workers unless the owner explicitly authorizes a bounded second
  level. Automatic `ultra` delegation is top-level only and never nested.
- Read-only workers may share a worktree only when their commands cannot mutate
  the index, caches, generated files, ports, or databases.
- Parallel writers use isolated worktrees or explicitly non-overlapping file
  ownership. Never let two workers edit the same file concurrently.
- Start verification concurrently only when commands do not contend for shared
  mutable state. Collect every exit status and report failures or live processes
  before completion.
- The entrypoint owner integrates overlapping ideas, resolves disagreements,
  inspects the final diff, and runs final verification.

## Workflow shapes

### Deterministic

1. Inspect the exact scope.
2. Make the narrow change with an efficient capable tier.
3. Run the focused deterministic check.
4. Skip delegation and review while consequence and ambiguity remain negligible.

### Normal behavioral work

1. One owner scopes the behavior and verification.
2. The owner or one bounded worker implements; avoid duplicate implementations.
3. Run focused tests and inspect the integrated diff.
4. Use one opposite-provider review when the risk triggers in `reviews.md` apply.
5. Validate findings, fix confirmed defects, and rerun affected checks.

### Critical or hard work

1. Sol or Fable owns a bounded plan at high/xhigh.
2. Strong models handle decisive scopes; efficient tiers handle only explicit
   support work.
3. Run focused and broader verification.
4. The opposite provider reviews the changed risk boundary at the strongest
   suitable tier.
5. The original owner reconciles findings and makes the evidence-based final
   judgement. Use max only for the hardest unresolved question.
