# AGENTS.md

Guidelines and default workflow for AI/code assistants collaborating in this repository.

## Default Mode: Preview Mode (Required)
- Propose changes first. Do not apply edits until explicitly approved.
- Provide:
  - A 1–3 bullet plan.
  - Exact code snippets and insertion/replacement anchors.
  - A concise diff-style preview (only the lines you intend to add/replace/remove).
- Wait for the explicit approval phrase before making any edits.

Approval phrase (required to apply edits):

```
APPROVED: apply changes
```

## Scope and Minimalism
- Only modify the file(s) and function(s) explicitly named by the user.
- Make the smallest possible diff that achieves the stated goal.
- Do not refactor, rename, reorder, or extract code unless explicitly requested.
- Do not add new files, properties, dependencies, or features unless explicitly requested.
- If a change requires touching multiple files, propose the full plan and ask for approval first.

## Ambiguity and Safety
- If anything is ambiguous, ask clarifying questions before proposing a diff.
- When user intent conflicts with existing code, highlight the conflict and propose options.
- Do not expose secrets or sensitive tokens. Avoid logging or displaying credentials.

## Security and Privacy
- Never display or publish secret values (e.g., session cookies, API keys).
- Store sensitive values using the mechanism specified by the user. If unspecified, propose options (e.g., Keychain) and wait for approval.
- Avoid increasing the exposure surface of secrets (e.g., do not make them observable/published unless explicitly required).

## Testing and Verification
- When changes are proposed, include a brief note on how to manually verify the behavior.
- If tests exist, mention which tests are affected or should be added. Do not add tests without approval.

## Communication Style
- Keep proposals concise and structured.
- Use code fences for full snippets and show only the relevant lines in diff previews.
- Summarize exactly what changed after edits are applied.

## Error Handling
- Prefer non-destructive edits that are easy to revert.
- If an edit could be risky, explicitly call it out and suggest a safer alternative.
