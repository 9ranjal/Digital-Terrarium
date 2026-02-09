---
layout: post
title: "Agentic Pipeline for Document Review"
date: 2025-02-28
tags: [Babel, Legaltech, AI, LLMs]
---

**TL;DR** -- An uploaded term sheet flows through a five-stage async pipeline that decomposes it into a scored clause graph. A copilot explains the deterministic analysis in plain language. A LangGraph state machine generates term sheets from natural-language deal descriptions. The LLM never picks the band; it explains what the engine already decided.

*For links to all the posts in this series, see [Babel](/2025/01/31/what-is-babel.html).*

---

## The Decomposition Pipeline

```
PARSE_DOC → CHUNK_EMBED → EXTRACT_NORMALIZE → BAND_MAP_GRAPH → ANALYZE
  parsed      chunked        extracted           graphed          analyzed
```

Each stage is a job in a PostgreSQL-backed queue, idempotent and retriable. The pipeline runs to completion without human intervention once the upload fires.

**Stage 1 — Parse.** *Purpose: turn arbitrary document formats into structured blocks the rest of the pipeline can use.* Downloads the blob from Supabase Storage and attempts structured parsing via Docling (IBM), falling back to PyMuPDF for PDFs or Mammoth/python-docx for DOCX files. Each fallback strategy cascades until one succeeds. Output: a `blocks[]` array (headings, paragraphs, tables with row/column metadata) and plaintext stored on the document record.

**Stage 2 — Chunk & Embed.** *Purpose: create searchable units and optional embeddings for semantic retrieval.* Each block becomes a chunk with `block_id`, `page`, `kind`, and `text`. If embeddings are enabled, 1536-dim vectors are generated and stored as pgvector columns with an IVFFlat index on cosine distance for approximate nearest-neighbour search.

**Stage 3 — Extract & Normalize.** *Purpose: identify clause boundaries and extract structured attributes for banding.* Two-phase clause detection. First, regex extraction classifies sections by heading lookup (`CANONICAL_HEADING_MAP`) and body-pattern matching (`BODY_HINTS`), and pulls structured attributes (days, percentages, multiples, participation type) from clause text. Second, LLM normalisation coerces the output at temperature 0.0; the LLM only normalises what the regex already extracted (e.g. standardising phrasing), it does not override clause keys or band choice, so determinism is preserved. Clauses are inserted into the database and linked to their source chunks.

**Stage 4 — Band, Map, Graph.** *Purpose: build a navigable graph of clauses with band/posture and cross-clause links.* Builds the clause decomposition graph. Three node types: a document root, category nodes (nine negotiation buckets), and clause nodes enriched with `band`, `badge`, and `tilt` from the scoring engine. Hierarchical edges connect `doc → category → clause`. Second-order edges encode cross-clause trade relationships:

```python
SECOND_ORDER_LINKS = {
    "rofr":                    ["tag_along", "rofo"],
    "tag_along":               ["rofr", "drag_along"],
    "drag_along":              ["exit"],
    "exclusivity":             ["rofo", "rofr", "tag_along"],
    "anti_dilution":           ["pay_to_play"],
    "liquidation_preference":  ["reserved_matters", "board"],
}
```

Links are symmetric in the sense that if A links to B, B typically links back (e.g. `rofr` ↔ `tag_along`). They are only added when both clause nodes exist in the current document, so the graph adapts to each term sheet's content. Output: a Cytoscape.js-compatible `graph_json`.

**Stage 5 — Analyse.** *Purpose: run the consensus engine on every clause and persist posture, score, and trades.* Runs the deterministic analysis per clause: extract attributes → match band → compute composite score → determine posture (±0.2 threshold) → upsert into the analyses table. The document is now fully processed.

---

## The Graph as Negotiation Map

The frontend renders the graph with **Cytoscape.js** using a force-directed layout. Document node at the centre, category nodes sized by clause count, clause nodes as rectangles with band badges and posture-coloured borders. Clicking a clause highlights its neighbourhood and triggers copilot analysis. The second-order edges surface trade possibilities: clicking `exclusivity` shows its links to `rofo`, `rofr`, and `tag_along`. A "highlight non-market" toggle fades balanced clauses to foreground contentious terms.

---

## The Copilot

The copilot's core design decision: **the LLM explains the deterministic result, it doesn't pick the band.** The engine has already matched the value to a band, scored it, and determined posture. The LLM translates that into prose a non-technical founder or investor can understand -- and adds colour (risks, leverage dynamics, precedent) that the math alone doesn't capture.

The clause analysis route supports a `?reasoned=` parameter: `reasoned=false` returns pure deterministic banding (fast, no LLM call); `reasoned=true` computes the deterministic result first, then the copilot explains it. The LLM is always an overlay, never the source of truth.

---

## Term Sheet Generation via LangGraph

Babel can also **generate** term sheets from a natural-language deal description. The generator is built with **LangGraph** as a stateful, multi-step workflow:

```python
class DealState(TypedDict):
    nl_input: str                                    # "Series A, $5M at $20M pre"
    overrides: Optional[DealOverrides]               # Parsed deal terms
    deal: Optional[DealConfig]                       # Full config with defaults
    validation_errors: List[str]                     # Any issues
    selected_clause_ids: List[str]                   # Which templates to use
    rendered_term_sheet: Optional[str]               # Final HTML output
    clarification_questions: Optional[List[str]]     # If input is ambiguous
```

```
input → parse_nl → apply_defaults → validate_deal → select_clauses → render_ts → output → END
```

Each node reads and writes to the shared `DealState`. The LLM extracts structured deal terms from natural language at temperature 0.0, defaults are merged from a market-standard base config, validation checks business rules, clause templates are selected and deduplicated, and the final term sheet is rendered as HTML. The graph is linear for now but the architecture supports clarification loops.

---

## Design Patterns (agentic behaviour)

Here "agentic" means multi-step workflows that run without human intervention between steps — goal-directed only in the sense that each step has a clear input/output contract and the next step is enqueued on success. Babel doesn't use a single "agent" framework; that behaviour emerges from several patterns:

| Pattern | Where | How |
|---|---|---|
| **Multi-step state machine** | `ts_generator/graph.py` | LangGraph with typed state, node-per-stage, conditional-edge-ready |
| **Tool-augmented reasoning** | `copilot_service.py` | LLM receives deterministic banding output as structured context |
| **Structured extraction** | `parse_nl` node | LLM → JSON schema (`DealOverrides`); temperature 0.0 |
| **Fallback chains** | `parse_docling.py`, `parse_docx.py` | Docling → PyMuPDF → Mammoth → python-docx → XML → plaintext |
| **Prompt grounding** | `analyze_clause()` | Band data injected into the prompt; the LLM explains, it doesn't invent |
| **Idempotent job chaining** | `workers/runner.py` | Each handler enqueues the next stage; crash at any point and it resumes |
| **Deterministic + LLM split** | `?reasoned=` flag | Core analysis is always deterministic; LLM is an optional layer |

The term-sheet generator is the clearest agentic example: unstructured input → LLM extraction → validation → template selection → rendered document, all without human intervention. The worker pipeline is agentic in a systems sense: five chained idempotent jobs, each capable of independent retry, coordinated by a queue.

---

## Technology Stack

| Layer | Technology | Role |
|---|---|---|
| **Frontend** | React + TypeScript, Zustand, Cytoscape.js | SPA with graph visualisation, state management, chat |
| **API** | FastAPI (Python, async) | REST endpoints with CORS, OpenAPI docs |
| **LLM Orchestration** | LangGraph | State-machine workflow for term sheet generation |
| **LLM Provider** | OpenRouter (DeepSeek v3.1 default) | Chat completions, structured extraction |
| **Database** | Supabase (PostgreSQL + pgvector) | Relational storage, RLS, vector search |
| **Document Parsing** | Docling (IBM), PyMuPDF, Mammoth, python-docx | Multi-strategy parsing with cascading fallbacks |
| **BATNA Engine** | TypeScript (`packages/batna/`) | Band matching, composite scoring, shared with frontend |
| **Job Queue** | PostgreSQL (`FOR UPDATE SKIP LOCKED`) | Five-stage async worker pipeline |
| **ORM** | SQLAlchemy (async, `asyncpg`) | Database access with session management |
