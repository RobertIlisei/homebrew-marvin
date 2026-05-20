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
# Single source of truth at install time. The same key is also
# pinned in this tap's README.md and in the MARVIN repo's
# `.minisign-pubkey` file at https://github.com/RobertIlisei/MARVIN .
# Phase 1: pubkey is published for manual verification; Phase 2 will
# add a cask-side preflight that auto-verifies before the install.
#
# Currently a PLACEHOLDER until @robertilisei generates the key pair
# and uploads the secret to the MARVIN repo's GitHub Actions secrets
# (see ADR-0026 §"Key generation"). When the real key lands, replace
# the second line of the comment block below with the actual pubkey
# string from `cat ~/.minisign/marvin.pub` (the line starting `RW…`).
MARVIN_MINISIGN_PUBKEY = <<~PUBKEY.freeze
  untrusted comment: minisign public key for RobertIlisei/MARVIN
  PLACEHOLDER — see ADR-0026 in the MARVIN repo for the key-gen procedure
PUBKEY

cask "marvin-ai" do
  version "0.1.8"

  # The release workflow stamps this sha into the run summary. Bump
  # it whenever you bump `version` above — Homebrew refuses to install
  # a cask whose downloaded zip doesn't match.
  sha256 "6372f58f0feb193f28083c65e420c06ebf402439f0adaf58e84cea21701436f3"

  url "https://github.com/RobertIlisei/MARVIN/releases/download/v#{version}/MARVIN-#{version}-arm64.zip"

  name "MARVIN"
  desc "Pair-programming AI assistant for macOS"
  homepage "https://github.com/RobertIlisei/MARVIN"

  # Apple Silicon only for now. Adding x86_64 means a second build
  # path in release.yml and a second SHA — defer until someone asks.
  depends_on arch: :arm64
  depends_on macos: ">= :sonoma"

  app "MARVIN.app"

  # Clean up MARVIN's per-user state on `brew uninstall --zap`. The
  # `app:` line above already removes /Applications/MARVIN.app on a
  # plain uninstall; `zap` is the optional extra that wipes the data
  # directory + log file + the legacy launchd agent (in case the user
  # ever ran the developer install with --launchd).
  zap trash: [
    "~/.marvin",
    "~/Library/Logs/MARVIN",
    "~/Library/LaunchAgents/net.marvin.desktop.server.plist",
    "~/Library/Application Support/MARVIN",
    "~/Library/Caches/net.marvin.macos",
    "~/Library/Preferences/net.marvin.macos.plist",
  ]

  caveats <<~EOS
    MARVIN is ad-hoc signed (no Apple Developer ID). On first launch,
    macOS may ask you to confirm — that's expected; brew has already
    stripped the quarantine xattr so the warning is one click, not a
    deal-breaker.

    MARVIN needs Anthropic credentials to do anything useful. Either:
      • use the Claude CLI you already have installed (`claude login`), or
      • paste an API key in MARVIN → Settings → Authentication.

    See:
      https://github.com/RobertIlisei/MARVIN#installation
  EOS
end
