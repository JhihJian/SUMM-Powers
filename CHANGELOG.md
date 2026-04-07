# Changelog

## Unreleased

### Fixed

- **Brainstorm server on Windows**: Auto-detect Windows/Git Bash (`OSTYPE=msys*`, `MSYSTEM`) and switch to foreground mode, fixing silent server failure caused by `nohup`/`disown` process reaping. Applies to all Windows shells (CMD, PowerShell, Git Bash) since they all route through Git Bash. (fixes #737, based on #740)
- **Brainstorm owner-PID on Windows**: Skip `BRAINSTORM_OWNER_PID` lifecycle monitoring on Windows/MSYS2 where the PID namespace is invisible to Node.js. Prevents the server from self-terminating after 60 seconds. The 30-minute idle timeout remains as the safety net. ([#770](https://github.com/obra/superpowers/issues/770))
- **Portable shebangs**: Replace `#!/bin/bash` with `#!/usr/bin/env bash` in all shell scripts. Fixes execution on NixOS, FreeBSD, and macOS with Homebrew bash. ([#700](https://github.com/obra/superpowers/pull/700))
- **POSIX-safe hook script**: Replace `${BASH_SOURCE[0]:-$0}` with `$0` in `hooks/session-start`. Fixes 'Bad substitution' error on Ubuntu/Debian where `/bin/sh` is dash. ([#553](https://github.com/obra/superpowers/pull/553))
- **Bash 5.3+ hook hang**: Replace heredoc with `printf` in `hooks/session-start`. Fixes indefinite hang on macOS with Homebrew bash 5.3+. ([#572](https://github.com/obra/superpowers/pull/572))
- **stop-server.sh reliability**: Verify the server process actually died before reporting success. Escalates to `SIGKILL` if needed. ([#723](https://github.com/obra/superpowers/issues/723))

### Known Issues

(None currently tracked.)
