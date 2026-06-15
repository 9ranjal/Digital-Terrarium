---
layout: post
title: "My Experiments with Claw - #1"
date: 2026-05-08
tags: [AI, experiments, data]
categories: projects
description: "A personal knowledge pipeline built on OpenClaw — articles and YouTube videos into structured Obsidian notes via Telegram."
---


TL;DR: I set up a personal knowledge pipeline using Openclaw to automatically ingest articles and YouTube videos into structured Obsidian notes. Send a URL to Telegram, get a permanent note within 60 seconds. Built to close a specific gap: I was reading a lot, retaining very little, and manual note-taking had too much friction to survive contact with a busy day.
## 1. Inception

I'm quite late to the agents having only installed [OpenClaw](https://openclaw.ai) this week. Suspect timing given its recent [issues](https://openclaw.ai/blog/openclaw-rough-week) and with other tools like Hermes seemingly getting traction. Part of the reason is that while I've been getting more comfortable with Claude CoWork and working with CLI tools over the past few months, I've struggled to think of a use case for experimenting with OpenClaw.

Putting the cart before the proverbial horse, I thought to pull the trigger and play with the tool even if I don't have any targeted use for it right now. 

The setup is fairly straightforward: VPS on AWS Lightsail, a Telegram bot as the interface, with a model fed via OpenRouter. 

## 2. The Gap

### The Reading Problem

I've struggled with the loss of my reading habit over the last few years (like many others). My grouse used to be that I have lost my capacity to read but I think the truth is more nuanced: my reading habit didn't *die* but instead *shifted* in a way that feels less rewarding over time as a consequence of my reading becoming more ad-hoc with articles and disparate posts substituting my long-form reading habit. 

In net terms, I'm probably reading the same number of words in a day but the effect is markedly different:

- A book is far more immersive experience, you steep in it for an extended period, and once done there is a substantive feeling of having wrestled with something, and even if you forget a plot, you rarely forget how a book made you feel.
  
- Most things I read now leave no trace. A few do, but only because some memorable fragment remains in my mind and dulls over time before becoming part of the substrate of my thought; when the thought emerges again, it's poorly formed and vocalised.

For instance, I'm a decade removed from reading Of Human Bondage, but I am quite confident that I can still adequately summarise the themes and the protagonist's journey. I'll however struggle to form a coherent view on anything I've read over the last year on philosophy, the economy, or any other topic that's caught my interest.

### The Note-Taking Problem

Ideally, I'd like to marry both worlds but while I rediscover (again) my love for 'literature', the more pressing concern for me is in transforming my ad-hoc reading into a repeatable system that compounds over time.

You probably know where this is going: note-taking. As I chronicled in my post about [this Website](https://pranjal-singh.com/projects/2023/12/01/This-Website.html), I've been on the hunt for a format for record-keeping that respects the non-hierarchical and disparate nature of thoughts and emergent knowledge. I've landed on Obsidian for now, so the natural fix for my trouble would be to (i) log and summarise what I read; (ii) let it compound over time so that I can eventually leverage a framework like Karpathy's LLM Wiki.

The issue is that it's incredibly tiresome to keep a running note of everything you've read and manage its summarisation and filing (whether human or LLM-aided).

Or at least it was for me until I set up my OpenClaw.

## 3. The Setup

### The Pipeline

I built two ingest flows — one for articles, one for YouTube videos — and wired them to the agent via a routing rule.

When I send a URL with any save signal ("save this", "note this", "/save"), the agent:

1. Routes the URL to the appropriate Python script based on domain
2. The script fetches the content — article text via `trafilatura`, or YouTube transcript via a third-party API
3. Passes the content to an LLM with a structured prompt
4. Writes the output as a Markdown note to my Obsidian vault on the VPS
5. Pushes to GitHub, which Obsidian Git on my Mac pulls within 60 seconds

Total friction is now reduced to sending one Telegram message. The note appears in Obsidian in under a minute, without me having touched a computer.

### Note Structure

The goal was notes that are useful to someone who never read the original — not just a compressed version of the article, but something that extracts the reasoning, the frameworks, the transferable mental models. For YouTube videos with financial or analytical content, the prompt asks for specific numbers, tracking plans, bear/base/bull scenario bands. For articles, it adapts structure to content type: news gets a different template than an argument piece, which gets a different template than a research paper.

Each note has consistent frontmatter (source, date, category, tags), a TL;DR blockquote, a concepts section that defines every named term or acronym, and a body structured for the content type. The categories mirror the topics I actually care about: AI/LLM, VC/Startup, Product, Policy, and a few others.

The output is not perfect. LLMs miss things and occasionally confabulate. But it is substantially better than nothing, and the structured format means the notes are scannable and usable in ways that ad-hoc summaries are not.

This also fits neatly into the file-first philosophy I wrote about [when I set up this site](/projects/2023/12/01/This-Website.html). The notes are plain Markdown files in a folder. No proprietary format, no database, no lock-in.

## 4. Closing Note

The system has been running for some time and the vault is growing at a pace that would not have been sustainable manually. More importantly, the notes are actually there when I want to look something up — which is the whole point.

The deeper shift is not the tooling. It is that saving something no longer requires a mode change. I do not need to decide to take notes. I just send a URL when I encounter something worth keeping, and the rest happens automatically.

**PS:**
- I wonder how many Claws are called Jeeves. Need to settle on a good name for mine.
- The next step for this would be to build/leverage something like [LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). Karpathy's LLM Wiki idea is topic-centric as each topic has one page — when new content comes in on that topic, the LLM merges it into the existing page and the output converges toward a synthetic encyclopedia, not a pile of source notes. My current set-up is source-centric with each ingest creating one new dated note tied to one source. It'd be harder to constrain drift at scale with something like LLM Wiki, unlike my setup which is more reliable with the trade-off being that the same topic can generate 10 articles across 10 sources in my set-up.
