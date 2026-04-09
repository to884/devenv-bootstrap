# Git Discipline Skill

**High‑quality Git history is part of code quality.**

Git Discipline Skill は、  
**ブランチ命名・コミットメッセージ・Pull Request までを一貫して整えるための Agent Skill** です。

このスキルは GitHub Copilot やその他の AI コーディングエージェントに対して、

*   「どんなブランチ名が正しいか」
*   「どんなコミットメッセージが望ましいか」
*   「Git 履歴として何が良い設計か」

を **オンデマンドで教えます**。

***

## ✨ What This Skill Does

This skill enforces:

*   ✅ Consistent branch naming conventions
*   ✅ Strict Conventional Commits compliance
*   ✅ Accurate commit type selection
*   ✅ Clean, reviewable commit granularity
*   ✅ Pull Request titles and descriptions aligned with commit history
*   ✅ Git history as long‑term documentation

It treats **Git discipline as a first‑class engineering concern**, not an afterthought.

***

## 🎯 When This Skill Is Used

The agent should load this skill when tasks involve:

*   Creating or suggesting Git branch names
*   Writing or revising commit messages
*   Deciding commit boundaries or splitting commits
*   Preparing Pull Requests
*   Reviewing Git diffs or commit history

***

## 🧩 Scope & Philosophy

Git Discipline Skill is intentionally **cross‑cutting**:

*   It does **not** automate a single workflow
*   It defines **how all workflows should be recorded**

Design philosophy:

> Treat commit history as a form of documentation  
> Optimize for future maintainers, not short‑term convenience

***

## ✅ Enforced Rules (Summary)

### Branch Naming

    <type>/<short-description>

*   Types: `feature`, `fix`, `hotfix`, `refactor`, `chore`, `docs`, `test`
*   Lowercase, hyphen‑separated
*   Short and descriptive

***

### Commit Messages (Conventional Commits)

    <type>(<scope>): <description>

*   Imperative mood
*   No capitalization at start
*   No trailing period
*   Scope is optional but meaningful when used

***

### Commit Quality

*   One logical change per commit
*   No mixing refactors and behavior changes
*   Prefer multiple clean commits over one large commit
*   Avoid WIP commits on shared branches

***

### Pull Requests

*   PR titles follow Conventional Commits
*   PR descriptions are structured:
    *   What
    *   Why
    *   How
    *   Related (optional)
*   PR title and commit history must align

***

## 🤖 Agent Behavior Guarantees

An agent using this skill will:

*   Propose **compliant branch names**
*   Generate or rewrite **valid Conventional Commit messages**
*   Explain **why a commit type was chosen**
*   Suggest **splitting commits** when changes are unrelated
*   Warn when Git history becomes unclear or noisy
*   Prefer **rebase over merge** unless instructed otherwise

***

## 🛠 Compatibility

This skill follows the **Agent Skills Standard** and works with:

*   GitHub Copilot (Agent / CLI / VS Code Agent Mode)
*   Claude Code
*   Cursor
*   OpenAI Codex
*   Any tool supporting `SKILL.md`‑based Agent Skills

***

## 📁 Installation

Add the skill to your repository:

```text
.github/skills/git-discipline/SKILL.md
```

Or install it as a personal skill:

```text
~/.copilot/skills/git-discipline/SKILL.md
```

Enable Agent Skills in VS Code if needed:

```json
{
  "chat.useAgentSkills": true
}
```

***

## ✅ Intended Audience

*   Teams practicing **code review–driven development**
*   Projects that value **clean Git history**
*   Organizations using **Copilot Agent / autonomous workflows**
*   OSS projects with multiple contributors
*   Enterprises where Git history is **audit‑relevant**

***

## 🔐 Stability & Maturity

*   Maturity: **stable**
*   Opinionated by design
*   Safe for production repositories
*   Suitable as a **baseline Git discipline policy**

***

## 📜 License

This skill is licensed under **CC BY 4.0**  
You may reuse, adapt, and distribute it with attribution.

***

## 🧠 Final Thought

> Code can be refactored.  
> Git history cannot—without cost.

This skill ensures your agents leave behind a repository  
that future humans will thank you for.