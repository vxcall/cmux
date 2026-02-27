# mux — tmux for Claude Code

Run a fleet of Claude agents on the same repo — each in its own worktree, zero conflicts, one command each.

Claude Code works best when it has full ownership of the working directory. Want two agents working in parallel? They'll stomp on each other — conflicting edits, dirty state, broken builds. You need separate checkouts.

[Git worktrees](https://git-scm.com/docs/git-worktree) are the perfect primitive for this. They share the same `.git` database but give each agent its own directory tree — no cloning, no syncing, branches stay in lockstep. mux wraps the entire worktree lifecycle into single commands so you can spin agents up, jump between them, and tear them down without thinking about it.

You wanna go fast without losing your goddamn mind. This is how.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/vxcall/cmux/main/install.sh | sh
```

Then add `.worktrees/` to your `.gitignore`:

```sh
echo '.worktrees/' >> .gitignore
```

## Quick start

```sh
mux new <your feature name> --claude   # creates worktree + branch, runs setup hook, launches Claude
mux new <your feature name> --codex    # same, but launches Codex
mux new <your feature name>            # worktree only, no agent launched
```

That's it. One command, one agent, fully isolated. See [Workflow](#workflow) for the full loop.

## Commands

| Command | What it does |
|---------|-------------|
| `mux new <branch> [--claude\|--codex] [-p <prompt>]` | Create **new** worktree + branch, run setup hook, optionally launch agent |
| `mux start <branch> [--claude\|--codex] [-p <prompt>]` | **Continue** where you left off in an existing worktree, optionally launch agent |
| `mux cd [branch]` | cd into a worktree (no args = repo root) |
| `mux ls` | List active worktrees |
| `mux merge [branch] [--squash]` | Merge worktree branch into your primary checkout (no args = current worktree) |
| `mux rm [branch \| --all]` | Remove a worktree and its branch (no args = current, `--all` = every worktree with confirmation) |
| `mux init [--replace]` | Generate `.mux/setup` hook using Claude (`--replace` to regenerate) |
| `mux update` | Update mux to the latest version |
| `mux version` | Show current version |

## Workflow

You're building a feature:

```sh
mux new feature-auth --claude        # agent starts working on auth
```

Bug comes in. No problem — spin up another agent without leaving the first one:

```sh
mux new fix-payments --claude        # second agent, isolated worktree, independent session
```

Merge the bugfix when it's done:

```sh
mux merge fix-payments --squash
mux rm fix-payments
```

Come back tomorrow and pick up the feature work right where you left off:

```sh
mux start feature-auth --claude      # picks up right where you left off
```

The key distinction: `new` = new worktree, new session. `start` = existing worktree, continuing session.

## Setup hook

When `mux new` creates a worktree, it runs `.mux/setup` if one exists. This handles project-specific init — symlinking secrets, installing deps, running codegen. If no setup hook exists, you'll be prompted to generate one.

The easy way — let Claude write it for you:

```sh
mux init
```

Or create one manually:

```bash
#!/bin/bash
REPO_ROOT="$(git rev-parse --git-common-dir | xargs dirname)"
ln -sf "$REPO_ROOT/.env" .env
npm ci
```

See [`examples/`](examples/) for more.

## How it works

- Worktrees live under `.worktrees/<branch>/` in the repo root
- Branch names are sanitized: `feature/foo` becomes `feature-foo`
- `mux new` is idempotent on the worktree — if it already exists, it skips creation and setup
- Use `--claude` or `--codex` with `mux new`/`mux start` to launch an agent; omitting the flag only enters the worktree
- `mux merge` and `mux rm` with no args detect the current worktree from `$PWD`
- Pure bash — just git and the Claude CLI

## Tab completion

You never have to remember branch names. Built-in completion for bash and zsh — automatically registered when you source `mux.sh`, no extra setup.

- `mux <TAB>` — subcommands
- `mux start <TAB>` — existing worktree branches
- `mux cd <TAB>` — existing worktree branches
- `mux rm <TAB>` — worktree branches + `--all`
- `mux merge <TAB>` — worktree branches
- `mux init <TAB>` — `--replace`

## License

MIT
