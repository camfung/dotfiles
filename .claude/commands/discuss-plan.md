---
name: discuss-plan
description: Read an existing plan file, identify design decisions that need clarification, and have an interactive discussion to nail down the details. Outputs a versioned decisions file.
argument-hint: "<path-to-plan-file>"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---

<objective>
Read the user's plan file, identify ambiguities and design decisions that need nailing down, then have a focused interactive discussion. Capture all decisions in a versioned `decisions-v<N>.md` file next to the plan.

This happens AFTER the plan is written — the plan exists, but the details need sharpening.
</objective>

<process>

<step name="validate_input" priority="first">
The plan file path comes from $ARGUMENTS (required).

If no argument provided:
```
Usage: /discuss-plan <path-to-plan-file>

Provide the path to your plan file.
```
Exit.

Read the plan file. If it doesn't exist, tell the user and exit.
</step>

<step name="check_prior_decisions">
Look for existing `decisions-v*.md` files in the same directory as the plan file.

```bash
ls "$(dirname "$PLAN_FILE")"/decisions-v*.md 2>/dev/null
```

**If prior decisions exist:**
- Read the latest version to understand what's already been decided
- Track these decisions so you don't re-ask them
- The new file will increment the version number (e.g., if `decisions-v2.md` exists, next is `decisions-v3.md`)

**If no prior decisions:**
- Version will be 1
</step>

<step name="analyze_plan">
Read the plan file thoroughly and identify design decisions that need clarification.

**How to identify gray areas:**

1. Read the full plan — understand what's being built
2. Determine the domain:
   - Something users SEE — visual presentation, interactions, states matter
   - Something users CALL — interface contracts, responses, errors matter
   - Something users RUN — invocation, output, behavior modes matter
   - Something users READ — structure, tone, depth, flow matter
   - Something being ORGANIZED — criteria, grouping, handling exceptions matter
3. Generate specific gray areas for THIS plan — not generic categories, but concrete decisions

**Skip anything already decided** in the plan itself or in prior decision files.

**Don't ask about:**
- Technical implementation details (you figure those out)
- Architecture patterns
- Performance optimization
- Things the plan already specifies clearly

**Do ask about:**
- How the user imagines it working
- What it should look/feel like
- What's essential vs nice-to-have
- Ambiguous behaviors that could go multiple ways
- Edge cases where the plan is silent
</step>

<step name="present_gray_areas">
Present what you found to the user.

**First, state what you understand:**
```
Plan: [plan title/summary]

I've identified a few areas where the details could go different ways.
```

**Then use AskUserQuestion (multiSelect: true):**
- header: "Discuss"
- question: "Which areas do you want to nail down?"
- options: 3-4 specific gray areas, each with:
  - label: concrete area name (not generic)
  - description: 1-2 questions this covers

Do NOT include a "skip" or "you decide" option. The user ran this command to discuss.

Continue to discuss_areas with selected areas.
</step>

<step name="discuss_areas">
For each selected area, conduct a focused discussion.

**For each area:**

1. **Announce:** "Let's talk about [Area]."

2. **Ask up to 4 questions using AskUserQuestion:**
   - header: "[Area]" (max 12 chars — abbreviate if needed)
   - question: Specific decision for this area
   - options: 2-3 concrete choices, with the recommended choice first and marked "(Recommended)"
   - Include "You decide" as an option when reasonable — captures that you have flexibility

3. **After 4 questions, check:**
   - header: "[Area]"
   - question: "More on [area], or move on?"
   - options: "More questions" / "Next area"

   If "More questions" — ask up to 4 more, then check again
   If "Next area" — proceed to next selected area
   If "Other" (free text) — continuation phrases ("more", "keep going", "yes") mean more questions; advancement phrases ("done", "next", "skip") mean next area

4. **After all selected areas are done:**
   - Summarize what was captured
   - AskUserQuestion:
     - header: "Done"
     - question: "We've covered [list areas]. Anything else unclear?"
     - options: "Explore more areas" / "Write it up"
   - If "Explore more areas": identify 2-4 new gray areas based on what you learned, return to present_gray_areas logic
   - If "Write it up": proceed to write_decisions

**Question design:**
- Options should be concrete ("Cards" not "Option A")
- Each answer should inform the next question
- If user picks "Other", reflect their input back and confirm you understood

**Scope handling:**
If the user suggests something outside what the plan covers:
```
That sounds like it's beyond what this plan covers — worth noting for later though.

Back to [current area]: [return to current question]
```
Track these as deferred ideas.
</step>

<step name="write_decisions">
Create `decisions-v<N>.md` in the same directory as the plan file.

**Structure:**

```markdown
# Decisions — v<N>

**Plan:** [plan filename]
**Date:** [today's date]

## Summary

[2-3 sentence summary of what was discussed and decided]

## Decisions

### [Area 1 that was discussed]
- [Specific decision made]
- [Another decision if applicable]

### [Area 2 that was discussed]
- [Specific decision made]

### [Area N]
- [Specific decision made]

### Your Discretion
[Areas where user said "you decide" — flexibility is noted here]

## Specific Ideas

[Any references, examples, or "I want it like X" moments from discussion]

[If none: "No specific references given — open to standard approaches"]

## Deferred Ideas

[Ideas that came up but are beyond the plan's scope. Captured so they're not lost.]

[If none: "None — discussion stayed within plan scope"]

---

*Decisions for: [plan filename]*
*Version: <N>*
*Date: [today's date]*
```

Write the file. Tell the user where it was created and summarize the key decisions.
</step>

</process>

<guidelines>
**Good decisions (concrete):**
- "Card-based layout, not timeline"
- "Retry 3 times on network failure, then fail"
- "JSON for programmatic use, table for humans"

**Bad decisions (too vague):**
- "Should feel modern and clean"
- "Good user experience"
- "Fast and responsive"

Capture decisions clear enough that someone implementing the plan could act on them without asking again.
</guidelines>
