# homebrew-marvin

Homebrew tap for [MARVIN](https://github.com/RobertIlisei/MARVIN), the pair-programming AI assistant.

> **Cask token:** `marvin-ai`, not `marvin`. The plain `marvin` token is taken by the [Amazing Marvin](https://www.amazingmarvin.com/) productivity app in the official `homebrew-cask` repo, so we disambiguate with the `-ai` suffix.

## Install

```bash
brew tap RobertIlisei/marvin
brew install --cask marvin-ai
```

That's it — MARVIN.app appears in `/Applications`, the bundled sidecar starts with the app, and quitting MARVIN cleans it up. No Swift, Node, or pnpm install required on your machine.

You'll need Anthropic credentials to use it: either run `claude login` (the Claude CLI handles it) or paste an API key in MARVIN's Settings → Authentication.

## Update

```bash
brew upgrade --cask marvin-ai
```

## Uninstall

```bash
brew uninstall --cask marvin-ai
# or, to also wipe ~/.marvin and the log directory:
brew uninstall --zap --cask marvin-ai
```

## Architecture

The cask downloads an ad-hoc-signed `MARVIN.app` from the [MARVIN releases](https://github.com/RobertIlisei/MARVIN/releases). Brew strips the `com.apple.quarantine` xattr during install, which is what lets the unsigned bundle open without Gatekeeper friction. See [ADR-0023](https://github.com/RobertIlisei/MARVIN/blob/main/docs/decisions/0023-brew-distributable-bundled-sidecar.md) for the full bundling design.

Apple Silicon only for now (`depends_on arch: :arm64`). Intel Macs will need a separate build path; open an issue on the MARVIN repo if that's blocking you.

## Bumping the version

When a new MARVIN release ships:

1. Find the new release at https://github.com/RobertIlisei/MARVIN/releases — the workflow attaches `MARVIN-<version>-arm64.zip` and prints the SHA-256 in the release notes.
2. In `Casks/marvin.rb`:
   - Bump `version "<new>"`
   - Replace `sha256 :no_check` (or the prior hash) with the new SHA-256.
3. Commit + push. Users get the update next time they `brew upgrade --cask marvin-ai`.
