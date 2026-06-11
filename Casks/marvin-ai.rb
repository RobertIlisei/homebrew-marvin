# Homebrew cask for MARVIN — the pair-programming AI assistant.
#
# Backed by GitHub Releases on https://github.com/RobertIlisei/MARVIN.
# The release artefact is built by .github/workflows/release.yml in
# that repo (an ad-hoc-signed MARVIN.app with a bundled Node runtime
# and Next.js sidecar; see ADR-0023).
#
# Why brew (and not a raw download): MARVIN.app is ad-hoc signed, not
# notarized. macOS refuses to open such bundles by default, but
# Homebrew strips `com.apple.quarantine` automatically during cask
# install — so the user goes from `brew install` to a working
# double-click without typing `xattr` commands. ADR-0023 §Distribution.
#
# Bumping the version: tag the release in the MARVIN repo, wait for
# release.yml to publish the .zip, copy the printed sha256 from the
# Actions log into `sha256` below, push.

# NOTE: cask token is `marvin-ai`, not `marvin` — the homebrew-cask
# core repo already ships a `marvin` cask for "Amazing Marvin" (a
# personal-productivity app), so an unqualified `brew install marvin`
# would resolve to that one. The disambiguating `-ai` suffix keeps
# the brand recognisable while making `brew install --cask marvin-ai`
# unambiguous.

# Minisign public key for release-artefact verification (ADR-0026).
# Single source of truth at install time. Mirrored in this tap's
# README.md and in the MARVIN repo's `.minisign-pubkey` file at
# https://github.com/RobertIlisei/MARVIN/blob/main/.minisign-pubkey .
# Three pinned copies across two repos — a tap-compromise that
# swapped this constant would be visibly inconsistent with the
# MARVIN repo's copy. The rotation procedure is documented in
# ADR-0026; key fingerprint 0794CFDFA5E629D5.
#
# Phase 1 (current): pubkey is published for manual verification;
# the cask install path does NOT auto-verify yet. Phase 2 will add
# a `preflight` step running `minisign -V` before extracting.
MARVIN_MINISIGN_PUBKEY = <<~PUBKEY.freeze
  untrusted comment: minisign public key 0794CFDFA5E629D5
  RWTVKeal38+UBwQ3tC8ETdPZkv8fFLchoXdtwi7UI9XMhaJWuUwx4QAQ
PUBKEY

cask "marvin-ai" do
  version "0.1.24"

  # The release workflow stamps this sha into the run summary. Bump
  # it whenever you bump `version` above — Homebrew refuses to install
  # a cask whose downloaded zip doesn't match.
  #
  # Every release since v0.1.10 carries a .minisig sidecar at the
  # same URL + ".minisig" suffix. The signature is verifiable against
  # MARVIN_MINISIGN_PUBKEY (above) — Phase 1 of ADR-0026. Phase 2
  # will add a `preflight` step that auto-verifies before extracting.
  sha256 "f29d5e65318e904a0e6197b55f68b0ac2c9a49cb7a38dda83c75bf623713e4be"

  url "https://github.com/RobertIlisei/MARVIN/releases/download/v#{version}/MARVIN-#{version}-arm64.zip"

  name "MARVIN"
  desc "Pair-programming AI assistant for macOS"
  homepage "https://github.com/RobertIlisei/MARVIN"

  # Apple Silicon only for now. Adding x86_64 means a second build
  # path in release.yml and a second SHA — defer until someone asks.
  depends_on arch: :arm64
  depends_on macos: ">= :sonoma"

  # ── Install location: ~/Applications, not /Applications ──────────────
  #
  # macOS 26 (Tahoe) enforces a kernel-level Gatekeeper check that
  # kills ad-hoc-signed bundles launched from `/Applications` —
  # process spawns and is immediately killed (RSS stays ~32 KB, no
  # UI, no logs). The same bundle launched from `~/Applications`
  # runs normally because user-scope Applications is exempt from
  # that specific check. See ADR-0027 in the MARVIN repo:
  #
  #   https://github.com/RobertIlisei/MARVIN/blob/main/docs/decisions/0027-macos-26-gatekeeper-user-applications.md
  #
  # `target:` instructs Homebrew to symlink/copy the bundle to that
  # exact path. Spotlight, Launchpad, Finder, and the Dock all
  # recognise `~/Applications` as an Apple-standard app install
  # location — there is no functional difference for the user
  # beyond where the bundle physically lives.
  app "MARVIN.app", target: "~/Applications/MARVIN.app"

  # Clean up MARVIN's per-user state on `brew uninstall --zap`. The
  # `app:` line above already removes ~/Applications/MARVIN.app on a
  # plain uninstall; `zap` is the optional extra that wipes the data
  # directory + log file + the legacy launchd agent (in case the user
  # ever ran the developer install with --launchd), and a stale
  # /Applications/MARVIN.app from a pre-0.1.12 install.
  zap trash: [
    "~/.marvin",
    "~/Library/Logs/MARVIN",
    "~/Library/LaunchAgents/net.marvin.desktop.server.plist",
    "~/Library/Application Support/MARVIN",
    "~/Library/Caches/net.marvin.macos",
    "~/Library/Preferences/net.marvin.macos.plist",
    "/Applications/MARVIN.app",
  ]

  caveats <<~EOS
    MARVIN.app installs to ~/Applications (not /Applications) — required
    on macOS 26 where the kernel-level Gatekeeper kills ad-hoc-signed
    bundles in /Applications. ADR-0027 has the technical detail.

    First launch — one-time Gatekeeper step:
      1. Double-click MARVIN.app (Finder, Spotlight, or Launchpad).
      2. macOS shows "Apple could not verify MARVIN.app…" — click Done.
      3. Open System Settings → Privacy & Security → scroll to Security.
      4. Find "MARVIN.app was blocked from use…" → click Open Anyway.
      5. Authorize with Touch ID. MARVIN launches and is whitelisted
         for the life of the install — you only do this once.

    MARVIN needs Anthropic credentials to do anything useful. Either:
      • use the Claude CLI you already have installed (`claude login`), or
      • paste an API key in MARVIN → Settings → Authentication.

    See:
      https://github.com/RobertIlisei/MARVIN#installation
  EOS
end
