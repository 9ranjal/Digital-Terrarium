---
layout: post
title: "This Website"
date: 2023-12-01
tags: [FOSS, data]
categories: projects
---

**TL;DR:** A minimal, file-first website built from plain-text notes using Jekyll, reflecting a broader philosophy of owning data, avoiding proprietary lock-in, and optimising for long-term clarity, portability, and readability over tools or platforms. Incipient steps into the [Fediverse](https://en.wikipedia.org/wiki/Fediverse).

## 1. Notes – A Philosophy of Note Taking

### Legacy

I maintained my notes on OneNote for close to a decade. It served me well, but over time I ran into a few structural problems that became hard to ignore:

- **Organisation:** Notes were scattered across notebooks and sections. I hit a wall with hierarchical organisation. Over time, intelligence did not feel accretive—useful information was buried and often lost in the noise.
- **Search:** The search experience was inconsistent. The tagging and linking system did not lend itself to quick or precise retrieval.
- **Proprietary lock-in:** There was no reliable way to export my notes in a format I could reuse for other projects, especially AI/ML work. OneNote uses a proprietary format that is not easily parsed or future-proof.

### Alternatives

Once I accepted that my days with OneNote were numbered, I experimented with a few other tools:

- **Notion:** The UI/UX is excellent—Ryo Lu (Notion, Cursor, etc.) is a design genius. I was drawn to the block-based writing model. Ultimately, I never invested enough time to learn it deeply, and the idea of being beholden to another proprietary, subscription-based platform put me off.
- **Other editors:** I also experimented briefly with a few rich-text editors like Milkdown and TipTap. While promising, I found it difficult to rely on stable builds given they are largely community-supported. Big shoutout to the developers for their work nonetheless—these are sophisticated projects often run by very lean teams.

### Enter Obsidian

Obsidian is where things finally clicked. It stood out for a few reasons:
- It stores notes as plain text files written in Markdown
- It is file-first and local by default
- It has a plugin system that allows gradual extension without lock-in
- It has a strong and thoughtful user community

### File Over App

This site is built around plain text files—primarily Markdown (authored in Obsidian)—rather than a database-backed application.

This choice is deliberate:

- Files are readable without any special software
- Content survives even if the website or tooling disappears
- There is no platform lock-in or proprietary data model

The CEO of Obsidian captures this philosophy well:

> “The ancient temples of Egypt contain hieroglyphs that were chiseled in stone thousands of years ago. The ideas the hieroglyphs convey are more important than the type of chisel that was used to carve them.”  
> — Stephan Ango

If this site disappears tomorrow, the writing still exists. It can be rebuilt anywhere, at any time, from first principles.

### From Notes to Publishing

Once my notes lived as plain Markdown files on disk, publishing them became an obvious next step.

There was no longer a distinction between “notes” and “content”—both were just text files. The question shifted from *where* I write to *how* those same files could be rendered and shared.

I did not want a separate publishing system that required copying, reformatting, or syncing content out of Obsidian. That would have reintroduced the very abstractions and lock-in I was trying to escape.

What I wanted instead was a thin, mechanical layer that could:
- read Markdown files directly
- apply minimal structure and styling
- emit static HTML
- stay completely out of the way of writing

This is what led me to Jekyll.

---

## 2. How I Built This Site

This site is intentionally simple.

The core idea is straightforward: take a folder of text files and turn it into a website. There is no database, no live server logic, and nothing happening “behind the scenes” once the site is built.

I use a static site generator called **Jekyll** to do this.  
(See: https://jekyllrb.com/)

In practical terms:
- I write posts and pages as plain text files.
- A build step converts those files into regular HTML pages.
- The final site is just a collection of files that any web server can host.

There is no ongoing computation once the site is published.

### Why This Approach

I deliberately avoided:
- content management systems
- dashboards and admin panels
- client-side JavaScript frameworks
- anything that requires a database or runtime service

PS: Big shoutout to Mike at Giraffe Academy for excellent tutorials on Jekyll.

### Theme and Styling

The site uses Jekyll’s default theme, **Minima**, with light customisation.

The default theme provides:
- readable typography
- sensible spacing
- accessible defaults

I resisted the urge to redesign it. All changes are incremental:
- small typography and spacing tweaks
- minimal layout overrides
- restrained header and footer design

The goal was not to “design a site” but to get out of the way of reading.

### Filesystem as Structure

The site mirrors the filesystem directly:

- Posts are dated text files in a folder
- Pages are standalone text files
- URLs map directly to file paths

There is no abstraction layer between content and output. If you understand the directory tree, you understand the site.

This also makes the site portable. It can be rebuilt elsewhere—or with a different tool entirely—without changing the underlying writing.

### Tooling

The entire toolchain is small:
- Ruby (the language Jekyll is written in)
- Jekyll
- a basic stylesheet system for design tweaks

There are no runtime dependencies and no client-side build steps. If something fails, the failure is usually obvious and local.

---

## 3. Content Architecture

- **Posts:** Dated Markdown files for time-bound writing
- **Pages:** Standalone Markdown files for durable content
- **Layouts:** Minimal templates for structure and reuse

The structure mirrors how the files are stored. There is no hidden content model.

---

## 4. Closing Note

The goal was to put my notes online in a way that I own and control. This remains an ongoing journey.

PS:
- The more you learn, the less you know.
- Since writing this, I’ve been exposed to the rabbit hole of note-taking systems (Zettelkasten, PARA, etc.), other WYSIWYG editors (Bear, Joplin), and decentralised systems of record and social media (Fosstodon, the Fediverse).
- Will keep at it to learn more.
