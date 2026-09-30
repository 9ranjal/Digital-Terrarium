---
layout: post
title: "Preparing your Data"
date: 2025-09-01
tags: [AI, RAG, LLMs, data, Aanae]
---

**TL;DR:** Before you can do RAG, you need your knowledge in a format machines can read. My notes lived in OneNote and PDFs—locked in, unstructured. I got everything out (export → HTML → Markdown), cleaned and normalized it, and ended up with plain-text Markdown and spreadsheets that the rest of the pipeline could actually use.

For links to all the posts in this series, see [Aanae](/projects/2025/08/26/Aanae.html).

---

Before you can build anything intelligent with AI, you need to answer a simple question: **Where is your knowledge, and what format is it in?**

For me, the answer was: OneNote.

---
## Why OneNote Became a Problem

OneNote is great for taking notes, but it fails when you try to do anything else with them.

Here's what went wrong:

- Notes pile up in random places. Notebooks, sections, pages—it sounds organized, but everything becomes a mess.
- Notes don't connect. They just sit there, isolated from each other.
- Search only finds words, not the ideas behind them.
- Your data is stuck. OneNote stores everything in its own format that other tools can't read.

***Most importantly***: OneNote won't let you extract your knowledge as plain text that a computer program can work with. 

If you want to use AI with your notes, this is a dealbreaker.

PDFs have the same problem. PDFs are designed to look good on a page, not to be read by software. Paragraphs aren't clearly marked. Tables and sidebars run together. AI models can't make sense of pages and fonts—they need plain text with clear structure.

My notes were easy for me to read, but impossible for a computer to process. That difference shaped everything I did next.

---
## Step 1: Getting the Data Out

First task: get all my notes out of OneNote and into a format I could actually work with.

I tried several methods:

- OneNote's built-in export
- Converting to HTML first
- Third-party conversion tools

None of them worked cleanly. The exports were always messy—weird formatting, broken lists, inconsistent headings.

What eventually worked:

**OneNote → export as text → convert to Markdown**

Why Markdown? 

Markdown is the 'native language' of most LLMs. When you give an AI a PDF, it has to guess where a header ends. When you give it Markdown, the `#` and `##` symbols act like signposts. It tells the AI: _'This is important, pay attention here.'_ It saves the AI from having to guess your structure so it can focus on your content

This wasn't automatic. I had to fix things manually, try different approaches, and accept that the first attempt would be ugly.

---

## Step 2: Cleaning the Mess

The exported files were still a mess:

- Lines broke in weird places
- The same header appeared over and over
- Leftover formatting junk from OneNote
- Tables that weren't actually tables
- Lists that lost their meaning

Before trying anything with AI, I had to clean this up. I wrote small scripts and went through files manually to:

- Fix the headings
- Remove the junk
- Make sure each file was about one clear topic
- Make the text readable as text, not just pretty on screen

This is boring work. But if you skip it, everything else fails. Bad data doesn't magically become good data later.

I kept making it a little bit better each time with each pass.

---

## Step 3: Naming Files Properly

Unexpected problem: what should I name each file?

This turned out to matter a lot. I used a system like this:

`ECONOMY_NCERT_XI_Macroenomics.md`

Each filename told me:

- Subject (ECONOMY)
- Source (NCERT textbook)
- Level (Class XI or XII)
- Topic

Why this helped:

- I could understand what was in a file without opening it
- Computer programs could figure out context from just the filename
- When the AI searched for information, it was less likely to get confused
- I could quickly see what topics I had and what was missing

File names became a cheap way to add information without having to read the whole file.

---
## Step 4: Dealing with Spreadsheets

Some of my material (statistics, data tables, summaries) was in Excel, not OneNote.

Excel creates different problems:

- Rows aren't the same as paragraphs
- Column headers explain what the data means, but that context gets lost
- Related information is often spread across multiple rows

I had to decide:

- When does one row become its own piece of information?
- When do multiple rows need to stay together?
- How do I keep the column headers connected to the data?
- How do I avoid creating facts that are missing important context?

This taught me something important: preparing data means making your assumptions clear.

Every rule I made was really just an assumption about how things should work. I wrote the rules down, tested them, and changed them when they didn't work.

---
## Step 5: Making Everything Work Together

At this point, my notes were:

- Out of OneNote
- Saved as plain text
- Organized consistently
- Readable without any special software

Only then were they ready to use.

## What Changed

By the end of this phase, my notes weren't just things I had written. They became: inspectable (I could see exactly what was in them), checkable (I could verify the quality), scriptable (programs could work with them), and independent (not locked to any one tool).

Only after this did it make sense to think about the next steps: breaking notes into chunks, adding context, building search systems. Those things only work if the underlying data is solid.

Getting the data ready was when this stopped being a collection of notes and started becoming a system.

---

_Next: Chunking (and why the structure of your chunks matters more than their size)_