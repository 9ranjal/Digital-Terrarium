---
layout: post
title: "Enrichment"
date: 2025-09-15
tags: [AI, RAG, LLMs, data, Aanae]
---

TL;DR: 
- The chunking post ended with a problem: chunks can be correctly scoped but still not self-contained. A chunk might say "the Act" without naming which act. It might carry a date without the event. It might contain "GDP" and "42%" with no indication of which country or year.

- I went from brittle regex hacks and overstuffed metadata to a focused enrichment pipeline that turns raw chunks into self-contained, searchable records with the right entities, concepts, and scores, so retrieval actually works on 30,000+ pieces of text.

For links to all the posts in this series, see [Aanae](/projects/2025/08/26/Aanae.html).

---
## What the First Chunks Were Missing

After getting to ~30k chunks with clean boundaries, I started testing retrieval. The failure pattern was consistent. I'd ask "What are Directive Principles?" and the retrieval would surface a chunk that said:

> "These principles, though not enforceable in court, are fundamental in governance."

Same story, over and over:

- **Headings vanished.** Correct chunk, good boundary — but the text never said "Directive Principles of State Policy" or "Part IV of the Constitution." It assumed the reader had just read the heading. In retrieval, that heading was gone.
- **Entities were invisible to filters.** A chunk about the Green Revolution would mention "Norman Borlaug" but not tag him as a PERSON entity, so entity-based filtering missed it.
- **Abbreviations broke matching.** A chunk about banking reform would say "RBI" and never expand it to "Reserve Bank of India," so a query using the full name wouldn't match.

These were enrichment problems, not chunking problems. The chunk was the right unit. It just didn't carry enough metadata to be found and understood in isolation.

---
## The Enrichment Pipeline

Enrichment runs after chunking and before embedding. It takes each chunk and adds layers of metadata that the retrieval and generation stages can use. 

The pipeline evolved across a few key commits:

- **July 5 (`c304294`)** – initial enrichment logic in `enhancer.py` inside the monolith.
- **July 28 (`8aea7a6`)** – major rewrite when I split things into a modular core.
- **July 30 (`d41bf1d`)** – `concept_analyzer.py`, `context_tagger.py`, and `domain_classifier.py` were added as separate modules (368, 373, and 237 lines).
- **Aug 20 (`c0c87d6`)** – glossary linker, unified omit logic, and the RAG metadata module.

The `batch_enrich_chunks()` function in `enhancer.py` is the main entry point. It processes chunks in batches. The pipeline goes roughly:

1. Pre-normalization (clean text one more time before NLP)
2. spaCy NER (entity extraction)
3. Entity density calculation
4. Quality re-assessment based on entities
5. Enhanced metadata extraction (domain, concepts, retrieval keywords, primary entities)
6. Semantic type classification
7. Context tag generation
8. Retrieval score calculation
9. Unified omit logic (post-enrichment)
10. Embedding generation
11. Hash generation for deduplication

Each step adds fields to the chunk's nested schema. By the end, a chunk that entered as plain text with basic source metadata leaves with entities, concept tags, context tags, domain tags, a semantic type, a retrieval score, quality flags, and a 1024-dimensional embedding vector.

---
## Entity Extraction

This was the first enrichment I added and the one that mattered most for retrieval quality.

Each chunk's text gets processed by spaCy's `en_core_web_trf` model. The model extracts named entities and labels them:

- PERSON
- ORG
- GPE (countries/states/cities)
- DATE
- MONEY
- PERCENT
- LAW
- EVENT
- LOC, CARDINAL, NORP, FAC, and a few others

The entities get stored in a nested `entities` dictionary on each chunk, organized by type: `person_entities`, `org_entities`, `gpe_entities`, `date_entities`, `money_entities`, `percent_entities`, `law_entities`, `event_entities`.

On top of that baseline, I layered three bits of logic:

- **Regex experiment (and rollback).** I first tried extracting organizations with regex (any capitalized multi-word phrase). The output was full of junk: "Stars", "Larger", "Some", "Millions." I commented that pattern out and left a note in the code so I wouldn't bring it back. I now rely on spaCy's NER for anything beyond abbreviations and dates, and use regex only for what the model misses: article numbers, section references, abbreviations like GDP or SEZ.
- **Primary entities.** There's a `primary_entities` extraction step that picks the top 5 named entities (PERSON, ORG, GPE) from each chunk after filtering: skip entities longer than 4 words (likely a phrase, not a name), skip lowercase single words, skip anything with digits, skip generic terms like "growth" or "development." These primary entities feed into the retrieval metadata and help the system answer queries like "Who was involved in X?" without relying solely on embedding similarity.
- **Entity density.** Entity density is a simple ratio: count of (person + org + GPE + date + law) entities divided by word count. I use it for quality assessment. A short chunk with zero entity density is usually noise. One with high entity density (e.g. "Article 370 was abrogated in 2019 by the BJP government") is often valuable despite being brief. So in the pipeline I use entity density to promote short chunks that would otherwise be flagged as fragments: if a chunk is under 50 words but density is above 0.01, I upgrade its quality to "ok" and leave `omit_flag` false.

---
## Concept Tags and Domain Classification

Entity extraction tells you *who* and *what* and *when* are in a chunk. Concept tags and domain classification tell you *what subject area* and *what ideas* the chunk belongs to.

The `ConceptAnalyzer` uses a hierarchical UPSC concept taxonomy: `polity.constitutional`, `polity.governance`, `economy.macroeconomic`, `economy.sectors`, `environment.conservation`, `geography.physical`, `history.ancient`, and so on. Each category has a set of keyword triggers. The analyzer checks the chunk text against all categories and returns the matching concept tags. These tags go into `retrieval_metadata.concept_tags`.

I built the concept taxonomy by hand from the UPSC syllabus. That's what makes it specific to the domain rather than a generic NLP pipeline. A chunk about "Ramsar wetlands" gets `environment.conservation`. A chunk about "fiscal deficit" gets `economy.macroeconomic`. Without these, the retrieval layer would rely entirely on embedding similarity, which works for most queries but fails on structured queries like "list all conservation-related topics."

The `DomainClassifier` works at a higher level: it assigns one or more domain labels (Polity, Economy, Environment, Geography, History, Science, International Relations) based on keyword scoring, entity types, and direct topic-to-domain mapping from the chunk's own metadata. A chunk with `topic = "POLITY"` automatically gets the Polity domain. One with "constitution" and "amendment" in the text gets it through keyword matching. These domain tags help filter results when the query has an obvious subject focus.

---
## Context Tags

Context tags capture the *role* a chunk plays in an explanation. The `context_tagger.py` module scans each chunk's text for patterns and assigns tags like:

- **cause** (text contains "causes of", "due to", "as a result")
- **example** (text contains "for example", "such as", "including")
- **comparison** (text contains "difference between", "compared to", "versus")
- **statistical** (text contains "%", "GDP", "growth rate", "survey")
- **timeline** (text contains "chronology", "sequence", "first... second... third")
- **scheme** (text contains "scheme", "policy", "program", "ministry of")
- **definition** (text contains "defined as", "refers to", "is known as")
- **constitutional** (text contains "article", "fundamental right", "amendment")
- **geographic** (text contains "river", "mountain", "located in", "capital of")

These tags go into `retrieval_metadata.context_tags`. They're useful at retrieval time because they let the system distinguish between a chunk that *defines* a concept and one that *gives an example of* it. A query asking "What is X?" should prefer chunks tagged as `definition`. A query asking "Why did X happen?" should prefer chunks tagged as `cause`.

---
## Retrieval Score

Every chunk gets a composite retrieval score between 0.0 and 1.0. The score is calculated in `scoring.py` and combines:

- **Word count fitness.** Markdown chunks score highest at 100-300 words (the sweet spot for retrieval). Excel chunks score highest at 10-100 words.
- **Entity density.** Chunks with moderate entity density (not too sparse, not overwhelmed with names) score higher.
- **Semantic type bonus.** If the chunk's semantic type is one of the "high-value" types (definition, factual, constitutional_principle, and ~80 others built from the UPSC syllabus), it gets a 0.2 boost.
- **Richness score.** Multi-sentence chunks with verbs and multiple entity types score higher. Pure comma-separated lists without verbs get penalized (an Excel-specific check).
- **Quality bonus.** Chunks that passed all quality checks and have >=2 concept tags get a small bump.

I use the score to decide whether a chunk survives the final gate. I omit Markdown chunks below 0.3 and Excel chunks below 0.2. But I added "protected" semantic types that never get omitted regardless of score: `constitutional_principle`, `definition`, `factual`, `fundamental_rights`, `judicial_review`, and the rest of the 80+ UPSC-specific types. I added those protections after noticing that short, factual chunks about constitutional provisions were getting low retrieval scores because they were brief, even though they were exactly the kind of chunk I wanted to retrieve.

---
## Retrieval Keywords

Embeddings handle semantic similarity well. But they can miss exact-match terms that matter for UPSC queries: abbreviations (GDP, SEZ, UPSC), constitutional article numbers (Article 370), legal section numbers (Section 144), and specific years (1991, 2019).

The keyword extractor runs after entity extraction and pulls up to 5 critical terms per chunk: abbreviations (all-caps, 2-5 characters), years (4-digit numbers), act names ("Sarfaesi Act"), article references ("Article 370"), and section references ("Section 144"). These keywords go into `retrieval_metadata.retrieval_keywords` and support hybrid search (embedding similarity + BM25 keyword matching).

I used to extract 20 keywords per chunk (proper nouns, technical terms, heading words, topic hierarchy). That was too many; retrieval got noisy. I cut it back to 5 and left a comment in the code: focus only on exact-match terms that embeddings might miss (abbreviations, article numbers, years). Embeddings handle the rest.

---
## Embeddings

I embed each chunk's final text with `BAAI/bge-large-en-v1.5` (1024 dimensions, `sentence-transformers`). I prefix the text with "Represent this passage for retrieval:" before encoding; BGE models need that for asymmetric retrieval. I L2-normalize the vectors.

I run the embedding step in batch after all other enrichment. That order matters: by then the text has been normalized, cleaned, and sometimes rewritten (Excel list chunks). So the embedding is for the final version of the chunk, not the raw input.

Each embedding is stored as a dictionary with the vector, model name, dimension, norm, and a timestamp. This metadata was useful when I later upgraded from a 384-dimensional model to the 1024-dimensional BGE model, because old chunks could be identified by their `dimension` field and re-embedded.

---
## The Unified Omit Logic

The last step before embedding is the unified omit logic. This is where I decide, after all enrichment, whether a chunk actually gets kept.

Inside `batch_enrich_chunks()` I run checks like:

- Is the chunk context-dead *and* under 15 words? Omit.
- Is the quality score below 0.4? Omit.
- Is the confidence below 0.4 *and* the sentence incomplete? Omit.
- Is it under 30 words with low retrieval score, low entity density, and not fact-like? Omit.

I added overrides: if the chunk has retrieval score above 0.4, or LAW entities, or an article number, or a policy with a year, I keep it regardless. I added those because I kept finding chunks about specific articles or schemes getting thrown out by the word-count and density rules.

Context-dead chunks over 25 words I flag for review but don't omit. A chunk that starts with "as discussed above" but runs for 50 words might still have useful content after the opening. The flag lets me review them in the QA CSV instead of auto-discarding.

---
## What Enrichment Changed

Before enrichment, the chunks were text with source labels. After enrichment, each chunk is a structured record with entities, domain context, concept tags, a retrieval score, quality signals, and an embedding. The system can now answer "who" questions (entity lookup), "what domain" questions (domain classifier), "what kind of explanation" questions (context tags), and score candidates for relevance before the LLM ever sees them.

The enrichment pipeline is also where most chunks get their final omit decision. Chunking flags fragments and context-dead starters. Enrichment adds entity-based evidence and either confirms the flag or overrides it. About 15-20% of chunks that survive chunking get omitted during enrichment. And some that were flagged as fragments during chunking get promoted back because enrichment finds they carry high-value entities.

---
## What I Tried and Disabled

Two things I built and then turned off.

**Glossary injection.** I wrote `glossary_linker.py` (216 lines) to map chunk text to glossary terms and inject definitions inline. The idea was: if a chunk says "NABARD", inject "NABARD (National Bank for Agriculture and Rural Development)" so it's self-contained. In practice it bloated chunks and hurt embedding quality. I disabled it and left a comment in `base_post_processor.py`. I moved to query-time glossary lookup instead.

**Boolean entity flags.** I used to add flat booleans like `ner_PERSON = True` at the root of each chunk. They polluted the schema and duplicated the nested entity lists. I commented that code out and now rely only on the nested entity lists and counts.

Both removals made the pipeline simpler and the chunks cleaner. Not every idea survives contact with real data.

---
## What's Still Open

Enrichment makes chunks self-contained. But it doesn't decide *how to find them*. The retrieval score is a heuristic, not a learned signal. The concept tags are keyword-based, not semantic. The embedding model was chosen, not trained on UPSC data.

The next post covers retrieval: how the system actually searches, ranks, and combines chunks when a user asks a question.

---

_Next: Retrieval (and how you search 30,000 chunks when precision matters)_
