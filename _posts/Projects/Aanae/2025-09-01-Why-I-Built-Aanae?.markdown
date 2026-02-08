---
layout: post
title: "Why I Built Aanae?"
date: 2025-09-01
tags: [AI, RAG, LLMs, data, Aanae]
---

**TL;DR**  
I read widely and made copious notes. I then started experimenting with LLMs and retrieval-augmented generation (RAG) using those notes. I realised there was a strong overlap with the way UPSC/PSC preparation works. I eventually tooled this RAG pipeline into a chatbot experience for aspirants (covered in the other posts in this series).

---
## The Starting Point

I joined Sequoia Capital in 2021. As part of the onboarding kit, I was given *Measure What Matters* by John Doerr. That book introduced me to goal-setting through OKRs (Objectives and Key Results).

One of my OKRs from that year looked like this:

![OKR Example](/assets/images/projects/aanae/okr-example.png)

Around this time, I realised I had slowly lost touch with my reading habit. I also felt a persistent urge to revisit my schoolbooks. Somehow, the curiosity that had been exorcised from my system through the vagaries of cramming and periodised testing came alive again.

I wanted to read:
- History  
- Geography  
- Polity  
- The sciences  

Anything that would help me understand the world better.

*Side note:* I had always assumed that you sharpen your understanding of the world as you grow older. My experience proved otherwise.

---
## Early Attempts 

I made well-laid plans:
- Organised my reading material
- Created an Excel sheet to track progress
- Calculated **Weekly Estimated Time (WET)** to complete the NCERT syllabus in a year
- Tried to balance this with work, life, and new interests (this was also when I discovered endurance sports and ultracycling)

I failed.

The Excel sheet gathered digital dust as work and life took over. I made incremental attempts to read more—with some success—but nothing felt structured or sustainable.

---
## The 2025 Pivot

By 2025, during my last year at Sequoia, my interests began trending in a different direction.

Over the preceding three years, I had lived through what felt like epochal events:
- ZIRP
- The crypto boom
- The advent of GenAI

I increasingly felt the need to slow down and just… study and learn.

The overarching goal was to understand:
- Data analysis  
- Systems architecture  
- AI and LLMs  

But I needed a gentler on-ramp. Something that would both rekindle the habit of studying and rebuild my ability to sit and focus. 

I chose to start with **NCERT books**.

---
## The Study Phase

- By **March 2025**, I had completed the entire NCERT syllabus.
- I then branched out to:
  - NIOS (*National Institute of Open Schooling*)
  - IGNOU (*Indira Gandhi National Open University*)
- By **May 2025**, my urge to “study” had been largely sated.

More importantly, I now had **copious notes** across geography, history, polity, and science.

---

## Detour: My Note-Taking Process
Taking notes was non-negotiable.

I knew I wouldn’t retain information beyond the event horizon of my memory. I needed a system that allowed me to revisit and refresh any granular topic quickly.

My evolution looked like this:

- **Handwritten notes**
  - Too slow
  - Scaled poorly over long texts
  - My handwriting and note density were not conducive to quick comprehension


- **Typed notes**
  - Better structure
  - Still slow

Eventually, I decided to **augment my note-taking with ChatGPT**.

### Final Workflow
- Use PDFs of books
- Read an excerpt or chapter
- Feed that text to the LLM
- Prompt for structure, clarity, and coverage
- Edit the output
- Save with appropriate taxonomy in OneNote  
  *(This last choice turned out to be a mistake, as discussed later.)*

---
## Where I Ended Up

By the end of this phase:

- I had (for now) satisfied my desire to study the foundational subjects that explain the world.
- I had accumulated **~250 MB of typed notes**, amounting to roughly **250,000 pages**.

I began to think of these notes explicitly as my **second brain**.

---
## The Aha Moment

The turning point came when I realised:

> I could feed my notes into an LLM, use it as a daily driver for curiosity and queries, and let it paper over the cracks of my memory and recall—subject, of course, to how well I handled hallucinations.

That realisation was the seed from which **Aanae** grew.