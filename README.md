# TypeLingo

TypeLingo is a macOS live subtitle overlay that watches the currently focused text field, translates the text in near real time, and renders the result in a floating on-screen subtitle panel.

It is designed for:

- bilingual chat and support workflows
- live demos and screen recordings
- streaming overlays
- fast translation while typing in any standard macOS text field

This project is currently a native macOS prototype built on top of the Accessibility API. It is intentionally lightweight and practical, but it is not yet a full input method, so IME composition support is still limited.

## What It Does

- monitors the focused input control on macOS
- ignores secure text fields
- translates captured text into a selected target language
- shows the translated text in a resizable floating subtitle window
- supports a configurable global wake shortcut to show or hide the overlay
- supports `Google Web` and `OpenAI-compatible` translation backends
- supports multiple API profiles and multiple prompt profiles
- stores API keys in macOS Keychain instead of plaintext app preferences
- supports settings import and export

## Current Limitations

- it depends on Accessibility permission
- Chinese and other IME composition text is not fully reliable until this becomes a true `InputMethodKit` implementation
- some Electron apps, games, remote desktop clients, and custom controls do not expose usable Accessibility text values
- `Google Web` is a convenience prototype backend, not a production SLA-backed integration
- unsigned or ad-hoc signed builds will still be blocked by Gatekeeper on other Macs

## Stack

- Swift 6
- SwiftUI
- AppKit
- Accessibility API
- macOS Keychain
- Swift Package Manager

## Getting Started

### Requirements

- macOS 14 or newer
- Xcode Command Line Tools

### Run From Source

```bash
git clone git@github.com:DEROOCE/TypeLingo.git
cd TypeLingo
swift run typelingo
```

On first launch, grant `Accessibility` permission in:

`System Settings -> Privacy & Security -> Accessibility`

### Build

```bash
swift build
swift test
```

## Using Translation Providers

TypeLingo currently supports two provider modes:

### Google Web

- no API key required
- best for quick local testing
- lower setup friction

### OpenAI-Compatible

- configurable `API Key`, `Base URL`, and `Model`
- supports multiple API profiles
- supports multiple system prompt profiles for different translation styles

## Packaging

### Build a Local App Bundle

```bash
./scripts/package-app.sh
```

Output:

```bash
dist/TypeLingo.app
```

The local app bundle is ad-hoc signed so Finder and `open` can launch it reliably on your own machine.

### Build Release Artifacts

```bash
./scripts/package-release.sh
```

Outputs:

```bash
dist/TypeLingo-0.1.0.zip
dist/TypeLingo-0.1.0.dmg
```

Without a real `Developer ID Application` certificate and notarization, these artifacts are suitable only for local use or limited internal testing.

## Developer ID Signing And Notarization

For public distribution on macOS, you need:

- a valid `Developer ID Application` certificate
- a configured `notarytool` keychain profile

Example:

```bash
SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_KEYCHAIN_PROFILE="typelingo-notary" \
./scripts/package-release.sh
```

## Settings And Secrets

- UI settings are stored in macOS preferences
- API keys are stored in macOS Keychain
- default settings export excludes API keys
- `Export With API Keys` exists for trusted-machine migration only

## Roadmap

- move from Accessibility polling to a more reliable text observation model
- add app blacklist and per-app behavior tuning
- improve segmentation for long typing sessions
- evolve into an `InputMethodKit` implementation for true IME composition support

## Open Source Status

TypeLingo is open sourced as an actively evolving prototype. The product direction is clear, but some implementation details are still optimized for iteration speed rather than long-term framework completeness.

If you use it, expect:

- a practical local tool
- fast iteration
- explicit macOS platform constraints

## License

MIT
