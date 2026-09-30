---
layout: post
title: "Hanging Man Problem"
date: 2026-03-01
tags: [philosophy]
categories: writing
subcategory: 101-philosophy-problems
---

## Problem Synopsis

A condemned prisoner is offered a final bargain by a judge: make one true statement before execution. If the statement is true, his death sentence is commuted to life imprisonment; if false, he’s executed immediately. On the eve of the execution, the prisoner utters a statement and is allowed to go free altogether. What does he say? 

The long-form problem is [here](https://philosophy.stackexchange.com/questions/46715/the-hanging-judge).

---
## My Initial Read / Thoughts

My instinct is that the statement cannot be declarative about the self (where you can introduce doubt via thought experiments such as [Brain in a Vat](https://en.wikipedia.org/wiki/Brain_in_a_vat)) or the world at large (where you can introduce doubt via Russell-style skepticism on there being no uniform perception of external stimuli/sense-data).

It must therefore deal with a system of thought, i.e. logic, and be related to the system of rules set forth by the judge. The following must occur:

- The prisoner utters a single statement.  
- The statement must be capable of being proved as true **or** false.  
- If false, he is executed immediately.  
- If true, his sentence is commuted and the prisoner is sent to jail.  

Crucially, the prisoner utters a statement that seems to sit outside the judge's rubric. We can infer this from him being allowed to go free altogether, i.e. neither executed (lie-state) nor imprisoned (true-state).

It follows then that the prisoner utters a statement that's neither a truth nor a lie. True/lie is a binary option — for something to be neither (or both) within the same fact pattern, the statement ought to be a paradox.

> **Note**:  
> At this point, I started reading up on paradoxes and came across the [Liar Paradox](https://en.wikipedia.org/wiki/Liar_paradox). This effectively solved the problem and cut short my inquiry (leaving me dissatisfied). It is now my resolve not to research/read up on a problem before I am satisfied with my application of mind.

*The solution and my further reading on the Liar’s Paradox follow.*

---
## Solution / What the Author Says

The prisoner says:

> "I will be executed."

This problem deals with *self-reference* in logic and is a restatement of the Cretan Liar paradox (also known as the Epimenides paradox), arising from the 6th-century BC statement by the Cretan philosopher Epimenides that:

> "All Cretans are liars."

---
## Case Analysis

### Case 1: Assume the statement is true

If "I will be executed" is true, then the prisoner's sentence ought to be commuted to imprisonment. In that case, the sentence is no longer true — leading to a contradiction.
### Case 2: Assume the statement is false

If "I will be executed" is false, then the prisoner ought to be executed immediately. In that case, the statement is no longer false — also leading to a contradiction.

The loop, as expressed by the author:

> "The truth of the claim affects the circumstances in which it is uttered, which affects the truth of the claim which etc.."

---
## What This Taught Me

### Notation in Logic

#### Propositional Variables

A **propositional variable** is a symbolic shorthand for a declarative statement that can be either true or false.

For instance, in this puzzle:

> E = "I will be executed."  
> ¬E = "I will not be executed."

Here:

- `E` represents the original statement.  
- `¬` (negation) means “not.”  
- So `¬E` is simply the denial of `E`.

---
#### If-Statements (Implication)

The arrow

> **→**

means “if … then …” and represents logical implication.

For example:

> E → ¬E

means:

> If E is true, then ¬E must follow.

In words:

> If "I will be executed" is true, then "I will not be executed" must occur.

Similarly:

> ¬E → E

means:

> If E is false (i.e., I will not be executed), then I will be executed.

---
#### Biconditional (If and Only If)

The double arrow

> **↔**

means “if and only if” and represents a biconditional relationship.

For example:

> E ↔ ¬E

means:

> E is true if and only if ¬E is true.

This is logically impossible in classical two-valued logic, because a statement cannot be both true and not true simultaneously.

---
#### Summary of the Structure in This Puzzle

The judge’s rule effectively forces:

> E → ¬E  
> ¬E → E  

Which collapses into:

> E ↔ ¬E  

This creates a contradiction — there is no stable truth value that satisfies both conditions.

### Closing Note

The Liar Paradox is a wormhole.

A non-exhaustive list of proposed approaches on Wiki includes:
- **Fuzzy logic**, where truth is not strictly boolean, but can take values between 0 and 1. 
- **Philosophy of language**, focusing on semantic limitations or structural constraints within certain languages.  
- **Temporal contextualisation**, as discussed by the Indian philosopher **Bhartrhari** — where truth may depend on temporal framing.  
- **Gödel’s incompleteness theorems** — which...I can't even begin to understand.

It is beyond my current skill to delve meaningfully into each of these.

I could conceivably spend the rest of the year — if not my life — attempting to wrap my head around these problems. But that would depart from my original mission: to use *[101 Philosophy Problems](https://www.amazon.in/101-Philosophy-Problems-Martin-Cohen/dp/0415635748)* as a springboard for launching my own education in philosophy and thinking more deeply on my own.

This is something I would like to perhaps revisit in the future, both to refine my understanding and to test whether my capacity for thinking has evolved. Cheers.