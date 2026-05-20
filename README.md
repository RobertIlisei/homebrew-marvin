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

## Release signing (ADR-0026)

Every MARVIN release zip is signed with [minisign](https://jedisct1.github.io/minisign/). The signature lives alongside the zip on each GitHub Release as `MARVIN-<version>-arm64.zip.minisig`.

**Public key** (pinned here, in [`Casks/marvin-ai.rb`](./Casks/marvin-ai.rb) as `MARVIN_MINISIGN_PUBKEY`, and in the [MARVIN repo's `.minisign-pubkey`](https://github.com/RobertIlisei/MARVIN/blob/main/.minisign-pubkey)):

```
untrusted comment: minisign public key 0794CFDFA5E629D5
RWTVKeal38+UBwQ3tC8ETdPZkv8fFLchoXdtwi7UI9XMhaJWuUwx4QAQ
```

Three pinned copies of the same key in two different repos. A tap-repo compromise that swapped the cask's pubkey constant would be visibly inconsistent with the MARVIN repo's record — that's the defence.

**Verify a downloaded release manually:**

```bash
brew install minisign
VERSION=0.1.9   # whichever version you downloaded
curl -fLO "https://github.com/RobertIlisei/MARVIN/releases/download/v${VERSION}/MARVIN-${VERSION}-arm64.zip"
curl -fLO "https://github.com/RobertIlisei/MARVIN/releases/download/v${VERSION}/MARVIN-${VERSION}-arm64.zip.minisig"
curl -fLO https://raw.githubusercontent.com/RobertIlisei/MARVIN/main/.minisign-pubkey
minisign -V -p .minisign-pubkey -m "MARVIN-${VERSION}-arm64.zip"
```

A successful verify prints `Signature and comment signature verified` and exits 0.

The cask install path (`brew install --cask marvin-ai`) does not yet auto-verify — Phase 2 of ADR-0026 will add a `preflight` step. Until then, manual verification is the canonical path for users who care.

See [ADR-0026](https://github.com/RobertIlisei/MARVIN/blob/main/docs/decisions/0026-release-artefact-signing-minisign.md) for the full signing model.

## Bumping the version

When a new MARVIN release ships:

1. Find the new release at https://github.com/RobertIlisei/MARVIN/releases — the workflow attaches `MARVIN-<version>-arm64.zip` and prints the SHA-256 in the release notes.
2. In `Casks/marvin.rb`:
   - Bump `version "<new>"`
   - Replace `sha256 :no_check` (or the prior hash) with the new SHA-256.
3. Commit + push. Users get the update next time they `brew upgrade --cask marvin-ai`.
