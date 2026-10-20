# FuRescue mobile docs

This folder is a **thin phone wrapper**. It does not replace the web study.

Paste-ready briefing for a new Cursor chat (web + phone): [`D:\pepot\furescue\docs\plans\CONTEXT_PROMPT.md`](../../furescue/docs/plans/CONTEXT_PROMPT.md).

Read the web repo first. Then read the files in this folder. To bring the server up and check the phone, start at [04-handover-run.md](04-handover-run.md).

## 1. Web (product “what”)

Sibling: `D:\pepot\furescue`.

1. `docs/study/OBJECTIVES.md`
2. `docs/study/SIGNIFICANCE_AND_SCOPE.md`
3. `docs/study/CONCEPTUAL_FRAMEWORK.md`
4. `docs/study/REQUIREMENTS_SPECIFICATION.md`
5. `docs/technical/WORKFLOWS.md` — roles, status machines, page map
6. `src/Http/Routes` — live endpoints (do not copy into this repo)

`docs/technical/FEATURES.md` in the web repo can lag the code. Trust routes + workflows over that inventory.

## 2. This folder (phone “how”)

| File | What it covers |
|------|----------------|
| [01-mobile.md](01-mobile.md) | Client vs API, roles on the device, screen map, architecture, opens |
| [02-how-to-run.md](02-how-to-run.md) | Flutter + physical phone + how the phone hits the local API |
| [03-handover.md](03-handover.md) | What the phone client already does, and what is still open |
| [04-handover-run.md](04-handover-run.md) | Seed, serve, and check from the PHP server through this app |

No API catalog. No copied objectives.

## Labels

| Label | Meaning |
|-------|---------|
| **STUDY** | Stated in the web study. Treat as a requirement. |
| **IMPLEMENTATION** | Phone-only engineering decision. |
| **OPEN** | Must be confirmed. Do not invent it in the app. |

If web and these files disagree, **web wins** except Flutter / phone rules.
