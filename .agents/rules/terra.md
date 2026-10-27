# Terra specialist

Use GPT-6.1 Terra (`gpt-6.1-terra`) for source-grounded writing, interpreting
images, screenshots, and charts, visual QA, or bounded already-authorized tasks
in supported browsers, desktop surfaces, and apps. Examples include checking
desktop/mobile clipping, asset crops, and text placement against supplied screens.

Astra remains the Codex owner; Fable owns direct Claude-led sessions. Sol keeps
code implementation at high and difficult diagnosis at xhigh; Luna keeps
mechanical work at low/medium. Return uncertain architecture, security, or
business decisions to the owner. Choose Terra by scope and available tools;
do not infer comparative quality or cost savings from unmeasured runs.
Keep deterministic extraction, reformatting, and structured summaries with Luna.
Choose Terra for prose synthesis from supplied sources or visual interpretation.

## Route and launch

Follow [routing.md](routing.md) for availability and [delegation.md](delegation.md)
for the hand-off contract. Start at low for simple writing or image inspection;
use medium for multiple sources/screens or multi-step visual/app work. Set the
actual native worker launch fields, with fresh compact context where supported:

```json
{ "model": "gpt-6.1-terra", "reasoning_effort": "medium", "fork_turns": "none" }
```

For one simple writing/image task, set `reasoning_effort` to `low` instead.
Confirm runtime model and effort on the first meaningful task. From a direct
Claude-led session, use the CLI only for writing or static image inspection.
Before launching, check `codex --version` and the compact live catalog: require
CLI 0.159.0 or newer and the exact model and effort. A failed check stops that
route. Run the installed CLI in host context:

```sh
codex exec --model gpt-6.1-terra -c 'model_reasoning_effort="medium"' \
  --sandbox read-only -C /path/to/isolated/context \
  --image /path/to/screenshot.png -o /path/to/result.txt < /path/to/brief.md
```

Use a narrow context directory and provide only necessary sources/screens.
The CLI image example provides static evidence; it does not establish live
browser or app access. Live browser/app tasks require a native Codex worker with
verified tools, or stay with an equipped owner. Verify the worker's actual tools,
permissions, and access before assigning that scope. Prefer a supported connector
when sufficient. A file sandbox does not constrain browser or app connectors.
Missing image/tool/access means stop the affected scope or explicitly retain it
with an equipped owner. Never silently fall back to another model or tool.

## Scope and evidence

The brief names the calling owner, sources/screens, exact read/write paths,
allowed actions, observable acceptance criteria, and no further delegation.
For writing, identify which claims each source supports and preserve uncertainty.
For charts, transcribe legible labels and values and flag estimates or uncertainty.
Return requested totals to the owner for code/CLI calculation or a Luna medium
hand-off under the routing rules. Never tally mentally or delegate further.

For visual QA, report the screen, viewport/device, location, and visible defect.
Label screenshot-only conclusions as static; never claim interactions occurred.
For live app tasks, observe the required final state and return evidence of it.
A click, submitted form, or opened preview alone does not prove completion.
Report blocked steps and remaining uncertainty to the owner.

Delegation expands no permissions. Sending, publishing, purchases, destructive
actions, or other external writes require existing specific user authorization.
Stay within the allowed actions even when the connector exposes broader access.
Send no credentials, personal data, or unrelated material in the hand-off.

Read-only visual QA is not an opposite-provider code or security review.
[reviews.md](reviews.md) still selects the required independent provider, model,
and effort. Terra does not replace those review routes or add a review helper.

## Official guidance

OpenAI describes Terra's writing, visual understanding, and computer use focus
in [Codex models](https://learn.chatgpt.com/docs/models). The CLI requires 0.159.0
or newer; model availability and browser/app capabilities require separate checks.
See also the [October 26 to 30 update](https://learn.chatgpt.com/docs/whats-new/october-26-30-2026).
