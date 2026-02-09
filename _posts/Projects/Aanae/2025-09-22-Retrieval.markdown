---
layout: post
title: "Retrieval"
date: 2025-09-22
tags: [AI, RAG, LLMs, data, Aanae]
---

TL;DR: I went from a naive vector-only search that missed obvious keyword matches to a hybrid pipeline — dense embeddings + sparse text search + cross-encoder reranking — that retrieves 5 chunks out of 30,000 with enough precision for UPSC answers.

The enrichment post ended with self-contained chunks: entities, concept tags, retrieval scores, embeddings. But none of that matters if the system can't *find* the right 5 chunks when a user asks a question. That's retrieval.

Chunking decides the boundaries. Enrichment fills in the context. Retrieval decides what the LLM actually sees.

For links to all the posts in this series, see [Aanae](/2025/08/26/Aanae.html).

---
## Why Retrieval Is the Hard Part

The naive version was simple: embed the query, compute cosine similarity against all 30,000 chunk embeddings, take the top 5. I shipped that first and it worked — for about half the queries.

The failures fell into two patterns:

- **Keyword misses.** A query about "Article 370" would retrieve chunks about "special status of Jammu and Kashmir" (semantically close) but miss the chunk that literally said "Article 370" in the text. Embeddings are good at meaning, bad at exact terms.
- **Semantic drift.** A query about "Green Revolution" would pull in chunks about agriculture broadly — crop patterns, MSP, APMC — because the embedding space clustered all agriculture together. The chunk that actually explained the Green Revolution (Norman Borlaug, HYV seeds, Punjab) got buried under generically related content.

Both problems pointed the same way: I needed more than embeddings. I needed keyword matching for precision, and I needed a reranker to sort the good from the close-but-wrong.

---
## The Retrieval Pipeline

The pipeline evolved across several commits. The first version was a monolithic `supabase_retriever.py` in the copilot directory (`c7a2789`, July 30) — keyword extraction, semantic boosting, and retrieval all in one file (226 lines). When I modularized the API in September (`804bb66`), retrieval split into three files under `copilot/retrieval/`:

- **`retriever.py`** — query embedding, candidate retrieval (Supabase RPC + local fallback)
- **`reranker.py`** — cross-encoder reranking
- **`metadata_augmentation.py`** — optional metadata fusion scoring

The SQL functions that power the database-side search went through their own evolution:

- **`001_hybrid_search.sql`** — first attempt: RRF (Reciprocal Rank Fusion) combining full-text and vector search, 384-dim embeddings, `ts_rank` for keywords
- **`002_update_embedding_dimension.sql`** — upgraded to 1024-dim embeddings (BGE-large), same RRF logic
- **`006_add_hybrid_search_function.sql`** — simplified: 70% vector similarity + 30% retrieval score, added quality filters (`omit_flag = false`, `chunk_quality != 'poor'`), added IVFFlat index
- **`008_match_chunks_rpc.sql`** — the current version: separate dense/sparse scores, hybrid formula with domain-specific bonuses, returns 5x candidates for reranking
- **`009_match_chunks_rpc_no_embedding.sql`** — performance pass: skip returning the 1024-dim vector by default, enforce minimum `entity_density >= 0.12`

Each migration was a response to something I saw failing in practice. I didn't plan the final architecture upfront.

---
## How a Query Gets Answered

When a query hits `run_simple_rag()` in `simple_rag.py`, the pipeline goes:

1. **Embed the query.** The `QueryEmbedder` encodes the query with the same BGE model used for chunks, but with a different prefix: `"Represent this question for retrieving supporting passages: {query}"`. The asymmetric prefix matters — BGE was trained with different prefixes for queries vs. passages.
2. **Retrieve candidates.** The embedded query goes to Supabase's `match_chunks` RPC, which runs both dense (cosine similarity) and sparse (PostgreSQL `ts_rank_cd`) search in a single SQL call. It returns up to `k * 5` candidates — I over-retrieve deliberately so the reranker has a pool to work with.
3. **Rerank.** A cross-encoder (`BAAI/bge-reranker-large`) scores each `[query, chunk_text]` pair. This is slower than embedding similarity but much more accurate — the cross-encoder sees both texts together and can catch subtle relevance that dot products miss.
4. **Deduplicate and truncate.** Remove duplicate `chunk_id`s, take the top `n` (default 5), and truncate the combined context to 12,000 characters.
5. **Generate.** The selected chunks go to the LLM as context.

The defaults: `top_k = 10`, `top_n = 5`, `hybrid_weight = 0.7` (70% dense, 30% sparse). I tuned these by running evaluation queries and watching which chunks surfaced.

---
## Dense Search (Embeddings)

The dense path computes cosine similarity between the query vector and every chunk's stored embedding. In Supabase, this is:

```sql
(1 - (c.embedding <=> embedding)) AS dense_score
```

The `<=>` operator is pgvector's cosine distance. I subtract from 1 to get a similarity score (higher = better).

I index the embeddings with IVFFlat (`lists = 100`). IVFFlat is an approximate nearest-neighbor index — it partitions the vector space into 100 clusters and only searches the closest clusters at query time. It's not as accurate as exact search, but it's fast enough for 30,000 vectors. If I ever scale to 100k+, I'll look at HNSW instead.

The embedding model is `BAAI/bge-large-en-v1.5` (1024 dimensions). I chose it because it was the top-performing open model on MTEB benchmarks at the time I was evaluating, and it ran on my laptop for local development. The query gets a different instruction prefix than the passages — that asymmetric encoding is what makes BGE work well for retrieval specifically, not just generic similarity.

---
## Sparse Search (Keywords)

The sparse path uses PostgreSQL's built-in full-text search:

```sql
ts_rank_cd(to_tsvector('simple', c.chunk_text), plainto_tsquery('simple', q_text)) AS sparse_score
```

I use the `simple` text search config, not `english`. The `english` config applies stemming (so "amending" matches "amendment"), which sounds helpful but caused problems: it would match too broadly on UPSC terms where the exact form matters. `simple` does tokenization and lowercasing but no stemming, which gave me better precision for queries like "Article 370" or "Fundamental Rights."

The sparse score handles the cases embeddings miss: abbreviations (GDP, SEZ, NABARD), article numbers, section references, exact proper nouns. A query about "DPSP" will get a high sparse score for chunks containing "DPSP" even if the embedding model doesn't associate the abbreviation strongly with "Directive Principles of State Policy."

---
## Hybrid Scoring

The two scores get combined in the SQL function:

```sql
hybrid_score = dense_score + 0.35 * sparse_score + bonus
```

The weighting is asymmetric: dense gets full weight, sparse gets 0.35x. I arrived at this ratio empirically. When I weighted them equally, keyword matches dominated and I'd get chunks that mentioned the query term but were about the wrong topic. When I made sparse too low, I was back to the embedding-only problem. 0.35 was where keyword matches helped without taking over.

On the Python side, I also compute a configurable hybrid:

```python
hybrid_score = (dense_score * hybrid_weight) + (sparse_score * (1 - hybrid_weight))
```

The default `hybrid_weight` is 0.7. The SQL formula and the Python formula differ slightly in structure — the SQL version is additive with a fixed weight, the Python version is a weighted average. In practice the Python-side recalculation only matters for the local development mode; in production the SQL hybrid score drives initial ranking, and the reranker overrides the order anyway.

There's also a domain-specific bonus I added for a specific failure case: short Excel chunks about biodiversity and water bodies were consistently ranked too low because their word count penalized them in the dense score. I added a +0.15 bonus for Excel chunks under 40 words with semantic type `biodiversity_conservation` or `water_bodies`. It's a narrow fix, but it solved a real retrieval gap for geography questions.

---
## Reranking

The initial hybrid retrieval gets me into the right neighbourhood. The reranker gets me to the right house.

I use `BAAI/bge-reranker-large`, a cross-encoder model. Unlike the bi-encoder used for embeddings (which encodes query and document separately), the cross-encoder takes the `[query, document]` pair as a single input and outputs a relevance score. This is fundamentally more accurate — it can attend across both texts — but too slow to run on all 30,000 chunks. So I use it as a second stage on the top candidates.

The flow in `reranker.py`:

- Take the retrieved candidates (typically 25–50, since I retrieve `k * 5`)
- Pair each candidate's text with the query
- Truncate: query to 512 characters, chunk text to 4,000 characters
- Run the cross-encoder in batch
- Sort by rerank score

If reranking fails (model loading error, timeout), I fall back to the hybrid score. I'd rather return imperfectly-ranked results than nothing.

The reranker made the single biggest difference in answer quality. Before adding it, the system would often surface 3 good chunks and 2 mediocre ones. After reranking, I consistently got 4-5 relevant chunks in the top 5. The cross-encoder catches nuances that cosine similarity misses — a chunk might be embedding-close but topically tangential, and the reranker pushes it down.

---
## Quality Gates in the Database

Not every chunk in the database is eligible for retrieval. The SQL function enforces gates:

- **Quality filter:** only chunks with `chunk_quality IN ('ok', 'high')` — anything flagged as `poor` during enrichment is invisible to search
- **Entity density floor:** `entity_density >= 0.12` — chunks with very few entities relative to their length are excluded (these tend to be filler or transitional text)
- **Omit flag:** enrichment's unified omit logic already set `omit_flag = true` on low-value chunks, and the earlier `hybrid_search` function filtered those out

I also support optional filters that get passed through from the API:

- `semantic_type_primary_in` — restrict to specific semantic types (e.g., only `definition` chunks)
- `source_type_in` — restrict to markdown or excel sources
- `min_entity_density` — override the default 0.12 floor

These filters let the frontend or the query planner narrow the search space when the query has a clear intent. A "define X" query can request only `definition`-type chunks. A query about government data can request only `excel` sources.

---
## The Fallback Chain

Production systems fail. I built the retrieval layer with explicit fallbacks:

- **Primary:** call `match_chunks` RPC (the latest, optimized function)
- **Fallback:** if `match_chunks` fails, call the older `hybrid_search` RPC (simpler, fewer features, but still functional)
- **Last resort:** return an empty list and let the RAG pipeline tell the user it couldn't find relevant information

Each RPC call goes through a retry wrapper with exponential backoff (3 attempts, delays of 1s → 2s → 4s). Supabase occasionally has cold-start latency on functions, and the retry catches that.

I also built a local mode for development. When I set `RAG_LOCAL_CHUNKS=true`, the system loads all chunks from a local JSON.gz file, builds a TF-IDF index with scikit-learn, and runs hybrid retrieval without touching Supabase. This let me iterate on retrieval logic without depending on the network or burning API calls. The local mode uses the same hybrid scoring formula but replaces PostgreSQL's `ts_rank_cd` with TF-IDF cosine similarity.

---
## Metadata Fusion (The Experiment)

After getting hybrid + reranking working, I tried adding a third signal: metadata-based scoring. The idea was to boost chunks based on their enrichment metadata — entity density, quality score, semantic type match, domain tag overlap with the query.

I built `metadata_augmentation.py` for this: extract feature vectors from each candidate, compute entity-type matching bonuses, and fuse them with the rerank score using configurable weights (alpha for rerank, beta and gamma for metadata components, with a bonus cap).

I gated this behind `META_SCORE_ENABLED` (default: off). In practice, the metadata fusion added complexity without measurably improving results. The reranker already captures most of what the metadata signals were trying to express. The entity density bonus, for example, rarely changed the top-5 ordering because high-entity-density chunks were already scoring well with the cross-encoder.

I kept the code and the configuration hooks. If I later find a failure mode that metadata can fix, I can turn it on. But for now, it's off.

---
## What I Tried and Dropped

**RRF (Reciprocal Rank Fusion).** My first hybrid search (`001_hybrid_search.sql`) used RRF — the standard approach from IR research. Each result gets a score of `1/(k + rank)` from each search method, and the scores are added. It works well when both search methods return comparable result sets. In my case, the full-text search often returned very few results (UPSC content doesn't always match keyword queries cleanly), which made the RRF scores unstable. I moved to the additive weighted formula, which handled uneven result sets better.

**English stemming.** I started with PostgreSQL's `english` text search config, which stems words. This caused over-matching: "fundamental" matched "fund", "amendment" matched "amend." For UPSC queries where the precise legal/constitutional term matters, stemming hurt precision. I switched to the `simple` config and precision improved.

**20-keyword extraction.** As I covered in the enrichment post, I used to extract 20 retrieval keywords per chunk. The BM25-side of hybrid search would match on these noisy keywords and surface irrelevant chunks. Cutting to 5 focused keywords (abbreviations, years, article numbers) cleaned up the sparse retrieval significantly.

---
## Confidence Score

Every RAG response includes a confidence score between 0.5 and 1.0. I compute it from the rerank scores of the selected chunks:

- Normalize the rerank scores of the top-n chunks to [0, 1]
- Average the normalized scores
- Map to the [0.5, 1.0] range: `confidence = 0.5 + 0.5 * normalized_avg`

The floor is 0.5 because if the system returned chunks at all, there's some signal. A confidence of 0.5 means the reranker wasn't very convinced. A confidence near 1.0 means the top chunks all scored high and close together — strong agreement on relevance.

I don't use the confidence to gate answers (yet). It goes into the response metadata so I can monitor retrieval quality over time and spot queries where the system is struggling.

---
## What Retrieval Changed

Before retrieval, I had 30,000 enriched chunks sitting in a database. After building the retrieval pipeline, I had a system that could take a UPSC question and surface the 5 most relevant chunks in under 2 seconds.

The layered approach matters:

- **Dense search** finds chunks that are semantically related to the query
- **Sparse search** catches exact terms that embeddings miss
- **Hybrid scoring** balances the two signals
- **Reranking** re-orders the candidates with a more powerful model
- **Quality gates** prevent low-value chunks from ever appearing

Each layer catches failures the previous one misses. That's the whole point.

---
## What's Still Open

Retrieval gets the right chunks to the LLM. But it doesn't control *how* the LLM uses them. A good retrieval result can still produce a bad answer if the prompt is wrong, the model hallucinates, or the answer format doesn't match the question type (prelims vs. mains).

The next post covers the LLM layer: prompting, the planner-writer-critic architecture, and how I handle the gap between retrieval quality and answer quality.

---

_Next: LLM Architecture (and how you turn 5 chunks into a UPSC answer)_
