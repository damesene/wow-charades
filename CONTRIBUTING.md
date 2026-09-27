# Contributing

- `tests/harness.lua` runs the automated checks against a mocked WoW API: `lua5.1 tests/harness.lua` from the repository root.
- Releases: push a tag like `v1.0.1`; GitHub Actions packages the addon and uploads it (see `.github/workflows/release.yml`).
