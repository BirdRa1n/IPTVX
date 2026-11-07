# Contributing to IPTVX

Thanks for your interest! This guide keeps the codebase consistent for
humans and AI agents alike.

## Workflow

1. Create a branch from `main` (`feat/…`, `fix/…`, `docs/…`).
2. Build with the `debug` preset, run `ctest --preset debug` and
   `cmake --build --preset debug --target all_qmllint`.
3. Keep commits small and focused; one logical change per commit.
4. Open a pull request describing the change, how you tested it and, for UI
   work, before/after screenshots (see the developer mode in
   [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)).

## Commit messages

[Conventional Commits](https://www.conventionalcommits.org/), in English,
imperative mood:

```
feat(core): add streaming XMLTV parser

Explain *why* and any trade-offs in the body, wrapped at 72 columns.
```

Types: `feat`, `fix`, `perf`, `refactor`, `test`, `docs`, `build`, `ci`,
`chore`, `i18n`. Scopes: `core`, `ui`, `app`, `player`, `agents`, …

## Code style

* C++20, formatted with the repository `.clang-format`.
* Qt string safety is enforced (`QT_NO_CAST_FROM_ASCII`): use `u"…"_s`,
  `"…"_L1` or `QStringLiteral`.
* Prefer value types and `std::shared_ptr<const T>` for shared immutable
  data; no raw owning pointers outside Qt parent/child ownership.
* QML: `pragma ComponentBehavior: Bound` for files with delegates,
  `required property` for model roles, only `Theme` tokens for styling.
* Follow the [memory rules](docs/MEMORY.md#rules-for-new-code).

## Tests & fixtures

* Every core change ships with Qt Test coverage in `tests/core/`.
* Fixtures use synthetic data only (`example.com` hosts, made-up names).
  Never commit real playlists, provider URLs or credentials.
