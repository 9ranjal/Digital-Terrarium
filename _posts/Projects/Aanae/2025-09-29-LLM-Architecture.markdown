---
layout: post
title: "LLM Architecture"
date: 2025-09-29
tags: [AI, RAG, LLMs, data, Aanae]
---

TL;DR: I built a Planner → Writer → Critic pipeline around DeepSeek (via OpenRouter) where the RAG knowledge base and live web search run as parallel streams that converge at the writer prompt — with domain mandates, temporal awareness, and streaming. The whole thing runs on Render (free tier) + Vercel + Supabase.

The retrieval post ended with chunks selected from 30,000. But the production system doesn't just use those chunks — it runs two parallel knowledge paths (the chunk database and live web search) and merges them before the LLM ever sees them. This post covers that convergence, the answer generation pipeline, and the tech stack holding it together.

For links to all the posts in this series, see [Aanae](/projects/2025/08/26/Aanae.html).

---
## The Tech Stack

Before getting into the LLM logic, here's what runs the system end-to-end:

- **Backend:** Python 3.11, Flask, Gunicorn (gthread, 4 threads), Dockerized
- **Frontend:** React 18, TypeScript, Vite, Tailwind CSS
- **Database:** Supabase (PostgreSQL + pgvector for chunk storage and hybrid search)
- **LLM (production):** DeepSeek Chat via OpenRouter (`deepseek/deepseek-chat`)
- **LLM (local dev):** Ollama running `phi3:medium`
- **Embeddings:** `BAAI/bge-large-en-v1.5` (sentence-transformers)
- **Reranker:** `BAAI/bge-reranker-large` (cross-encoder)
- **Web search:** Serper.dev (Google Search API)
- **Hosting:** Render (backend, free plan) + Vercel (frontend)
- **Caching:** Redis (for PIB current affairs snapshots)
- **Analytics:** PostHog

The provider selection is automatic. `LLMClient` in `api/llm/client.py` checks if the `RENDER` env var is set. If yes, it routes to `OpenRouterClient`. If no, it falls back to `OllamaClient`. I didn't want to think about which provider I'm hitting — on my laptop it's Ollama, in production it's OpenRouter, and the rest of the code doesn't care.

I chose OpenRouter over calling DeepSeek directly because it gives me model switching without code changes. If DeepSeek goes down or a better model shows up, I change one env var (`OPENROUTER_MODEL`) and redeploy. I've already swapped models multiple times without touching code.

---
## The Planner → Writer → Critic Pipeline

The original version was a single LLM call: stuff the chunks into a prompt, ask for an answer, stream it back. It worked, but the answers were inconsistent. Sometimes they'd open with a definition when the question wanted a mechanism. Sometimes they'd miss an important case law or scheme. Sometimes they'd assert a meeting frequency as fact when the actual cadence varies.

I replaced the single call with a three-stage pipeline:

- **Planner** — an LLM call that reads the question, domain, task type, and any verified web sources, then outputs 5–9 content bullets and a mode decision (tutor, smalltalk gate, or clarification gate). It also decides the answer mode: `verdict_first`, `mechanism_first`, `compare_table`, or `policy_brief`.
- **Writer** — the main generation call. It takes the planner's bullets, the retrieved chunks, verified sources, and a structured prompt with domain-specific requirements, then streams the answer.
- **Critic** — a post-generation pass that checks for frequency hedging (governance domains shouldn't assert rigid meeting schedules), MCQ answer completeness, and basic QC (word count, structure).

All three stages are feature-flagged (`PLANNER_ON`, `CRITIC_ON`). I can disable either in production without a deploy. The planner added the biggest quality improvement — the writer follows a plan instead of improvising, so the answers have consistent structure.

---
## Where RAG Meets the Writer

The previous posts covered how chunks get enriched (Enrichment) and retrieved (Retrieval) from the Supabase database. But the production copilot doesn't just run one search — it has two parallel knowledge streams that converge at the writer prompt:

- **The chunk knowledge base (RAG).** The 30,000 enriched chunks in Supabase with embeddings, concept tags, and retrieval scores. These feed in through `build_context_from_request()` as context snippets — either from the user's selected notes, visible content in the frontend, or chat history that references earlier retrieved chunks.
- **Live web search (Serper.dev).** Real-time Google results that get fetched, authority-scored, and verified before the planner even runs. These provide current affairs data that the static chunk database can't have.

The convergence point is the writer prompt in `build_from_plan()`. It takes both:

- `ctx_snippets` — context from the knowledge base (salience-ranked, clipped to 600 chars each)
- `verified_sources` — web results, gated by temporal weight (full content for breaking news, titles-only for stable topics)

For **breaking news queries**, I run a dual search strategy using `asyncio.gather` to fetch two web queries in parallel:

- A **temporal query** (the user's question + current month/year)
- A **UPSC query** (the user's question + "UPSC analysis current affairs")

Both result sets get deduplicated, filtered for temporal relevance (no 2008 articles for a 2025 question), and then passed through a two-stage relevance check: fast heuristic first (do 70% of query terms appear in the title/content?), then a batch LLM call for the ambiguous remainder. This keeps the search fast while filtering out noise.

When verified web sources come in, they *replace* the static context snippets for that query. The logic: if I have current, authority-scored web sources about the topic, those are more useful to the writer than the chunk database's version. The chunk knowledge still matters — it's what the planner draws on through chat history and note context — but for the actual generation call, current affairs get priority.

For stable queries ("What are Directive Principles?"), the web search still runs but gets low temporal weight. The chunk database's context stays primary.

---
## Intent Detection and Task Routing

Before the planner even runs, the system needs to figure out *what kind of question* this is. That happens in two steps:

**Intent detection** (`api/tutor/core/intent.py`) classifies the query as one of:

- `tutor_query` — a UPSC study question
- `correction` — the user is correcting a previous answer
- `smalltalk` — greeting or off-topic chat
- `general_conversation` — casual but not a study question

I use an LLM call for this (same DeepSeek model, lower temperature). Before the LLM, fast heuristics catch obvious cases: if the message is under 4 words and starts with a greeting ("hi", "hello", "hey"), it's smalltalk. If it has a question mark or study verbs ("explain", "define", "compare"), it's a tutor query. The LLM handles the ambiguous middle.

**Task detection** (`api/tutor/core/tasks.py`) determines the *type* of answer needed:

- `define`, `compare`, `analyse`, `critique`, `mechanism`, `history`, `policy_brief`, `caselaw`, `general`

Task detection uses regex first (with support for English, Hinglish, and Hindi cues — `kya hai` maps to `define`, `अंतर` maps to `compare`). If regex is inconclusive, an LLM fallback kicks in. The task type drives downstream choices: minimum word counts, opening strategy, and which domain mandates to apply.

---
## Domain Mandates

Each domain has a set of non-negotiable requirements defined in `api/tutor/core/mandates.py`. These go into the writer prompt so the LLM knows what it *must* include:

- **Polity:** name Articles/Amendments with years, cite case law with holdings, specify status/appointment/tenure
- **Economy:** state allocations/targets in ₹ and %, name implementing agencies, cite at least one evaluation report
- **Environment:** quote Acts with penalties, name institutions (NTCA, CPCB), include a recent notification
- **History:** name 3–5 leaders with roles, include 2–3 Acts/reforms with years, state aims explicitly
- **Geography:** list exact metrics (length, rainfall), explain classification and spatial patterns
- **Ethics:** define the framework, lay out options → consequences → justified course

I built these by hand from UPSC answer-writing rubrics and past toppers' strategies. They're the single most domain-specific piece of the system. A generic RAG pipeline would never ask the LLM to "cite case law with year and holding" — but for UPSC, that's the difference between a good answer and a vague one.

The mandates are also task-aware: comparison nudges only appear when the task is `compare`. Otherwise they're stripped out so the writer doesn't force unnecessary comparisons.

---
## The Writer Prompt

The writer prompt in `build_from_plan()` is the most carefully tuned piece of the system. It assembles:

- **The question, domain, and task**
- **Plan bullets** from the planner (up to 10, clipped to 150 chars each)
- **Context snippets** from retrieved chunks (up to 3, salience-ranked — snippets with data, percentages, dates, and policy terms get priority)
- **Verified web sources** (gated by temporal weight — more detail for current affairs, less for stable topics)
- **Structured facts** from pattern-based verification (compact JSON)
- **Domain quotas** — the per-domain requirements listed above
- **Format policy** — ## headings, bold key terms, 350–400 words, inline citations [1],[2]
- **Opening hint** — "Start with a one-line verdict" or "Begin with a definition" depending on task type

The prompt sanitises all inputs to prevent injection (strips `system:`, `assistant:`, `</s>` patterns). Context snippets get salience-ranked: a snippet containing "₹", "crore", "2025", or "amendment" scores higher than one with generic prose.

Temperature is 0.28 for most answers, 0.32 for deep-density mode. Max tokens: 1,400 default, 1,800 for deep mode. I tuned these by reading hundreds of generated answers and adjusting until the outputs were detailed enough without being padded.

---
## Temporal Awareness and Web Verification

UPSC questions can be about stable concepts ("What are Fundamental Rights?") or time-sensitive facts ("How many tiger reserves does India have?"). The system handles both, but differently.

`plan_from_query()` in the planner calculates a `temporal_weight` (0.0 to 1.0):

- **0.8–1.0 (high):** count queries ("how many"), current queries ("latest", "recent"), rate queries ("inflation rate"), or critical keywords (tax rates, GDP, policy changes). Web sources get full content (500 chars each, 3 sources).
- **0.5–0.75 (medium):** topics with some temporal sensitivity. Web sources get titles and URLs only.
- **< 0.5 (low):** stable topics. Web sources get a header only ("Sources available — use your knowledge").

Web search always runs (via Serper.dev). I used to have the LLM decide whether to verify, but that was unreliable — it would skip verification for questions that turned out to need it. Now web search is unconditional; only the *weight* given to the results changes.

The verified sources go through authority scoring in `api/tutor/verifier.py`: government sites score highest, followed by academic sources, then news. Wikipedia is allowed but scored lower. Social media is blocked entirely. The top 3 sources by combined authority + recency + reliability score make it into the prompt.

---
## Streaming

Answers stream token-by-token to the frontend via Server-Sent Events (SSE). The `copilot_stream_handler` in `api/routes/copilot.py` yields events at each phase:

- `planning` — the planner is generating bullets
- `web_search` — web sources are being fetched and scored
- `planning_ready` — plan bullets are available (shown as "thinking" UI)
- `drafting` — the writer is generating the answer
- `chunk` — a piece of the answer text (streamed incrementally)
- `critique` — the critic is reviewing
- `tutor_response` — the complete answer with metadata, sources, and follow-ups

The OpenRouter client buffers about 40 characters before yielding a chunk (to avoid sending single-token events). Markdown tables get special handling: they're accumulated and sent as complete units so the frontend doesn't try to render half a table.

I strip code fences during streaming. The LLM sometimes wraps its output in triple backticks even though the prompt says not to. Rather than adding more prompt instructions, I just strip them in the streaming loop.

---
## The Critic

The critic is the simplest stage. After the writer finishes, `review_and_patch()` in `api/tutor/quality/critic.py` runs two checks:

- **Frequency hedging.** If the domain is governance/policy/institution and the answer asserts a rigid meeting cadence ("meets quarterly") without qualifiers ("usually", "typically"), the critic appends a hedging note. I added this after the system confidently stated that NITI Aayog meets "quarterly" when there's no statutory schedule.
- **MCQ answer line.** If the question looks like an MCQ (has `(A)`, `(B)` options) but the answer doesn't have an explicit "Answer: Option X" line, the critic infers the option from the text and appends it.

The critic also has access to a knowledge base (`critic_kb.py`) for domain-specific corrections — for example, "Panchamrit" in a UPSC context must reference COP26 climate pledges, not the Hindu ritual.

I kept the critic simple on purpose. A heavy critic that rewrites the answer would add latency and risk introducing its own errors. The current version catches two specific failure modes I saw repeatedly, and that's enough.

---
## The Frontend

The frontend is a React 18 + TypeScript app built with Vite and styled with Tailwind. I chose these because I knew them and they're fast to iterate with — I wasn't optimising for framework choice, I was optimising for shipping.

The app has a 3-pane resizable layout:

- **Left sidebar** — module navigation (Copilot, Quiz, Notes, Flashcards)
- **Main content** — the active module
- **Right sidebar** — context-specific: quiz stats, note editor, flashcard sessions

The Copilot module is the core. It uses `useStreamingChat` to parse SSE events, accumulates chunks incrementally, and renders with `react-markdown` (with `remark-gfm` for tables, `remark-math` + `rehype-katex` for LaTeX, and `rehype-highlight` for code). Citations come through as `[1]`, `[2]` in the markdown and get parsed into interactive pills — hover to see the source, click to open.

I spent more time than I expected on markdown rendering. The LLM's output has formatting quirks: tables without proper newlines, headings without blank lines before them, backticks where there shouldn't be any. I wrote `_normalize_markdown_tables()` and `de_template()` on the backend to fix these before the text reaches the frontend, plus a `MarkdownRenderer` component that handles the remaining edge cases (LaTeX normalisation, table separator stripping, PIB article CTA buttons).

The frontend is deployed on Vercel. The backend Flask app runs on Render's free tier inside a Docker container (Python 3.11-slim, Gunicorn with gthread workers). Supabase handles auth and the chunk database. Redis (also on Render) caches PIB current affairs snapshots.

---
## Choices I Made and Why

**DeepSeek over GPT-4.** Cost. OpenRouter lets me route to DeepSeek Chat at a fraction of GPT-4's price. For UPSC tutoring, DeepSeek's quality is good enough — it handles Indian polity, economy, and geography well, likely because of the multilingual training data. If I needed stronger reasoning I'd switch, but I haven't needed to.

**Planner as a separate LLM call.** This doubles the LLM calls per query. I accepted the latency because the quality improvement was large. The planner call is fast (500 max tokens, low temperature) and the structured output means the writer rarely goes off-track.

**Regex before LLM for task detection.** Speed and cost. Most UPSC queries match a pattern ("What is X?", "Compare A and B", "Explain the mechanism of..."). The regex catches 70–80% of queries in under a millisecond. The LLM fallback handles the rest. I also added Hinglish and Hindi regex patterns because some users mix languages.

**Streaming over batch.** Non-negotiable for UX. A 4–6 second wait for the full answer feels broken. Streaming the answer token-by-token, with phase events ("Planning...", "Searching...", "Writing..."), makes the same latency feel interactive.

**Render free tier.** The backend is stateless (all state is in Supabase and Redis), so Render's free tier works — cold starts are the main pain point (~15–20 seconds after inactivity). I could fix this with a paid plan, but for now it's acceptable for a project at this stage.

**Feature flags for everything.** Planner, critic, QC preflight, stream phases, web search — all toggleable via env vars. This let me ship incrementally. I'd turn on the planner in production, watch the logs for a day, then turn on the critic. If something broke, I'd flip it off without a deploy.

---
## Evaluation

I built an evaluation framework to measure whether the answers are actually correct. `copilot/eval/prelims_eval.py` runs the full RAG pipeline against a dataset of 100 UPSC prelims MCQs, compares the LLM's chosen option against the gold answer, and writes structured results: accuracy by subject, latency percentiles, grounding and hallucination rates, chunk citation analysis, and error breakdowns.

The results across three runs told me where things stand:

- **Accuracy:** 37–38% on prelims MCQs — not great, but this is a hard benchmark (4-option MCQs across all UPSC subjects, random baseline is 25%)
- **Grounding:** 93–100% of answers were supported by retrieved chunks (the LLM used the context, not just its own knowledge)
- **Hallucination rate:** 0–7% — low, which means the retrieval + prompt design is working
- **Citation usage:** 89% of answers included chunk citations, with an average citation ratio of 0.4
- **Solve/leave:** the LLM can choose to "leave" a question if unsure — 90% solve rate, 1% leave rate

Each result record is a structured Pydantic model (`ResultRecord`) with latency breakdowns per question, retrieval metadata (which chunks were cited, scores, reranker lift), grounding checks, and the full solver JSON (question type, confidence, elimination steps). The eval writes JSONL results and a summary JSON per run.

---
## What's Still Open

The eval covers prelims MCQs, where there's a clear gold answer. What it doesn't cover yet: whether individual factual claims in mains-style answers are grounded in the source chunks, subtle hallucinations within otherwise correct answers, or cases where the answer contradicts the retrieved evidence. The grounding check is coarse — "did we have sources and reasonable confidence?" — not fine-grained claim-level verification.

I also haven't fine-tuned the embedding model or the LLM on UPSC-specific data. The system runs on general-purpose models with domain knowledge injected through prompts, mandates, and retrieval. Fine-tuning is the obvious next step if I want to push accuracy past the current ceiling.

The pipeline works well enough that I use it for my own UPSC prep. That was the bar I set at the start.

---

_This is the last post in the Aanae series — for now._
