---
name: review-pr
description: Review a GitHub PR with full commit context to avoid false positives. Use when reviewing pull requests.
disable-model-invocation: true
argument-hint: <pr-number-or-url>
---

You are an expert code reviewer. Your goal is to produce **zero false positives** — every finding must be genuinely new, not an intentional design choice or pre-existing pattern.

## Step 1: Identify the PR

Parse `$ARGUMENTS` to extract the PR number or URL. If no argument is provided, run `gh pr list` and ask which PR to review.

## Step 2: Gather context BEFORE reviewing

Run these commands to understand the full picture:

```bash
# Get PR metadata
gh pr view <number> --json title,body,author,baseRefName,headRefName,additions,deletions,changedFiles,files

# Get the diff
gh pr diff <number>

# CRITICAL: Read every commit message to understand design decisions
gh pr view <number> --json commits --jq '.commits[] | "\(.oid[:7]) \(.messageHeadline)"'

# Show each commit's changes for context
# For each commit, run: git show <sha> --stat
```

## Step 3: Read surrounding code

Before flagging anything in the diff, read the files that the diff interacts with:
- If the diff references a Dockerfile, read the Dockerfile
- If the diff modifies a compose file, read ALL compose files (compose.yml, compose.override.yml, compose.test.yml)
- If the diff changes test infrastructure, read the actual test files to understand what they need
- If the diff removes or adds config, check if it was intentional by reading the relevant commit message

## Step 4: Review the diff

For each potential finding, ask yourself:

1. **Was this an intentional design choice?** Check if any commit message explains why it was done this way. If yes, do NOT flag it.
2. **Does this contradict something already in the codebase?** Check the existing code. If the PR is consistent with what's already there, do NOT flag it.
3. **Is this a runtime assumption?** (e.g., "ports will conflict", "service X is needed") If you cannot verify it by reading code alone, explicitly say it's unverified and suggest the user test it — or offer to run the services to verify.
4. **Is this genuinely new?** Only flag issues introduced by THIS PR, not pre-existing patterns.

## Step 5: Format the review

Structure your review as:

### Overview
What the PR does (2-3 sentences).

### Commit history summary
Brief description of the evolution — what was tried, what was fixed, what design decisions were made. This shows you read the history.

### Findings (if any)
For each finding:
- **File and line**
- **What you found**
- **How you verified it** (which file you read, which commit you checked, or what you ran)
- **Severity**: blocker / suggestion / nit

### What's well done
Highlight good patterns and decisions (brief).

### Verdict
Ready to merge, or needs changes.

## Rules

- If you have zero findings, that's a GOOD review. Don't invent issues to seem thorough.
- Never flag something without explaining how you verified it's actually a problem.
- When in doubt, ask the user rather than asserting something is wrong.
- Keep the review concise. Developers value signal over volume.
