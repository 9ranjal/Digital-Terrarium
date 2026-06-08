---
layout: post
title: "Babel - Continued"
date: 2026-06-08
tags: [Babel, Legaltech]
categories: projects
exclude_recent: true
---

Babel started from one bet: *structure, not scale, makes machine reasoning reliable.* The work lived in decomposition — turning tasks into graphs of typed entities — and in orchestration frameworks like LangGraph, where the model is invoked at defined points in a flow rather than left to improvise.

This post continues that thread one layer down, into the **harness** — the runtime an agent actually runs on.

## Harnesses for agents

Today's harnesses (OpenClaw, Hermes) solved the plumbing: multi-channel transport, tool dispatch, memory, sub-agents. But they kept two chatbot-era assumptions — the **LLM is in charge**, and the **conversation is the state**. That makes them great personal assistants and poor substrates for work that has to be correct over time. My own OpenClaw experiments confirmed the ceiling: a stateless ingest pipeline is delightful precisely because nothing is at stake.

The next move is a **control inversion**: demote the LLM from *the system* to a *bounded component* of one, and push state and verification above it. Reliability stops being a prompt problem and becomes an architectural property.

## A harness for legal tasks

Legal work is the sharpest test, because being wrong has consequences. A harness for it would hold four disciplines the generic ones don't:

- **State** in a typed, persistent store — not the context window.
- **Verification** as an un-skippable gate in the control flow — work-product (citations, drafts, filings) can't be emitted without passing it.
- **Durability** — deadlines and reminders as a background engine reacting to events and the calendar.
- **Two speeds** — a fluid conversational lane for the "aha moment," a slow gated lane where trust is earned.

## Use case: LitigationOS

LitigationOS applies this to an Indian litigating lawyer. It's a WhatsApp-native assistant that treats a **matter**, not a message, as the unit of state: forward an order, and it extracts the next date, derives the reply deadline, and sets a reminder — then, asked "what's tomorrow?", answers across all fifty matters at once. The point isn't that it replies; it's that it *knew what was at risk before being asked* — which is only possible on a structured spine.
