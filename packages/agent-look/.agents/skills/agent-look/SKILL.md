---
name: agent-look
description: Use when the user asks to automatically check their current physical presence or availability using the webcam, or when deciding whether to interrupt the user would materially benefit from a one-shot visual state signal. Wraps the local agent-look CLI; do not use for continuous monitoring.
---

# Agent Look

Use this skill to get a one-shot webcam context signal for AI agent work.

## When To Use

Use `agent-look` automatically when the current task would materially benefit from knowing whether the user appears present or available, especially:

- before asking a non-urgent clarification during a long-running task
- before interrupting the user after background work completes
- when the user asks whether they are present, away, or available
- when the user says to "look", "check camera", "see if I am here", or similar

Do not use it for routine turns, high-frequency polling, or continuous monitoring.

## How To Use

Prefer a single capture:

```sh
agent-look status
```

If full analysis is unnecessary, capture only the image path:

```sh
agent-look capture --json
```

The CLI stores only the latest reduced-size image under `~/.local/state/agent-look/latest.jpg` and overwrites it on the next capture.

## Interpretation Rules

Use the result only as a weak state signal. Keep conclusions observational:

- OK: person visible, no person visible, looking away from camera, lighting usable, background details visible
- Avoid: identity, emotion, age, gender, health, fatigue, intent, productivity, sensitive attributes

If the signal is ambiguous, say it is ambiguous and ask normally.

## Interruption Policy

If the user appears absent, avoid asking non-urgent questions immediately. Continue safe background work, summarize blockers, or wait for explicit user input.

If the user appears present, you may ask concise clarification questions when needed.

If `agent-look` fails because of camera permissions or sandboxing, do not retry repeatedly. Explain the failure and continue without camera context.
