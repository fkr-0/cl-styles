# Changelog

All notable changes to `cl-styles` are recorded here. The library follows semantic versioning independently of ElmTUI.

## Unreleased

Candidate version: **0.2.0**. This remains an in-tree candidate and is not a
registry publication or tagged release; the GitHub source repository exists.

### Added

- Added a standalone GitHub Actions CI workflow: pinned SBCL 2.6.2 / CLPM 0.4.1, FiveAM verification, fail-closed SB-COVER executable-line measurement, and GitHub Pages/verified coverage badge publication after the verification job.
- Repaired SB-COVER LCOV compiler-line instrumentation; 218 tests pass and the measured baseline is 60.42% (60% ratchet, 85% target).
- Added a standalone OCP workflow identity, README CI/coverage badges, and generated-artifact ignore rules.
- Added ASDF-native `test-op`, regression cases for keyword conversions and
  value initialization aliases, and a deterministic extracted-source test
  target.
- Revisioned computed-style results plus `explain-style` declaration traces with winner/override, origin, specificity, source order, inheritance, and variable-expansion evidence.
- Typed `missing-style-variable`, `style-variable-cycle`, and invalid-selector diagnostics, including variable fallbacks.
- Monotonic `stylesheet-revision` tracking for rule and variable mutations.
- Terminal geometry declarations for offsets and scroll positions.
- Canonical property aliases for TUI color/background values.
- Expanded flex/gap, border, selector, inheritance, variable, and edge-case coverage.
- Path-independent local CLPM bundle metadata.

### Changed

- Cascade precedence is explicit: property defaults, inheritance, matching rules by specificity/source order, then inline style. Equal-specificity later rules now win.
- Each declaration source resolves variables and expands shorthands before precedence merging, preventing a lower-specificity longhand from blocking a higher-specificity shorthand.
- Static selectors and known property declarations are validated at rule/stylesheet construction boundaries where possible.
- `add-rule` appends to stylesheet source order. Legacy tree-cache keywords are accepted but ignored so full recomputation is the correctness oracle until revision-safe caching is implemented.
- Property normalization now happens at the reusable styling boundary instead of in renderer-specific compatibility code.
- The CSS-like selector/cascade/property engine remains independent of ElmTUI widgets and rendering policy.

## 0.1.0

- Initial CSS-like selector, rule, stylesheet, token, property, protocol, and cascade engine.

### Fixed

- Repaired stylable protocol fixtures, selector package conflicts, API/core
  style equality, stylesheet query compatibility, style-set raw values, and
  public-facade selector macro bindings.
