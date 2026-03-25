# TypeLingo Phase 1 Postmortem

This document summarizes the first development phase of TypeLingo: a macOS prototype that watches the currently focused input field, translates text in near real time, and displays the result in a floating subtitle overlay.

The goal of this phase was not to finish the product. The goal was to answer a narrower and more useful question:

Can we build a working macOS tool that captures typing activity from arbitrary input fields, routes the text through configurable translation providers, and renders the result in a subtitle-style overlay that is actually usable?

The answer is yes, with an important constraint: the current prototype is viable as a real local tool, but not yet as the final technical architecture. The main unresolved boundary is IME composition support, which will require an eventual move from an Accessibility-based capture model to an `InputMethodKit`-based implementation.

## 1. Project Background

TypeLingo started from a simple user-facing idea: while typing in any input field on macOS, show a translated version of that text in a live subtitle window.

The idea sounds lightweight. The implementation is not.

At the product level, the request looks like a floating translation overlay. At the systems level, it is a macOS text-capture problem. The main engineering challenge is not translation quality. It is whether the app can reliably observe the user's current input across a wide range of applications without becoming brittle, invasive, or misleading.

That distinction shaped the entire project.

## 2. Phase 1 Goals

The first phase had five concrete goals:

1. Prove that focused-input capture was possible on macOS without building a full input method on day one.
2. Build a real subtitle overlay instead of a fake in-app demo.
3. Support at least two translation backends so the product was not coupled to one provider.
4. Make the tool configurable enough for repeated use: provider settings, prompt settings, target language, hotkey, appearance.
5. Package and open-source the result in a way that other developers could inspect, run, and iterate on.

This phase explicitly did not aim to solve every hard platform problem. In particular, it did not aim to fully solve Chinese IME composition, perfect app coverage, or notarized public distribution.

## 3. What Was Built

By the end of the phase, the project had evolved from a rough prototype into a coherent open-source macOS app with the following capabilities:

- macOS native app built with SwiftUI and AppKit
- focused input monitoring via the Accessibility API
- floating, resizable subtitle overlay
- configurable global wake shortcut
- support for `Google Web` translation
- support for `OpenAI-compatible` translation APIs
- multiple API profiles
- multiple prompt profiles for different translation scenarios
- settings import and export
- API key storage in macOS Keychain
- local packaging into `.app`, `.zip`, and `.dmg`
- open-source repository setup and initial GitHub Release

This is a meaningful result. It is not just a UI mock. It is a usable end-to-end system with real operating system integration, provider abstraction, configuration management, persistence, and packaging.

## 4. Core Product And Engineering Thinking

### 4.1 The First Important Decision: Build The Right Prototype

The most important early decision was not about UI and not about models. It was about choosing the right prototype boundary.

There were two possible approaches:

- build the final architecture immediately with `InputMethodKit`
- build a lower-risk prototype on top of the Accessibility API and validate the full interaction loop first

The second path was chosen deliberately.

That decision was based on one principle: before building the hardest possible version of the system, validate that the full product loop is worth building. In this case, the loop was:

focused input -> captured text -> translation provider -> subtitle overlay -> settings and iteration

This turned out to be the right call. It gave the project a working product surface quickly, exposed real usability issues early, and made later architectural tradeoffs much more concrete.

### 4.2 Recognize The Real Bottleneck

A recurring theme throughout the build was that the translation problem was never the hardest part.

The hardest part was always input capture:

- different app frameworks expose text differently
- secure fields must be ignored
- Electron, games, and remote desktop clients are inconsistent
- Chinese IME composition often is not visible to Accessibility polling in a reliable way

This mattered because it changed how the project should be scoped. If this had been treated as "mostly a floating translation UI," the prototype would have optimized the wrong layer first.

Instead, the work prioritized system observation, text flow, overlay usability, and configuration hygiene before investing in polish that would have hidden the real risks.

### 4.3 Separate Fast Validation From Long-Term Correctness

Another key principle was to avoid pretending that the prototype had already solved the final architecture.

Several constraints were kept explicit throughout development:

- Accessibility capture is good enough for a prototype, but not equivalent to an input method
- local packaging is good enough for testing, but not equivalent to notarized public distribution
- storing secrets in plaintext is acceptable only temporarily, not as a durable design

This approach avoided a common failure mode in prototype work: shipping something that appears complete while its deepest assumptions remain unresolved.

## 5. Major Challenges And How They Were Handled

### 5.1 Challenge: Arbitrary Input Field Monitoring On macOS

This was the foundational challenge.

The product requirement was "any input field." On macOS, that is not a single interface. The system has to deal with:

- native AppKit controls
- browser inputs
- Electron apps
- custom text widgets
- inaccessible controls
- secure inputs that must never be captured

The initial solution was to use the Accessibility API and poll the focused input element. That gave the project a real capture path quickly and worked well enough for many standard text fields.

The tradeoff was accepted knowingly:

- strong enough for product validation
- not sufficient for robust IME composition support

This was resolved in Phase 1 by documenting the constraint clearly rather than obscuring it. The future direction is already understood: if TypeLingo needs reliable mid-composition text, it must eventually move to `InputMethodKit`.

### 5.2 Challenge: Making The Overlay Feel Like A Subtitle Tool Instead Of A Debug Panel

The overlay went through several iterations. Early versions exposed too much internal state or too many controls directly in the floating window.

That created obvious problems:

- the overlay looked tool-like rather than product-like
- controls distracted from the subtitle content
- long text could become unreadable or clipped
- some UI affordances were technically available but not actually useful

The solution was gradual refinement:

- remove unnecessary original-text display from the overlay
- minimize visible status noise
- keep the overlay focused on translated output
- move complex controls into the settings panel
- support window resizing
- keep only high-frequency controls in the overlay header

This was a useful reminder that a floating tool window should not be treated like a settings page. The closer it felt to a subtitle card, the better the product became.

### 5.3 Challenge: Configuration Complexity Grew Faster Than The First Architecture

The app started simply, but the number of meaningful settings grew quickly:

- target language
- active provider
- multiple provider profiles
- multiple prompt profiles
- font size
- background opacity
- wake shortcut
- import and export

At that point, configuration stopped being incidental state and became a system of its own.

The first version stored too much directly in preferences, including secrets. That was corrected by moving API keys into Keychain, keeping structured profile data in preferences, and making exports exclude API keys by default.

This was one of the most important hardening steps in the project. It moved the app from "works locally" to "has a minimally responsible configuration model."

### 5.4 Challenge: Packaging And Distribution Were More Than A Final Step

Packaging initially looked like a small operational task. It was not.

Several issues had to be handled:

- how to generate a working `.app`
- how local signing affects launch behavior
- how repeated repackaging affects Accessibility permission stability
- how to generate `.zip` and `.dmg`
- how to distinguish "shareable for internal testing" from "publicly distributable"

The solution was to separate those concerns cleanly:

- local `.app` builds are ad-hoc signed so they can launch reliably
- release scripts can generate `.zip` and `.dmg` for internal distribution
- documentation explicitly states that public distribution still requires `Developer ID` signing and notarization

This was not glamorous work, but it was necessary. Without it, the project would have looked further along than it really was.

### 5.5 Challenge: Too Much Manual Verification

During the early and middle parts of the project, many regressions could only be caught manually. This was workable for UI iteration but became riskier once security, persistence, and migration logic were added.

A minimal automated test layer was added later in the phase to cover:

- secret sanitization
- export behavior
- wake shortcut formatting
- migration away from plaintext provider keys in preferences

This test suite is still small, but it changed the confidence level of later refactors substantially.

## 6. What Worked Well

Several parts of the project worked better than expected.

### 6.1 The MVP Boundary Was Chosen Well

The prototype did not try to solve everything. It solved enough of the product to be real while leaving the deepest platform-specific problem explicit.

That let the project move fast without becoming fake.

### 6.2 Iteration Speed Stayed High

One of the strengths of this build was the speed of response to product feedback. Overlay behavior, settings structure, hotkey recording, provider switching, export behavior, and release packaging all evolved quickly through direct iteration.

That fast loop was especially valuable for the UI and workflow pieces, where static planning would have been slower and less accurate than building and adjusting.

### 6.3 The Product Surface Became Coherent

By the end of the phase, TypeLingo was no longer a collection of disconnected prototype features. It had become a coherent tool with:

- a clear primary workflow
- a recognizable overlay identity
- meaningful provider abstraction
- a practical settings model
- a credible open-source starting point

### 6.4 The Project Did Not Hide Its Hardest Unsolved Problem

This may be the most important success.

The project ended the phase with a better understanding of its real technical boundary than it had at the start. The main unsolved problem is now narrow and concrete:

reliable IME composition capture on macOS

That is a healthy project state. It means the next phase is about a real technical frontier, not about rediscovering the problem definition.

## 7. What Could Have Been Better

### 7.1 The Phase Boundary Should Have Been Written Down Earlier

The project moved across three implicit modes over time:

- quick prototype
- personal-use product
- public open-source project

Those are related, but they are not identical. The lack of an explicit phase document meant some effort was spent reinterpreting goals in the middle of development instead of once at the beginning.

In future work, a one-page phase brief would help:

- what this phase must prove
- what it does not need to solve yet
- how success is measured

### 7.2 Naming Was Finalized Too Late

The transition from an internal `Live Translate` identity to the public `TypeLingo` name required updates across:

- app name
- binary name
- packaging scripts
- bundle identifier
- release asset names
- repository documentation

This was manageable, but it happened later than ideal. Naming decisions become more expensive once packaging and release workflows exist.

### 7.3 Settings Logic Centralized Too Much Responsibility

`AppState` was effective for speed, but it accumulated a large range of responsibilities:

- persistence
- migration
- UI state
- import and export
- prompt and provider selection
- shortcut configuration
- error state

That is acceptable in an early-phase prototype, but it is the clearest code-structure warning sign going into Phase 2.

### 7.4 Automated Tests Arrived Late

The test coverage that now exists is valuable, but it should have started earlier for the configuration and persistence paths.

The late addition of tests increased the cost of some refactors and made certain regressions harder to diagnose than necessary.

## 8. Efficiency Review

Overall development efficiency was strong, especially given the breadth of the system:

- OS integration
- native UI
- translation APIs
- configuration
- secret storage
- packaging
- open-source packaging
- GitHub release workflow

That said, several improvements would make the next phase materially faster and safer.

### 8.1 Write A One-Page Phase Plan Up Front

Not a full design document. Just a one-page working brief.

Suggested structure:

- phase objective
- user outcome
- hard platform constraints
- non-goals
- exit criteria

This would reduce midstream reframing and make prioritization cleaner.

### 8.2 Split Product State From Settings Storage Earlier

The current implementation is fast to work in, but the next phase should separate:

- runtime app state
- persisted preferences
- provider profile management
- prompt profile management
- secret storage
- overlay appearance state

That separation would make the code easier to test and safer to evolve.

### 8.3 Add CI Before Phase 2 Starts

At minimum, the repository should automatically run:

- `swift build`
- `swift test`

This is cheap leverage. It protects the project as the configuration model, provider layer, and platform integration get more complex.

### 8.4 Create A Small Research Track For `InputMethodKit`

The next major risk should not be mixed into feature work.

Instead, it should be isolated as a technical spike:

- can a minimal macOS input method capture IME composition the way the product needs?
- what new UX constraints come with becoming an input method?
- how much of the existing overlay and provider logic can be reused?

That work should happen as a separate investigation, not as an incidental extension of the current Accessibility prototype.

### 8.5 Tighten The Release Workflow

The release flow now works, but it can be improved:

- add GitHub Actions for build and test
- define a release checklist
- optionally automate release creation from tags
- later add notarized release support when a paid Apple Developer account is available

## 9. Current State Of The Project

At the end of Phase 1, TypeLingo can be described accurately as:

- a real macOS prototype
- a usable local tool
- an open-source codebase with a clear product direction
- not yet the final technical architecture

This is a strong phase outcome.

The project is not blocked by uncertainty about what to build. It is constrained by one well-understood systems problem. That is exactly where a healthy prototype should land.

## 10. Recommended Focus For Phase 2

The next phase should stay narrow.

Recommended priorities:

1. Run a focused `InputMethodKit` feasibility investigation.
2. Refactor state and settings boundaries before the codebase grows further.
3. Add CI and basic release discipline around the open-source repository.

Everything else should be secondary to those three items.

## 11. Final Assessment

The most important outcome of this phase is not that TypeLingo now exists as a packaged macOS app.

The most important outcome is that the project now has:

- a validated product loop
- a realistic understanding of its platform constraints
- a working codebase with repeatable packaging
- a credible public repository
- a sharply defined next technical frontier

That is a successful first phase.
