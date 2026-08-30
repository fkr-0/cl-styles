# Changelog

All notable changes to `cl-styles` are recorded here. The library follows semantic versioning independently of ElmTUI.

## Unreleased

Candidate version: **0.2.0**. This remains an in-tree candidate and is not a
registry publication or separate-repository release.

### Added

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
