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
| Mechanical extraction, inventory, transformations | Luna low, medium for batches or table aggregates | Native Codex worker; `codex exec` from Claude |
| Frontend/UX or substantive implementation by fit | Opus high | `opus-task` |
| Architecture input, difficult diagnosis, complex analysis or implementation | Fable high | `fable-task` |

Use Fable early when its capability fits a difficult scope. Astra can assign it
directly; a failed Sol or Opus attempt is not a prerequisite. Either entry owner
may choose suitable Sol, Luna, or Opus scopes. Keep briefs focused and avoid
duplicate work. Review effort still follows `reviews.md`.

For native Codex workers, set both `model` and `reasoning_effort`; use
`fork_turns: "none"` with a fresh brief when that interface supports it.
Do not rely on inherited models or unverified custom agent profiles. If the
runtime cannot select the requested model, report that and retain the scope
with the entry owner.

## Direct Claude to Codex

Native Codex workers exist only inside Codex. From a direct Claude-led session,
Fable can use the installed `codex exec` in host context. Run the compact live
catalog filter in [routing.md](routing.md) once before the first hand-off; do
not dump the raw catalog. If the shell disallows a pipeline, redirect the
catalog to a private temporary file and run `jq` separately.

```sh
codex exec --model gpt-6-sol -c 'model_reasoning_effort="high"' \
  --sandbox read-only -C /path/to/worktree -o /path/to/result.txt \
  < /path/to/brief.md
codex exec --model gpt-6-luna -c 'model_reasoning_effort="low"' \
  --sandbox read-only -C /path/to/worktree -o /path/to/result.txt \
  < /path/to/brief.md
```

Use Luna `medium` for batches and Sol `xhigh` for difficult diagnosis. Reviews
use the helper selected by `reviews.md`; this CLI route is for delegated work
only. For already-authorized local edits in isolated
worktrees or non-overlapping paths, change `--sandbox` to `workspace-write`.
The working directory is not a read boundary; keep the brief's read scope narrow.
Do not use permission bypass or model fallback flags. Capture exit status and
result; confirm model/effort from the startup banner and saved session
`turn_context` metadata on the first meaningful run. Extract those fields only,
not full transcripts. The Fable owner integrates results and required checks.

## Task brief

Give each worker a concise goal, exact read/write paths, acceptance criteria,
relevant commands or evidence, and known constraints. Include the calling owner,
whether edits are authorized, and a prohibition on further delegation. Workers
return changed files or findings, checks actually performed, blockers, and
decisions for the calling owner. Do not send conversation transcripts,
credentials, personal data, or unrelated repository material.

Announce the selected model and scope once. Verify the runtime model and effort
on its first meaningful task. A requested model name alone is not proof of use.

## Claude task helpers

Run these in host context so Claude can use its existing subscription login.
The installer provides both helpers; they preflight authentication themselves.
Each starts a fresh session from an explicit working directory and brief file:

```sh
opus-task /path/to/worktree /path/to/brief.md
fable-task --effort high /path/to/worktree /path/to/brief.md
opus-task --edit /path/to/worktree /path/to/brief.md
```

The conversation is fresh; Claude's built-in and user-level startup context can
still load. The helpers do not copy the orchestrator's conversation history.

The default is read-only. Use `--edit` only for local edits already authorized
by the task. Give parallel writers isolated worktrees or non-overlapping paths.
Use a narrow working directory containing only the relevant repository context;
named paths in the brief are instructions, not a file-level sandbox.

The helpers pin `claude-opus-5-5` or `claude-fable-5-1`, default to high effort,
and expose file reading/searching, plus Edit/Write only in edit mode. Restricted
mode confines file tools to the working directory. They expose no shell, MCP,
or nested-agent tools. The entry owner runs the required tests and Git
operations. This route supports code edits; assignments needing commands return
to that owner.

Helpers reject unsupported CLI capabilities, failed authentication, invalid
briefs, provider errors, permission denials, and mismatched runtime model
metadata. They never silently substitute a model. Failed runs retain a private
result file and print its path for diagnosis. A failed editing task may have
left partial changes: inspect the diff before recovery. Keep polling the
same process while its response is buffered; do not launch duplicate tasks.

Read-only task analysis is not a substitute for mandatory independent review.
Use `claude-review`, `fable-review`, `sol-review`, or `astra-review` by authorship
and risk, then integrate and verify without repeating the worker's work.

Official interfaces: [Codex subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents)
and [Claude CLI](https://code.claude.com/docs/en/cli-reference).
