# Plans — visual reference pages

Source HTML for the three published reference pages. They are kept here so they
are version-controlled and editable; the published copies live at claude.ai and
are private until deliberately shared.

| File | Published as | What it covers |
|---|---|---|
| [`network-architecture.html`](network-architecture.html) | *Two VNets, No Bridge* | Logical and physical topology, address plan, decisions D-01 to D-04, NSG baseline, control-type mapping |
| [`deployment-plan.html`](deployment-plan.html) | *Three Places, One Lab* | Where each component runs, RAM budget against real hardware, cost per configuration, build order |
| [`first-thirty-days.html`](first-thirty-days.html) | *The First Thirty Days* | Day-by-day build plan with `az` commands, costs, and the trigger for lifting into Azure |

**These are derived documents, not sources of truth.** The authoritative versions
are [`infra/network-architecture.md`](../../infra/network-architecture.md) and
[`docs/business-plan.md`](../business-plan.md). If the two disagree, the markdown
wins and these need regenerating.

Diagrams are hand-authored HTML/CSS rather than Mermaid, deliberately. Mermaid
renders against the *viewer's* theme in a published artifact, which collided with
the fixed diagram panel and produced unreadable text. Hand-built CSS takes every
colour from the same token set as the page, so both themes are guaranteed.

To republish after editing, ask Claude to publish the file again — same path
keeps the same URL.
