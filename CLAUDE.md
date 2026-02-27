# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is mux

mux is a pure Bash shell tool that manages git worktree lifecycles for running parallel Claude Code sessions. Each worktree gets its own isolated working directory so multiple Claude agents can work on the same repo simultaneously.

## Architecture

**Single-file shell tool** — all logic lives in `mux.sh` (~560 lines), which is sourced into the user's shell (bash/zsh). There is no build step, no dependencies, and no test suite.

**Function structure:**
- `mux()` — public dispatcher, routes subcommands to `_mux_<cmd>` functions
- `_mux_*()` — private functions: `_mux_new`, `_mux_start`, `_mux_cd`, `_mux_ls`, `_mux_merge`, `_mux_rm`, `_mux_rm_all`, `_mux_init`
- Helper functions: `_mux_repo_root`, `_mux_safe_name`, `_mux_worktree_dir`, `_mux_spinner_start/stop`

**Key design patterns:**
- Idempotent operations (e.g. `mux new` reuses existing worktrees)
- Context-aware: `mux rm` and `mux merge` with no args detect the current worktree from `$PWD`
- Branch name sanitization: `feature/foo` → `feature-foo` for directory names
- Worktrees live under `.worktrees/<safe-branch-name>/` in the repo root

**Setup hook system:** `.mux/setup` is an executable bash script that runs after worktree creation. It handles project-specific init (symlink secrets, install deps, codegen). `mux init` uses Claude CLI (`claude -p`) to auto-generate this hook.

## Key files

- `mux.sh` — the entire application
- `install.sh` — curl-pipe installer that downloads mux.sh to `~/.mux/` and adds source line to shell RC
- `.mux/setup` — project-specific worktree setup hook (committed to repo)
- `examples/setup-node` — example setup hook for Node.js projects

## Shell conventions

- 2-space indentation
- Functions prefixed `_mux_` for internal, `mux` for public
- Zsh compatibility: uses `setopt localoptions nomonitor` where needed for job control
- Error handling: validate inputs, check `command -v`, guard with `|| return 1`
- No `set -e` in mux.sh (it's sourced, not executed); install.sh uses `set -e`

## QA — mandatory before considering any task done

Always self-test changes to mux.sh before finishing work. Source the file in a bash subshell and run the affected commands to verify correct output and behavior:

```bash
bash -c 'source /path/to/mux.sh && mux <subcommand> [args]'
```

Test thoroughly: check happy paths, error paths, flag combinations, and edge cases (no args, bad input, missing worktrees, etc.). Do not consider a task complete until you have verified the changes work.
