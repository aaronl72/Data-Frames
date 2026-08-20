# Information Security Policy

| | |
|---|---|
| **Document owner** | Aaron — Founder & Principal Consultant, Data-Frames |
| **Applies to** | Data-Frames (data-frames.com), including all systems, data, and infrastructure operated under the business, and any contractor or employee granted access in the future |
| **Version** | 1.0 |
| **Effective date** | 2026-08-19 |
| **Review cycle** | Annual, or on any material change to infrastructure, services, or applicable law |
| **CISSP domain mapping** | Domain 1 — Security & Risk Management |

## 1. Purpose

This policy states Data-Frames' commitment to protecting the confidentiality, integrity, and availability (CIA) of its own information assets and any client information entrusted to it, and defines the baseline rules that govern how that protection is carried out. It exists both as the operating standard for the business and as the artifact a prospective client can review to judge whether Data-Frames holds itself to the standard it sells.

At the business' current single-operator stage, one person (Aaron) holds every role this policy assigns. The policy is deliberately written as if the business will scale — with named roles rather than "the owner does everything" — so that adding a contractor or employee later is a matter of assigning an existing role, not rewriting the policy.

## 2. Scope

Applies to:
- The `data-frames.com` marketing site and its GitHub repository/CI pipeline
- The Azure subscription hosting the Wazuh SIEM, Metasploit lab, and Shuffle SOAR (private VNet)
- The `network-packets.com` honeypot and its Azure VNet (isolated from the above)
- Domain registrar (GoDaddy) and DNS
- Any client data, credentials, or engagement artifacts Data-Frames holds during or after an engagement
- Any future contractor, subcontractor, or employee acting on Data-Frames' behalf

Out of scope: client-owned infrastructure and data while it is on the client's own systems — those are governed by the engagement's rules of engagement and the client's own policies, not this one.

## 3. Policy Objectives (CIA Triad)

- **Confidentiality** — information is disclosed only to those authorized to see it, at the classification level defined in §5.
- **Integrity** — information and systems are protected from unauthorized or unintended modification, and changes are traceable.
- **Availability** — systems and data are accessible to authorized parties when needed, commensurate with the business impact defined in the BCP/DRP.

## 4. Roles and Responsibilities

| Role | Responsibility | Currently held by |
|---|---|---|
| Business Owner | Ultimate accountability for this policy, risk acceptance decisions, budget for security controls | Aaron |
| Security Officer | Maintains this policy and the risk register, runs the annual review, approves exceptions | Aaron |
| System Administrator | Azure/VNet/VM administration, patching, backup execution, access provisioning | Aaron |
| Incident Responder | Executes incident response per the IR plan (see §9), first point of contact for client-facing incidents | Aaron |
| Data Custodian | Handles client data day-to-day per its classification (§5) | Aaron |

Any future hire is assigned one or more of the roles above rather than inheriting undefined authority.

## 5. Data Classification

All information handled by Data-Frames falls into one of four levels. Handling requirements scale with the level.

| Level | Definition | Examples | Minimum handling |
|---|---|---|---|
| **Public** | Cleared for public release | Marketing site content, published blog posts, service descriptions | No restriction |
| **Internal** | Not for public release, but not sensitive if leaked | Business plan, pricing sheets, internal process notes | Access limited to Data-Frames personnel; no restriction on internal tooling |
| **Confidential** | Damaging to the business or a client if disclosed | Client contracts, engagement scope documents, non-public financials, credentials to Data-Frames-owned systems | Encrypted at rest and in transit; access limited to those with a defined need; MFA required for any system storing it |
| **Restricted** | Severely damaging if disclosed; regulatory exposure | Pentest findings and raw vulnerability data, client PII/PHI encountered during an engagement, honeypot-captured attacker data that could implicate a real third party, any credential with write access to client or Data-Frames production systems | Encrypted at rest and in transit; access limited to named individuals on a documented need-to-know basis; retained only as long as the engagement or legal requirement demands, then securely destroyed; no storage on personal/unmanaged devices |

Classification is assigned by whoever creates or receives the information, defaulting to the higher level when in doubt.

## 6. Access Control

- **Least privilege** — access is granted only to what a role requires, not by default to everything in the subscription.
- **MFA is mandatory** on Azure, GitHub, the domain registrar, and any system holding Confidential or Restricted data.
- **No shared credentials.** Every human or service identity is uniquely attributable; service principals are scoped to a single system, not subscription-wide.
- **Credential storage** — no plaintext credentials in source control, chat, or unencrypted notes. A password manager or Azure Key Vault is the only sanctioned store.
- **Credential lifetime** — MFA covers the login event, not a credential already issued. API keys, deploy tokens, and service credentials are therefore short-lived and auto-rotated wherever the platform supports it (e.g., OIDC-based per-run tokens for CI/CD instead of a long-lived stored secret), so a leaked credential is only useful for a bounded window rather than indefinitely.
- **Access review** — access rights are reviewed at least annually, and immediately on any role change or offboarding.
- **The two-VNet separation** (Wazuh/lab vs. honeypot) is itself an access control: no routine credential, account, or trust relationship is shared between the honeypot VNet and the private lab VNet, so a honeypot compromise cannot pivot into production tooling.

## 7. Acceptable Use

- Data-Frames-owned systems are used for business purposes; incidental personal use is permitted if it does not create risk (e.g., no personal software installs on systems holding Confidential/Restricted data).
- Metasploit and other offensive tooling are used **only** against Data-Frames-owned infrastructure (the honeypot/lab) or a client's environment with signed, current authorization on file. Never against any third party without that authorization.
- No exfiltration of client Restricted data to personal accounts, devices, or unapproved cloud storage, for any reason including "just to work from home."

## 8. Asset Management

- All infrastructure (Azure resources, domains, GitHub repos) is tracked in a single inventory (currently: this repo's `infra/` documentation) with an owner and a classification of the highest-sensitivity data it touches.
- Decommissioned assets (old VMs, expired domains, deprecated repos) are removed from the inventory only after data on them has been securely wiped or the resource deleted.

## 9. Incident Response

Full procedures live in a separate IR playbook (planned, ties to the Shuffle SOAR build) — this policy establishes the obligation:

- Any suspected security incident affecting Data-Frames or client systems is reported and triaged **within 4 hours** of detection or notification.
- Client-affecting incidents are communicated to the client per the timeline in their engagement agreement, and no later than legally required breach-notification windows for their jurisdiction/industry.
- Post-incident, a lessons-learned review updates this policy or the risk register if the incident reveals a gap.

## 10. Business Continuity

Full plan lives in the companion **BCP/DRP** document. This policy establishes that recovery time and recovery point objectives are defined per-system there, and that the plan is tested at least annually.

## 11. Third-Party and Vendor Risk

Current vendors: Microsoft Azure (infrastructure), GitHub (source control, CI/CD, Pages hosting), GoDaddy (domain registration), and any SaaS tooling added later (e.g., Shuffle if hosted rather than self-run).

- Vendors holding or processing Confidential/Restricted data are reviewed for their own security posture (SOC 2, ISO 27001, or equivalent) before onboarding, where a paid tier or enterprise agreement makes that documentation available.
- Vendor access is scoped to what the integration requires; API keys and service credentials follow §6.

## 12. Compliance and Legal

- Data-Frames aligns its own controls and client-facing recommendations with NIST CSF, CIS Controls, and MITRE ATT&CK, as reflected on the marketing site.
- Client engagements involving regulated data (HIPAA for healthcare clients, etc.) are governed additionally by that regulation's requirements, layered on top of this policy, not in place of it.
- All offensive testing (Metasploit or otherwise) requires a signed rules-of-engagement/authorization document before any activity begins — no exceptions, including for prospective/trial clients.

## 13. Security Awareness

At single-operator scale, this is Aaron's own continuing education (including CISSP study). As the business adds people, this section expands to require documented onboarding security training and annual refreshers for all personnel.

## 14. Policy Review and Exceptions

- This policy is reviewed annually by the Security Officer role, or sooner if infrastructure, services, or law change materially.
- Exceptions require written justification, a defined expiration date, and Security Officer sign-off — an exception is never permanent by default.

## 15. Enforcement

Violation of this policy by any Data-Frames personnel (currently: Aaron holding himself to it) is grounds for corrective action up to termination of access or, for contractors, termination of engagement. Client-facing violations are additionally subject to the terms of the relevant engagement agreement.
