---
layout: post
title: "Underwriting Companies in the Deranged Age"
date: 2026-02-17
tags: [AI]
categories: writing
---

*How CFOs and General Counsels should evaluate AI-enabled companies when models commoditise software*

---
You've likely read Matt Schumer's [Something Big is Happening](https://fortune.com/2026/02/11/something-big-is-happening-ai-february-2020-moment-matt-shumer/) or seen talk of the [Saaspocalypse](https://indianexpress.com/article/explained/explained-economics/ai-automation-anthropic-saaspocalypse-it-sector-10528263/) in recent weeks and are trying to place yourself on the Utopia-to-Skynet spectrum.

The Walker Percy quote (also cited in [A16z's Techno-Optimist Manifesto](https://a16z.com/the-techno-optimist-manifesto/)) feels apt:

> “You live in a deranged age — more deranged than usual, because despite great scientific and technological advances, man has not the faintest idea of who he is or what he is doing.”

But CFOs and General Counsels don't have the luxury of 'not having the faintest idea' when most companies now either sell an AI product, sell tools to other AI builders, or add AI to legacy workflows. Capital still needs allocation and risk still needs pricing.

This demands a rubric that updates SaaS-era diligence frameworks (QoE, cash flow, working capital, balance sheet, IP, material contracts) for **training data & IP**, **model dependency**, **evaluation infrastructure**, and **token economics**.

Read more on this below or access the [Conclusion and TL;DR Checklist](#conclusion-and-tldr).

---
## 1) Financial Diligence (Classic Rubric, AI Additions)

### I. Quality of Earnings (QoE): Normalise EBITDA for AI

QoE asks whether EBITDA holds up once you strip out temporary effects. AI adds a few distortions that show up often.

#### A. Normalisation Adjustments

**Revenue distortions**
- Pilot “AI transformation” contracts treated as recurring ARR.
- Upfront implementation/customisation fees booked as recurring revenue.
- Temporary spikes tied to launches or hype cycles.
- “Free usage” promotions that pull-forward demand.

**Cost distortions**
- Provider credits and discounted model pricing.
- Eval and labelling spend that is missing or pushed out.
- Capitalised “AI development” that is mostly experiments and prompt work.

**QoE diligence ask**
- Per-customer gross margin distribution (not just average).
- API cost line items and credit schedules.
- Evidence of recurring vs one-time revenue components.

Critical QoE question:

> EBITDA needs to work at normalised token costs, without credits, with steady-state usage.

#### B. Pro-Forma Adjustments (Reality-check the forward story)

Forward projections in AI often assume falling token costs, free quality gains from new models, clean open-source migration, and rapid enterprise rollout. Pro-forma needs stress tests that match how the stack behaves in real life.

Run cases where:
- Model costs rise **2–5x**.
- Output quality plateaus and humans stay in the loop.
- Provider terms change or a provider builds the same feature.
- Procurement slows and payment cycles extend.

---
### II. Cash Flow, Working Capital, and Debt

AI businesses can burn cash even when the P&L looks fine. The problem is timing and volatility.

Usage can jump overnight. Provider bills arrive fast and may not sync with invoicing and realisation cycles. Check:
- Billing lag vs usage.
- Whether customers prepay.
- Limits, throttles, and overage pricing in contracts.

Tie this back to economics:
If the company cannot slow heavy usage without breaking SLAs, cash exposure rises.

---
### III. Balance Sheet and Tax

Balance sheets often hide AI liabilities.

Review:
- Data license obligations and royalties.
- Deferred compute liabilities and committed spend.

Tax issues get missed until a buyer asks for reps:
- **GST/VAT** exposure on cross-border API/compute use.
- Withholding on foreign vendors.
- Transfer pricing if a group entity intermediates the spend.

---
### III. Token Economics: Why SaaS Math Breaks

AI gross margin depends on tokens. Tokens scale with usage. Some customers cost more to serve than they pay.

#### A. Margin Sensitivity

Request:
- Gross margin at current model pricing.
- Gross margin at **2x / 3x / 5x** pricing.
- Margin by cohort, with the heavy-user tail called out.

#### B. Heavy-User Losses

Many teams price per seat while costs scale per token. The result is negative-margin accounts.

Look for:
- Overage pricing.
- Fair-use limits.
- Model routing that saves cost.

#### C. Cost Controls That Exist Today

Check how the following are implemented:
- Caching and batching.
- Context trimming.
- Cheap-first routing with fallbacks.
- Distillation and smaller models.
- Hybrid or self-hosting in a defined segment.

#### D. Evals as Cost Discipline

Strong eval systems stop silent cost creep. They also prevent teams from defaulting to the most expensive model for every call.

Ask for:
- Quality-per-dollar benchmarks.
- Alerts for cost drift.
- Rollback triggers tied to cost and quality.

---
## 2) Legal Diligence (IP, Contracts, Market Access, Security)

Traditional legal diligence still applies but AI shifts the center of gravity to **data rights, vendor dependency, and liability allocation**.

### I. IP Diligence: Training Data & Rights Are the New Crown Jewels

#### A. Data Provenance, Chain of Title, and Statutory Transparency

Core question:

> “Do you legally own or license the data that underpins the product—and can you prove it?”

Review:
- Data source agreements and licenses.
- Customer data usage clauses and consent frameworks.
- Data lineage documentation (what went where, when, and under what rights).
- Exclusivity and transferability (especially on change of control).

“Unclear provenance” is not just a litigation risk but also a **market access risk**:
- The **EU AI Act** moves toward **general application in August 2026**, raising the stakes for documentation, transparency, and governance for in-scope systems.
- Transparency/reporting regimes (for example, **California AB 2013**–style disclosures) shift diligence from “can we defend a lawsuit?” to “can we legally operate and sell?”

Red flags:
- “We found it on the internet” datasets.
- No documented provenance.
- No contractual rights to use customer data for improvement.
- Weak internal access controls or audit trails.

Practical test:

> “Can you reconstruct the source, rights basis, and usage scope for any dataset used in training/fine-tuning—and produce it in audit-ready form?”

#### B. Hard Context vs Soft Context (Legal Reality)

**Hard context (defensible):**
- Exclusive licenses.
- Regulated access workflows (certifications, approvals).
- Long history of expert annotations.
- Data network effects that competitors can’t bootstrap.
- Contractual barriers that prevent competitors from access.

**Soft context (replicable):**
- Prompts and prompt heuristics.
- Founder expertise.
- Generic scraped or purchasable data.

Diligence should classify each claimed “data moat” as hard or soft.

#### C. Fine-Tuned Models and Ownership

Clarify:
- Who owns fine-tuned weights, if any?
- Are they portable across providers?
- Are there restrictions on retraining or commercialisation?
- Does vendor ToS create hidden encumbrances?

#### D. Prompt as Trade Secret (Usually Not)

System prompts are rarely durable IP. Potentially defensible IP includes:
- Proprietary eval suites and benchmarks.
- Domain-specific safety/alignment layers.
- Human-in-the-loop workflows with unique feedback data.
- Workflow orchestration tied to regulated operations.

---
### II. Material Contracts: Customers, Vendors, and the Liability Boundary

#### A. Customer Contracts (Where Liability Hides)

Key clauses to review:
- Liability caps for AI outputs (and exclusions).
- Indemnities (IP, privacy, output harms).
- Disclaimers for hallucinations and reliance.
- Audit rights and security obligations.
- Data usage rights (including model improvement).
- IP ownership of AI-generated outputs and derivatives.

Key checks:
- Are indemnities uncapped?
- Does the company accept liability it cannot control (model behaviour)?
- Are SLAs consistent with token-cost realities?

#### B. Vendor Contracts: Model Providers, Cloud, and Dependencies

Review:
- Pricing escalation and unilateral change-in-terms rights.
- Termination rights and suspension triggers.
- Data retention and deletion obligations.
- Competitive restrictions and use limitations.
- IP/derivative work constraints (fine-tuning, outputs).

Single-vendor risk should be explicit and quantified.

#### C. Open Source and Third-Party Dependencies

If the product uses open-source models/tools, ensure:
- License compliance (Apache/MIT vs GPL contamination risk).
- Proper attribution and notice files.
- Clear policy on model weights and derivative distributions.
- Third-party dataset license compatibility.

#### D. LLM Security

Require:
- Prompt injection defenses.
- Output filtering where needed.
- Logging and monitoring.
- Incident response playbooks.
- Clear boundaries on what the model can access.

---
## Conclusion and TL;DR

The old questions were:
- **What do you own?** (IP chain of title, codebase, patents)
- **How sticky is revenue?** (ARR quality, churn, expansion)
- **Do margins scale?** (near-zero marginal cost, operating leverage)
- **Can they keep competitors out?** (product differentiation, integrations, switching costs)

The new questions are:
- **What rights do you actually have over the inputs?**  
  Training data, customer data, outputs, and improvement rights. Show chain of title and audit-ready provenance.
- **Who controls your COGS and your roadmap?**  
  Model providers and cloud vendors. Show pricing power exposure, ToS encumbrances, and the real cost to switch.
- **Do unit economics hold under stress?**  
  Gross margin at 2x/3x/5x token pricing, heavy-user tail, billing lag, and cash exposure.
- **Can the system ship safely as models change?**  
  Evals, drift monitoring, rollback discipline, and time-to-adopt new models without breaking SLAs or compliance.

### TL;DR: Checklist for Every Deal

#### Financial
- **Quality of Earnings:** Rebuild EBITDA without provider credits, subsidised model pricing, under-spent eval/label costs, and aggressive capitalisation of “AI development”.
- **Token-cost sensitivity:** Show gross margin at **2x / 3x / 5x** model pricing. Include the heavy-user tail.
- **Customer-level margins:** Break out gross margin by customer and by cohort. Flag negative-margin accounts.
- **Working capital stress:** Map usage spikes to billing cycles. Show exposure when customers pay late and model providers bill on time.
- **Compute commitments:** List cloud minimum spends, GPU leases, penalties, and any off–balance sheet commitments.
- **Tax exposure on compute:** Check **GST/VAT** on cross-border API/compute, withholding on foreign vendors, and transfer pricing where group entities sit between buyer and provider.
- **Cost controls in production:** Show what is already live: caching, routing, context trimming, distillation, hybrid/self-hosting.

#### Legal
- **Data rights:** Produce chain of title for training and fine-tuning data. Include licenses, consent, transferability, and exclusivity.
- **Market access:** Show readiness for **EU AI Act (general application Aug 2026)** and disclosure regimes such as **California AB 2013** where relevant.
- **Fine-tuning ownership:** Confirm who owns fine-tuned weights/derivatives and what the model-provider terms restrict.
- **LLM security:** Controls for prompt injection, data leakage, logging, and incident response.

#### Architecture
- **Evals:** Automated regression across quality, cost, latency, and safety. Provide at least one example where evals blocked a bad release.
- **Model abstraction:** Ability to swap providers or models in weeks. Show routing logic and fallbacks.
- **Observability:** Trace requests to outputs, detect drift, and roll back quickly. Provide runbooks.
- **EODOR cadence:** Evidence of fast Evaluate → Deploy → Observe → Rollback cycles in production.
