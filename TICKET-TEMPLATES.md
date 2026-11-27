# Ticket templates

Every ticket in a Rapid Lightning Media repo is born on the form for its type. The forms live in `.github/ISSUE_TEMPLATE/` in this repo, and GitHub serves them to every repo in the org. Blank issues are off.

The ruled shape behind the forms is written once, on the RLM share: `rlm-shared://_templates/tickets/ticket-templates.md`. The worked example for every type sits beside it in `samples.md`. The forms, the `/open-ticket` command in both Claude kits, and the board automation's template check all follow that one file. Change the spec first, then the three copies, in the same motion.

## Pick the Form

The source of these forms is the part "Shapes in the New Tree" of the ticket shapes page, `rlm-shared://_templates/tickets/ticket-templates.md`.

| Form | Type | Pick it when | First heading |
|---|---|---|---|
| Idea | Idea | A thought you do not want to lose. Board automation adds its Explore and Decide Steps. | Proposed |
| Outcome | Outcome | One thing a person can open and test, under the Build Stage, a Run or a Market. The title starts `O1: `. | Outcome |
| Task | Task | A unit of work for one doer. | Mission |
| Decide Task | Task | A Task that holds a ruling. The title starts `Decide`. | Mission |
| Bug | Bug | The code is wrong. A bug in a released version goes under that version's Run. | Symptom |
| Alert | Alert | Something went wrong and a person should look. A machine usually opens it. | Alert |
| PR Ticket | PR Ticket | The ticket a pull request closes when no open ticket fits it, or when one change is merged in several repos. | Ruling |

Goals, Stages, Steps and Quarter Buckets have no form. Board automation makes each of them.

## How to write it

Plain, simple English. Short sentences. One idea per sentence. Write for a person who opens the ticket cold.

Do not condense. Three facts are three sentences.

A new idea starts a new paragraph. A blank line sits between paragraphs.

Every section has a heading that names it, in Title Case. Name a ticket as a full link, never a bare number. Dates as `09/02/2026-Wed`. Quotes as `"..." (JD: 09/02/2026-Wed)`. Share files as `rlm-shared://path`. Tables and lists, liberally. Number every item someone may refer to later.

Every type ends with the same three sections: Supporting Material, Origin, Related Tickets.

## What the automation does

When a ticket is born, board-cascade reads its body against the template for its type. If a required section is missing, it adds the `template-gap` label and posts one comment naming the sections. Fix the body and the label clears on the next edit. The rule is rlm-ops#484.
