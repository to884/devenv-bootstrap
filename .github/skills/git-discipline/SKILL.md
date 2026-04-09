---
name: git-discipline
description: >
  Enforce consistent Git discipline across branches, commits, and pull requests.
  Use this skill when creating branches, writing commit messages, preparing pull
  requests, or reviewing Git history quality.
license: CC-BY-4.0
compatibility: >
  Compatible with GitHub Copilot, Copilot Coding Agent, Copilot CLI,
  VS Code Agent Mode, Claude Code, and other agents supporting Agent Skills.
metadata:
  category: git
  maturity: stable
  audience:
    - professional-teams
    - open-source
    - enterprise
  philosophy:
    - git-history-as-documentation
    - correctness-over-convenience
  enforced-standards:
    - conventional-commits
    - semantic-branch-naming
---

# Git Discipline Skill

This skill enforces **high-quality, consistent Git practices** across the entire
development workflow.

The agent MUST prioritize Git history quality as a first-class concern,
alongside correctness and readability.

---

## Scope of This Skill

Apply this skill when the task involves any of the following:

- Creating or suggesting Git branch names
- Writing or revising commit messages
- Splitting or squashing commits
- Preparing pull requests
- Reviewing Git history or diffs

---

## 1. Branch Naming Convention

### Rule

All branch names MUST follow this format:

```
<type>/<short-description></short-description></type>
```

### Allowed Types

- ✨ feature
- 🐛 fix
- 🚑 hotfix
- ♻️ refactor
- 🔧 chore
- 📝 docs
- ✅ test

### Naming Rules

- Use lowercase letters only
- Use hyphens (`-`) to separate words
- Keep the description concise (5–7 words max)
- Do NOT include issue numbers unless explicitly requested

### Examples

✅ Valid:

`feature/add-user-auth`
`fix/handle-null-response`
`docs/update-readme`

❌ Invalid
`Feature/AddUserAuth`
`bugfix_login_issue`
`feature/1234-add-auth`


### Agent Behavior

- When generating Git commands, ALWAYS suggest compliant branch names
- If a non-compliant name is detected, propose a corrected alternative

---

## 2. Conventional Commits

### Rule

All commit messages MUST follow the Conventional Commits format:

```
<type>(<scope>): <description></description></scope></type>
```

### Allowed Types

- ✨ feat: new features
- 🐛 fix: bug fixes
- 📝 docs: documentation-only changes
- 💄 style: formatting, linting (no logic change)
- ♻️ refactor: internal refactoring without behavior change
- ⚡ perf: performance improvements
- ✅ test: adding or fixing tests
- 🔧 chore: build, CI, tooling, dependency updates

### Scope Rules

- Scope is OPTIONAL
- If used, scope MUST represent a logical module or domain
- Do NOT use filenames as scope

### Description Rules

- Use imperative mood (e.g., "add", not "added")
- Start with a lowercase letter
- Do NOT end with a period

### Examples

✅ Valid

`feat(auth): add token refresh logic`
`fix(api): handle null error response`
`chore(ci): update workflow timeout`

❌ Invalid

`Fixed login bug`
`feat: Added new feature.`
`fix(login_bug)`

### Agent Behavior

- ALWAYS propose commit messages in this format
- Rewrite or reject non-compliant commit messages
- Prefer clarity over brevity when necessary

---

## 3. Commit Type Accuracy

### Rule

The agent MUST accurately distinguish commit intent.

### Guidelines

| Situation | Commit Type |
|---------|------------|
| New external behavior or API | feat |
| Bug fix without adding features | fix |
| Behavior-preserving improvement | refactor |
| Internal maintenance / cleanup | chore |
| Performance-only improvement | perf |

### Disambiguation Rule

If unsure between `feat` and `fix`:

> Default to **fix**, unless new outward-facing behavior is introduced.

### Agent Behavior

- When suggesting commits, briefly explain WHY the selected type was chosen
- Avoid overusing `feat`

---

## 4. Commit Granularity

### Rule

- One logical change per commit
- Avoid mixing refactors and functional changes

### Agent Behavior

- Prefer multiple small, focused commits
- Suggest splitting commits when unrelated changes are detected
- Avoid "WIP" commits on shared or protected branches

---

## 5. Pull Request Convention

### PR Title

- MUST follow Conventional Commits format
- Should align with the primary commit type

### PR Description Template

The agent SHOULD generate PR descriptions using the following structure:

```
## 変更対象
- What was changed

## 変更理由
- Why the change was necessary

## 変更方法
- High-level implementation notes

## 関連
- Related issues or tickets (optional)
```

### Agent Behavior

- Ensure PR title is consistent with commit history
- Flag mismatches between PR title and commits

---

## 6. Branching and History Strategy

### Rules

- Prefer short-lived branches
- Rebase over merge unless explicitly instructed otherwise
- Maintain a clean, linear history where possible

### Agent Behavior

- Suggest rebasing when merge commits add no value
- Warn when history becomes noisy or unclear

---

## Priority Order

When making decisions, the agent MUST prioritize:

1. Correctness
2. Readability
3. Git history quality

---

## Explicit Restrictions

- Do NOT introduce alternative Git workflows unless explicitly requested
- Follow repository-defined rules over general best practices
- Do NOT relax these rules for convenience

---

## Summary

This skill treats **Git discipline as part of code quality**.

The agent must act as a senior engineer who:
- Cares about future maintainers
- Treats history as documentation
- Leaves the repository better than it was found
