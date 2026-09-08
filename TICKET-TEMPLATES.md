# Ticket templates

Every ticket in a Rapid Lightning Media repo is born on the form for its type. The forms live in `.github/ISSUE_TEMPLATE/` in this repo, and GitHub serves them to every repo in the org. Blank issues are off.

The ruled shape behind the forms is written once, on the RLM share: `rlm-shared://_templates/tickets/ticket-templates.md`. The worked example for every type sits beside it in `samples.md`. The forms, the `/open-ticket` command in both Claude kits, and the board automation's template check all follow that one file. Change the spec first, then the three copies, in the same motion.

## Pick the form

| Type | Pick it when | First heading |
|---|---|---|
| Idea | A thought you do not want to lose. Not decided yet. | Proposed |
| Decision | A call that needs a ruling. | Question |
| Goal | The top umbrella of a program, a roadmap row. | Summary |
| Phase | A group under a Goal. | Scope |
| Discovery | The product phase: rough mockups, what/why/success. | Objective |
| Architecture | The system-design phase: the ADR. | Overview |
| Design | The branded mockups, after Architecture. | Screens |
| Blueprint | The code shape: file-tree diff, signatures, control flow. | Shape |
| Execute | A workable ticket: a slice, a plain build, an ops task. | Mission |
| Bug | Something is wrong. | Symptom |
| PR Ticket | The ticket a PR closes when one change lands in several repos. | Ruling |
| Ops Umbrella | One of the seven standing shelves. Only on a ruling. | Purpose |

A Quarter Bucket has no form. The board automation writes it when the first ticket under an ops umbrella is set Done in a quarter.

## How to write it

Plain, simple English. Short sentences. One idea per sentence. Write for a person who opens the ticket cold.

Do not condense. Three facts are three sentences.

A new idea starts a new paragraph. A blank line sits between paragraphs.

Every section has a heading that names it, in Title Case. Name a ticket as a full link, never a bare number. Dates as `Wed-09/02/2026`. Quotes as `"..." (JD: Wed-09/02/2026)`. Share files as `rlm-shared://path`. Tables and lists, liberally. Number every item someone may refer to later.

Every type ends with the same three sections: Supporting Material, Origin, Related Tickets.

## What the automation does

When a ticket is born, board-cascade reads its body against the template for its type. If a required section is missing, it adds the `template-gap` label and posts one comment naming the sections. Fix the body and the label clears on the next edit. The rule is rlm-ops#484.
