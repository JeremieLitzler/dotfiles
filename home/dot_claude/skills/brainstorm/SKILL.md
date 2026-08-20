---
name: brainstorm
description: 'Structure a multi-round brainstorming project — a plan, a feasibility study, a supplier/technology comparison, a technical synthesis — as a versioned folder in the "my-claude-conversations" repo: context dossier, initial prompt, ONE living deliverable rewritten in place with a correction log, numbered feedback rounds, and reproducible calculation scripts. Works from ANY project and on Windows, Linux or macOS — locates the archive clone (data disk on Windows, home directory otherwise), cloning it first if missing. Use when the user opens a subject that needs research and several rounds of refinement ("dégrossir", "cadrer", "brainstorm", "plan", "I need a plan and questions to refine the need"), or asks to resume such a project.'
tools: Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch
---

# Brainstorm

A brainstorming project is **not** a chat that produces a long answer. It is a
folder that accumulates: the facts, the ask, one deliverable that gets rewritten
as it is proven wrong, and the scripts that back every number in it.

The point of the folder is that a future session — on another machine, weeks
later — can reopen it and know what is settled, what was wrong, and what is next.

## 1. Locate or create the folder

**One** command, so the human sees one permission request:

```bash
bash ~/.claude/skills/brainstorm/scripts/locate-brainstorm.sh "<slug>"
```

- `<slug>` is kebab-case, derived from the subject
  (`preparation-projet-solaire-electrique`, `push-notification-strategy`).
- The script locates the `my-claude-conversations` clone and **clones it if
  missing**. Search order depends on the OS — Windows: `/d/Git/GitHub`,
  `/e/Git/GitHub`, `$HOME`; Linux and macOS: `$HOME`, `$HOME/Git/GitHub`,
  `$HOME/git`. Setting `BRAINSTORM_REPO=/path/to/my-claude-conversations`
  overrides the search.
- If a folder ending in `-<slug>` already exists under `prompts/`, it is
  **reused** (resume mode); otherwise it creates `prompts/YYYY-MM-DD-<slug>/`.
- It prints `REPO_ROOT=`, `BRAINSTORM_DIR=`, `MODE=new|resume`, and in resume
  mode an inventory of the files already there.

In resume mode, **read the deliverable first** — version banner, correction log,
and its two state tables (§7) — then the highest-numbered `TODO-*` file. Those
two reads are the resume. Do not re-derive what is already settled.
Older folders use `PROMPT.md` / `README.md` where §2 says `INITIAL-PROMPT.md` /
`CONTEXTE.md` — **keep their names**, renaming only breaks the links inside
them.

## 2. Files

```
prompts/YYYY-MM-DD-slug/
  CONTEXTE.md            durable facts, initial context — optional but usually right
  INITIAL-PROMPT.md      the ask
  PLAN.md                THE deliverable — name it for what it is
  FEEDBACK-PLAN-v1.md    feedback on version 1 → produces version 2
  FEEDBACK-PLAN-v2.md
  analyse/               scripts + their CSV outputs
  <data folders>/        raw inputs + a README documenting provenance
  TODO-<SCOPE>-vN.md     what the human must pick up — offered, never forced
  CHECKLIST.md           on demand, once the plan is validated
```

**Naming rules.**

- The deliverable is named for what it is: `PLAN.md`, `SYNTHESE.md`,
  `COMPARATIF.md`, `ETUDE.md`. There is exactly **one** per project.
- The feedback file **mirrors the deliverable's name**:
  `FEEDBACK-<DELIVERABLE>-vN.md`.
- `FEEDBACK-…-vN.md` holds feedback on **version N**; processing it produces
  **version N+1**. When resuming a folder that numbered things differently,
  follow that folder's existing convention — never renumber history.
- Everything derived from the deliverable keeps its own name in caps:
  `DEVIS-<FOURNISSEUR>.md`, `CAHIER-DES-CHARGES-<X>.md`, `EMAIL-<DESTINATAIRE>.md`.
- **Language follows the human.** French conversation → French documents,
  including headings. Only file names stay in this convention.

Templates: `~/.claude/skills/brainstorm/assets/` (`CONTEXTE.md`,
`INITIAL-PROMPT.md`, `DELIVERABLE.md`, `FEEDBACK.md`). Use them as a starting
shape, not a straitjacket — drop sections that do not apply.

## 3. Opening a new project

1. **Split context from ask.** Everything durable — address, measurements,
   equipment, existing platform, org chart, constraints, budget, images, raw
   transcripts — goes to `CONTEXTE.md` (or a raw material file such as
   `TRANSCRIPT-<X>.md`). The prompt stays about what you want done. Ask the
   human to drop images and exports into the folder; reference them by relative
   path.
2. **Write `INITIAL-PROMPT.md`** — the human's ask, cleaned up, covering: who
   they are and their level on the subject, the objective, the deliverables to
   produce, and the standing instructions. If the human gave the prompt in
   chat, write it to the file anyway; it is the record of what was asked.
3. **Ask before assuming.** Round zero is questions, not answers. A first
   deliverable that ends in a real open-questions section beats one that guesses
   and has to be retracted at v2.
4. **Gate downstream deliverables.** Quotes, specs, emails to third parties are
   produced only once the human says the deliverable is good. State the gate.

## 4. The loop

Each round:

1. **The round opens with feedback**, and it comes in one of two shapes:
   - **A TODO round** — the human took the current `TODO-<SCOPE>-vN.md` away,
     worked through it, and answers it point by point **by ID** (`A1`, `B3`) in
     `FEEDBACK-<D>-vN.md`. This is the loop the TODO exists for.
   - **A spontaneous round** — new material, a correction, a change of
     direction, unrelated to the TODO.

   Either way, if it came in chat, write it to the file yourself before
   answering, so the round is on record. **Which of the two it is decides
   whether the TODO re-versions** (§8) — a spontaneous round must not fork a
   TODO nobody has answered.
2. **Answer every point.** Number your answers to their numbering. When a point
   deserves a full treatment, give it a dedicated section in the deliverable and
   link to it from the version banner.
3. **Rewrite the deliverable in place**, bump the version banner, and add a
   `vN` entry to the correction log stating **what was wrong before**, not what
   was added:

   > - v3: le prix des modules était surestimé de ~75 % ; l'affirmation « la
   >   batterie ne se rentabilise pas » était fausse, faute d'avoir comparé à
   >   l'absence de batterie.

   This log is the most valuable part of the file. A round that only adds
   material and corrects nothing usually means the feedback was not taken
   seriously. Old text lives in git — never keep `PLAN-v3.md` snapshots.
4. **Propagate.** If a locked decision changed, update the deliverable's two
   state tables (§7) and every derived document — quotes, specs, checklist — in
   the same round.

## 5. Rules that make these projects work

- **Never compute in the chat.** Any number that survives into the deliverable
  comes from a script in `analyse/` (§6). Arithmetic done in prose cannot be
  re-run when an input changes at v5 — and it will.
- **Cite sources.** Load-bearing claims — regulation, vendor limits, platform
  behaviour, pricing, best coding or architectural practices — carry a URL. Group them in a `Sources` section with one
  line per source saying what it establishes. Verify with `WebFetch`/`WebSearch`
  rather than recalling.
- **Separate the settled from the open.** The deliverable states its status in
  the banner (`Draft v1 — needs answers to §9`, `✅ Validé le 12/08/2026`) and
  carries the two state tables of §7 — decisions not to reopen, figures not to
  recompute. It is what makes a second file unnecessary, so keep it current.
- **Split questions by audience.** When several parties must answer, one list
  per party, each question addressed to the party that can actually decide it
  (technical feasibility ≠ product arbitration ≠ compliance sign-off).
- **Lead with the recommendation.** §1 says what to do and why; the analysis
  follows. Do not make the human read to the end to learn the answer.
- **Say when the premise is wrong.** "Do not bundle these two problems
  together" and "these panels are more expensive than new ones even if free"
  are the highest-value outputs of these sessions. Deliver them plainly, with
  the numbers.
- **Diagram the mechanisms.** Mermaid sequence diagrams for flows with several
  actors, tables for comparisons, ASCII for architecture sketches.
- **Safety first where it applies.** Physical or financial risk gets a warning
  section at the top, not a footnote.

## 6. Scripts — reproducibility is the deliverable's foundation

Every calculation lives in `analyse/` (or `scripts/`), one script per round or
per question:

- **Docstring header** stating: the round it serves, the question asked, the
  method (and which earlier script it reuses), and the output files.
  See `assets/script-header.py`.
- **Inputs by relative path** from the script's own location — the folder must
  survive being cloned elsewhere. Do not hardcode `D:\…`.
- **Outputs to CSV**, `out_<subject>.csv`, committed next to the script. The
  deliverable quotes them; **the CSV is the source of truth** — say so in the
  banner, so a divergence is resolved by re-running, not by trusting prose.
- **Reuse, do not rewrite.** `simu6_occasion.py` reuses `simu5_feedback.py`'s
  method verbatim and changes only what the new question changes. State that in
  the docstring.
- **Raw data gets a README** in its folder: period covered, row count, columns,
  gaps and how they were handled, DST/duplicate anomalies, totals. A merge that
  is not documented cannot be trusted at v6.

## 7. Two files, not three

A project has exactly **two** places to look, and they never hold the same
thing:

- **The deliverable holds what is settled.** Its version banner says where the
  project stands, and two tables make a cold session productive without any
  second file: **Décisions arrêtées — ne pas les rouvrir** (the decision, its
  value, the reason) and **Chiffres clés — ne pas les recalculer** (each with the
  script that produced it). Known tooling limits and their workarounds go there
  too.
- **`TODO-<SCOPE>-vN.md` holds what is open** — what the human has to pick up
  away from the session: the questions only **they** can answer, from inside
  their own organisation, files or memory. Distinct from the deliverable's open
  questions, which go to third parties — though it can carry the reminder to
  **forward** those third-party questions. See §8.

**Do not create a `RESUME.md`.** It duplicates the deliverable's own tables and
then drifts from them; banner + the two tables + the current TODO already are
the resume. Older folders that still carry one have been renamed to the TODO
convention — if you meet one, rename it too rather than keeping both.

`CHECKLIST.md` is the one further file worth adding, once the plan is validated
and the work moves to doing: ordered, checkable, with the measurements and
verifications to perform.

## 8. The TODO — the pickup file, offered at the end of every response

Track, as you work, everything the human will have to go and find out: a fact
you could not verify, a decision that is theirs, an assumption you had to take,
an action only they can carry out. This is the file they open the next morning.

**The round trip — this is the whole point of the file.** The TODO goes out with
the human; the answers come back as a `FEEDBACK-<D>-vN.md` replying to its
questions **by ID**. That is why questions carry stable `A1`/`B3` IDs: so the
feedback can be a numbered list of answers rather than a retelling. Write the
TODO to be answerable that way. When it comes back, fold each answer where it
belongs — a settled decision into the deliverable's *decisions not to reopen*
table, a corrected fact into the section it invalidates — then rebuild the TODO
with what is still open. **The answers never live in the TODO**: it is the
outbound half of the loop of §4, the feedback file the inbound half.

**End every response in a brainstorm session with one short line** stating what
is pending and offering to write it down — then move on. One line, at the very
end, no follow-up paragraph. It is an offer the human takes or ignores; never
write the file unprompted, never repeat the offer twice in a row for the same
items, and drop the line entirely when nothing is pending.

> 4 points en attente de ton côté (auth e-banking, sortie Internet, langue
> utilisateur, périmètre Alessandro) — je les mets dans `TODO-BACKEND-v2.md` ?

> 2 things only you can check (the ISBN's Lulu listing, the church's tax
> status) — want them in a TODO file?

When they say yes, write `TODO-<SCOPE>-v<N>.md` — `<SCOPE>` is whose homework it
is (`BACKEND`, `MAIRIE`, `PERSO`), `<N>` the TODO's **own** generation. Which
deliverable version it accompanies goes in a line inside the file, not in the
name. Use `assets/TODO.md`:

- **Open the file with the instruction to answer it** — name the exact feedback
  file to create (`FEEDBACK-<DELIVERABLE>-v<X>.md`) and say to reply by ID. The
  human should never have to remember the convention, or wonder whether to
  annotate the TODO itself.
- Questions **grouped by theme under a heading**, each stating what its answer
  changes. Prefix with a priority: 🔴 blocks design or costing · 🟠 structural ·
  🟡 do not forget.
- **Numbering restarts at 1 under every heading.** A heading ends the list;
  markdown renderers restart the ordered list there whatever number you typed,
  so a run continued across themes (`…9.`, `10.`) renders as `1.`, `2.` and
  every cross-reference to it breaks. Reference questions by **theme letter +
  number** — `A1`, `B3` — never by a bare number, and make the theme letter part
  of the heading (`## A. Authentication`) so the ID is readable on the page.
- A closing **"assumptions I took — invalidate if wrong"** list (`H1`, `H2`, …),
  saying which one you consider the most fragile.
- **The TODO is a living file, like the deliverable — edit it in place.** Strike
  what got settled, add what the round opened, re-prioritise. A round that
  rewrites the deliverable does **not** create a TODO.
- **A new version is created only by a TODO round** (§4.1) — a feedback file
  that answers this TODO's questions. Then, and only then, freeze the answered
  file next to the feedback that answered it — together they record what got
  settled and when — and carry the unresolved items into `v<N+1>`. A single
  answer dropped in passing mid-round is folded in place like any other edit. **Never fork a TODO the human has not worked through**: two
  near-identical lists strand their annotations in the superseded one and force
  a reconciliation that buys nothing.

## 9. Closing a round

Tell the human which files changed and the deliverable's new version. Leave
committing to them unless they ask. If the session is worth archiving, the
`save-session` skill is the next step.
