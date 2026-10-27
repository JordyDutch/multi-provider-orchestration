# Assigning specialists

Astra owns Codex-led work; Fable owns direct Claude-led entry sessions. The entry
owner scopes tasks, selects workers, resolves decisions, integrates results, and
verifies completion. Delegation never transfers ownership.

## Select and launch

Use the roles and quality gates in [routing.md](routing.md). For suitable work,
launch that specialist before implementing its scope yourself.
Keep tiny work with the owner or shell and unresolved decisions with that owner.
Do not launch every available model.

| Assigned work | Worker | Execution route |
| --- | --- | --- |
| Implementation, tests, bounded analysis | Sol high for implementation, medium for bounded analysis, xhigh for difficult diagnosis | Native Codex worker; `codex exec` from Claude |
| Mechanical extraction, inventory, transformations | Luna low/medium; Haiku 5.5 low for read-only search; Sonnet 5.5 low/medium for edits | Native Codex worker; `codex exec` from Claude; `haiku-scout`, `sonnet-worker`, `haiku-task`, `sonnet-task` |
| Writing, visual QA, bounded app tasks | Terra low/medium | Native Codex worker; CLI from Claude for writing/static images only; [terra.md](terra.md) |
| Frontend/UX or substantive implementation by fit | Opus high | `opus-worker` or `opus-task` |
| Architecture input, difficult diagnosis, complex analysis or implementation | Fable high | `fable-specialist` or `fable-task` |

Use Fable early for difficult scopes; a failed Sol or Opus run is not required.
Either entry owner may choose any listed worker by fit. Avoid duplicate work;
review effort follows `reviews.md`. Native Claude workers use the pinned agent
types in [claude-native.md](claude-native.md).

For native Codex workers, set both `model` and `reasoning_effort`; use
`fork_turns: "none"` with a fresh brief when that interface supports it.
Do not rely on inherited models or unverified custom agent profiles. If the
runtime cannot select the requested model, report that and retain the scope
with the entry owner.

## Direct Claude to Codex

From Claude, use installed `codex exec` in host context. Native Codex workers
exist only inside Codex. Run the compact catalog filter in [routing.md](routing.md)
before the first hand-off. If pipelines are disallowed, use a private temporary
catalog file and run `jq` separately. Never dump the raw catalog.

```sh
codex exec --model gpt-6.1-sol -c 'model_reasoning_effort="high"' \
  --sandbox read-only -C /path/to/worktree -o /path/to/result.txt \
  < /path/to/brief.md
codex exec --model gpt-6-luna -c 'model_reasoning_effort="low"' \
  --sandbox read-only -C /path/to/worktree -o /path/to/result.txt \
  < /path/to/brief.md
```

Reviews use the helper selected by `reviews.md`; this CLI route is for delegated
work only. For already-authorized local edits in isolated worktrees or
non-overlapping paths, change `--sandbox` to `workspace-write`.
The working directory is not a read boundary; keep the brief's read scope narrow.
Do not use permission bypass or model fallback flags. Capture exit status and
result; confirm model/effort from the startup banner and saved session
`turn_context` metadata on the first meaningful run. Extract those fields only,
not full transcripts. The Claude owner integrates results and required checks.

## Task brief

Brief with goal, exact read/write paths, acceptance criteria, commands/evidence,
constraints, calling owner, edit authorization, and no further delegation.
Workers return changed files/findings, actual checks, blockers, and owner decisions.
Exclude transcripts, credentials, personal data, and unrelated material.

Announce the selected model and scope once, then verify the runtime model and
effort on its first meaningful task; a requested name is not proof of use.

## Claude task helpers

Run these installed helpers in host context so Claude uses its subscription
login; they preflight authentication. Each starts a fresh session from an
explicit working directory and brief file:

```sh
opus-task /path/to/worktree /path/to/brief.md
fable-task --effort high /path/to/worktree /path/to/brief.md
sonnet-task --effort medium /path/to/worktree /path/to/brief.md
haiku-task --advisor /path/to/worktree /path/to/brief.md
opus-task --edit /path/to/worktree /path/to/brief.md
```

Sessions carry no orchestrator history, though Claude's built-in and user-level
startup context can still load.

The default is read-only. Use `--edit` only for local edits already authorized
by the task. Give parallel writers isolated worktrees or non-overlapping paths.
Use a narrow working directory containing only the relevant repository context;
named paths in the brief are instructions, not a file-level sandbox.

The helpers pin `claude-opus-5-5`/high, `claude-fable-5-1`/high,
`claude-sonnet-5-5`/low (medium for batches), or `claude-haiku-5-5`/low.
`--advisor` attaches the pinned Fable 5.1 advisor; see
[claude-native.md](claude-native.md). They expose file reading/searching, plus
Edit/Write only in edit mode. Restricted mode confines file tools to the
working directory and exposes no shell, MCP, or nested-agent tools; tests, Git,
and other commands stay with the entry owner.

Helpers reject unsupported CLI capabilities, failed authentication, invalid
briefs, provider errors, permission denials, and mismatched runtime model
metadata. They never silently substitute a model. Failed runs retain a private
result file and print its path for diagnosis. A failed editing task may have
left partial changes: inspect the diff before recovery. Keep polling the
same process while its response is buffered; do not launch duplicate tasks.

Task analysis does not replace mandatory independent review; select it with
`reviews.md`, then integrate and verify without repeating the worker's work.

Official interfaces: [Codex subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents)
and [Claude CLI](https://code.claude.com/docs/en/cli-reference).
