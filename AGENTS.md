# Zero Adaptive Link - Agent Guide

This file defines the architecture, coding conventions, and required workflows for the `zero_adaptive_link` Flutter plugin. AI coding agents (CodeBuddy, Trae, Cursor, Claude Code, GitHub Copilot, Codex, etc.) should read and follow it for any task in this repository. It is the single source of truth for project conventions.

## Overview
`zero_adaptive_link` is a pure-Dart Flutter plugin for adaptive navigation: business code writes **one `onTap`** (a `ZeroLink` or `ZeroNav.open(location)`) and the plugin decides by **window width** whether to push a new page (compact / medium) or expand / update a right sidebar pane (expanded, master-detail). Locations are URL-addressable and deep-linkable; the web defaults to the hash strategy (`/#/products/42`). Zero runtime dependencies; no platform channels and no native code.

## When to apply
- Implementing features, fixing bugs, or changing the public API in `lib/`.
- Opening pull requests (titles must follow Conventional Commits; 3 status checks are required to merge).
- Cutting a release or publishing to pub.dev.
- Updating the GitHub Pages documentation site.
- Editing `pubspec.yaml`, the workflows under `.github/workflows/`, or the `website/` docs source.

## Architecture
- `lib/zero_adaptive_link.dart` - public barrel; the ONLY import consumers may use. Re-export the public API here; never ask consumers to import `lib/src/`.
- `lib/src/router/router.dart` - `ZeroRouter` (a `RouterConfig`), `ZeroShell`, `ZeroTab`, `ZeroRoute` plus the builder typedefs (`ZeroRouteBuilder`, `ZeroTitleBuilder`, `ZeroRouteRedirect`, `ZeroRouterRedirect`, `ZeroExitHook`, `ZeroShellBuilder`, `ZeroBreadcrumbsBuilder`, `ZeroErrorBuilder`).
- `lib/src/router/match.dart` - `ZeroRouteMatch`, `MatchList` and the pure location matcher (`ZeroRouteMatcher`): first match wins, child paths are relative to the parent, `:param` matches a single segment.
- `lib/src/router/parser.dart` - `ZeroRouteInformationParser` (location = path + query, hash fragment on web).
- `lib/src/router/delegate.dart` - `ZeroRouterDelegate` (a `RouterDelegate<String>` + `ChangeNotifier`): per-tab page stacks, the fullscreen overlay stack, the current location, the imperative verbs, `popRoute`, and the widget tree.
- `lib/src/router/state.dart` - `ZeroRouteState`, `ZeroShellState`, `ZeroShellScope`, `ZeroPaneScope`, `ZeroRouteStateScope`.
- `lib/src/router/route_information_provider.dart` (+ `_native` / `_web`) - conditional export: web uses the hash URL strategy via `dart:js_interop` (`/#/products/42`), native uses `PlatformRouteInformationProvider`.
- `lib/src/layout/` - `breakpoints.dart` (`Breakpoints`, `BreakpointClass`; 600 / 840 by window width, not device type), `sliding_panes.dart` (`SlidingPanes`), `sliding_pane.dart` (`SlidingPane`), `breadcrumbs.dart` (`Breadcrumbs`).
- `lib/src/nav/zero_nav.dart` - `ZeroNav` imperative facade + `ZeroNavScope`.
- `lib/src/widgets/zero_link.dart` - `ZeroLink` (GestureDetector + MouseRegion; no Material ancestor required).
- `lib/src/shell/shell.dart` - `ZeroShellChrome` (compact bottom bar rendered inside branch pages).
- Widget structure: a root `Navigator` (pages: shell page + fullscreen overlay pages) hosts the shell route; the shell builder receives `child` = per-tab `Navigator` on compact / medium, or `SlidingPanes` over the last two matches on expanded.
- **Pure Dart**: there are no `android/` or `ios/` directories, no method channels, and no platform code. Do not add any.

## Dependencies and SDK constraints
- Dart SDK: `>=3.11.0 <4.0.0`; Flutter: `>=3.3.0` (from `pubspec.yaml`).
- Runtime dependencies: **none**. Do not add a third-party runtime dependency; use `ValueNotifier` / `InheritedWidget` / `dart:js_interop` instead.
- Dev dependencies: `flutter_test`, `flutter_lints` (v6). Keep the caret (`^`) constraint style on pub dependencies (Dependabot `versioning-strategy: increase` preserves it); do not pin exact versions without reason.
- License: MPL-2.0 (Mozilla Public License 2.0). Do not relicense without the maintainer's explicit decision.
- How features work: window width is classified from `MediaQuery` (falling back to the layout constraints) into compact / medium / expanded; the delegate owns per-tab match stacks; compact / medium render a pages-based `Navigator` (so `PopScope`, `LocalHistoryEntry` sheets and Android predictive back work for free), expanded renders `SlidingPanes` over the last two matches; fullscreen / fullscreenDialog leaves are split into a root overlay navigator that covers the shell; imperative pops sync through `Navigator.onDidRemovePage`, system back goes through `RouterDelegate.popRoute`.

## Coding conventions
- Follow `effective_dart`; style is enforced by `flutter analyze` / `flutter_lints` (v6) in CI.
- Bilingual (EN-primary, ZH-secondary) doc comments on all public classes, methods and properties.
- Use Conventional Commits for both commit messages AND PR titles: `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`, `build:`, `ci:`, `chore:`, `revert:`.
- Do not break the public API without a major version bump.
- All public symbols are exported from the barrel `lib/zero_adaptive_link.dart` only.

## Workflows

### Branching and PRs
- Branch from `main` with a typed prefix: `feat/`, `fix/`, `docs/`, `ci/`, `chore/`, etc.
- Never push directly to `main`; it is branch-protected and requires 3 passing status checks to merge.
- PR titles MUST follow Conventional Commits, enforced by `pr-title-check.yml` (`amannn/action-semantic-pull-request@v6`).
- Required checks before merge: `Analyze & Test`, `Pana Score Check`, `Check PR Title (Conventional Commits)`.

### Pull request body template / PR 正文模板

AI coding agents (CodeBuddy, Trae, Cursor, Claude Code, GitHub Copilot, Codex, etc.) and contributors SHOULD follow the body template below when opening PRs. Keep the `###` section structure; fill in real content. Use English as the primary language and Chinese as the secondary language (EN-primary, ZH-secondary) for each section. Brand the assistant with **Zero Buddy** (two words, NOT "ZeroBuddy") at the end.

AI 协作工具（CodeBuddy、Trae、Cursor、Claude Code、GitHub Copilot、Codex 等）与贡献者开 PR 时应遵循以下正文模板。保留 `###` 章节结构并填入真实内容。每个章节采用英文为主、中文为辅（EN-primary, ZH-secondary）。文末以 **Zero Buddy**（两个单词，不要写成 "ZeroBuddy"）署名。

```markdown
### Summary / 摘要

<one-line plain-English summary> + <对应中文一句话摘要>

### Changes / 变更

- <change bullet, EN> / <中文说明>
- <change bullet, EN> / <中文说明>

### Context / 背景

<why this change is needed, EN> / <改动背景的中文说明>

### Checklist / 检查项

- [ ] Title follows Conventional Commits / 标题符合约定式提交
- [ ] CI checks pass after merge / 合入后 CI 通过

## Test plan

- [ ] <how to verify, EN> / <验证方式>

🤖 Generated with [Zero Buddy](https://www.zerolabsco.com)
```

Notes / 说明:
- The PR **title** stays English-only and MUST follow Conventional Commits (enforced by `pr-title-check.yml`). Bilingual content goes in the body only.
  PR **标题**仅用英文，且必须符合约定式提交（`pr-title-check.yml` 强制校验）。双语内容只放在正文。
- For Dependabot PRs, do NOT author the body manually — `dependabot-pr-bilingual.yml` auto-appends the bilingual summary (see CI section).
  Dependabot 的 PR 不要手动写正文，由 `dependabot-pr-bilingual.yml` 自动追加双语摘要（见 CI 段）。

### CI
- `ci.yml`: `actions/checkout@v7`, `subosito/flutter-action@v2`, `actions/cache@v6` (pub cache keyed on `pubspec.lock` plus `example/pubspec.lock`); runs `dart format --set-exit-if-changed lib/`, `flutter analyze lib/`, `flutter test`, `dart run tool/check_release.dart`, the example's format / analyze, and a `pana` score check (>= 120).
- `pub-publish.yml`: on a `vX.Y.Z` tag, reuses `ci.yml` as a prerequisite, verifies `pubspec.yaml` version and the `CHANGELOG.md` entry, runs `dart pub publish --dry-run`, publishes via `k-paxian/dart-package-publisher@v1.6` (secret `PUB_CREDENTIALS_JSON`), and creates a GitHub Release from the CHANGELOG entry.
- `docs.yml`: on `main` pushes touching `website/**` or `pubspec.yaml`, builds the Nextra site (`npm ci` + `node website/scripts/sync-docs.mjs --ci`) and force-orphan-publishes `website/out/` to the root of the `gh-pages` branch (`actions/setup-node@v7`, node 22, `peaceiris/actions-gh-pages@v4`).
- `dart-format-fix.yml`: on PR `opened`/`synchronize`/`reopened` (and `workflow_dispatch`), runs `dart format .` and auto-commits fixes back to the same PR branch as `style: auto-format with dart format`.
- `dependabot-pr-bilingual.yml`: `actions/github-script@v9` appends a bilingual (EN-primary, ZH-secondary) summary to the **body** of Dependabot PRs only (`github.actor == 'dependabot[bot]'`, idempotent via marker). It does NOT touch the PR title or commit subject.
- `link-check.yml`: on PR changes to `README.md`, `README_zh.md`, `CHANGELOG.md` (and `workflow_dispatch`), runs `lychee-action@v2` to scan those docs for dead/broken links. `website/pages/` is deliberately **not** scanned (Nextra route links are false positives; the site build validates them).
- `pr-title-check.yml` details: allowed types are `feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert`; `requireScope` is `false`; PRs labeled `dependencies` or `github-actions` are ignored.
- `stale.yml`: `actions/stale@v11` marks stale issues/PRs (60 days stale / 7–14 days close).
- `example-build.yml`: manual-only (`workflow_dispatch`) `flutter build web` of the example on ubuntu — the regression check that the demo still compiles against the public API. NOT a required status check.
- `paths-ignore` skips pure assets/non-package files (images, `**.txt`, `**.gitignore`, `LICENSE`, example build artifacts, etc.) but it MUST NOT blanket-ignore all `**.md` or `docs/**`. `README*.md`, `CHANGELOG.md`, `CONTRIBUTING.md` and any other markdown are intentionally **kept OUT of `paths-ignore`** so docs-only PRs still trigger the `ci.yml` workflow — otherwise the entire workflow would be skipped and the branch-protection required checks would never appear (yellow), blocking merge.
- Whether a triggered run actually executes the heavy jobs is decided by the `path-filter` job's `code` output:
  - The `code` list contains **only code paths** (`lib/**`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `test/**`, `example/lib/**`, `example/pubspec.yaml`, `example/pubspec.lock`, `example/analysis_options.yaml`, `.github/workflows/ci.yml`).
  - A **docs/asset-only PR** → `code=false` → `Analyze & Test` and `Pana Score Check` **skip green**, satisfying branch protection.
  - A **docs + code PR** → `code=true` → runs the real jobs.
  - The only non-code exception kept in the `code` list is `.github/workflows/ci.yml`.
- Never reintroduce `'**.md'` or `'docs/**'` to `paths-ignore` — it would skip the whole workflow and block docs-only PRs from merging.

### Release and publish
1. Bump `version` in `pubspec.yaml` (semver; major bump for breaking public API).
   **Mandatory version-bump checklist — every one of these MUST be updated to the new version `X.Y.Z` (and the old version string removed):**
   - [ ] `pubspec.yaml` → `version: X.Y.Z`
   - [ ] `README.md`:
     - [ ] the `^X.Y.Z` dependency constraint in the install snippet
     - [ ] the `` `X.Y.Z` `` placeholder in "install from GitHub" (replace `X.Y.Z` with the version you need)
     - [ ] the `ref: release/vX.Y.Z` in the GitHub install git block (use the `release/vX.Y.Z` archive **branch**, NOT the `vX.Y.Z` tag — the tag collides with branch refspec and breaks `git push`)
     - [ ] the "🔔 Upgrade recommended" callout — briefly summarize what the **current** release changed and recommend upgrading to the latest version (`^X.Y.Z`); it must **NOT** mention or reference previous versions
     - [ ] `README_zh.md`: same spots as `README.md` (`^X.Y.Z`, `` `X.Y.Z` `` placeholder, `ref: release/vX.Y.Z`, and the "🔔 推荐升级：" callout)
   - [ ] `website/pages/*.md`: the install snippet uses the `__ZAL_VERSION__` placeholder; it is auto-filled from `pubspec.yaml` by `website/scripts/sync-docs.mjs`, so bumping `pubspec.yaml` alone is enough (do NOT hardcode a version there).
   - [ ] `CHANGELOG.md`: add a new `## X.Y.Z` section at the top describing the changes.
   - **CHANGELOG bilingual format / 变更日志双语格式:** Every entry MUST be bilingual English-primary, Chinese-secondary. Do NOT use a ` / ` slash to separate the two languages — use a nested sub-bullet instead: the English description is the top-level bullet, and the Chinese translation is an indented nested bullet directly beneath it, with **no** explicit "中文：" / "EN:" label. Section headers stay bilingual as `### Added / 新增`, `### Changed / 优化`, `### Fixed / 修复`.
   - **Changelog scope rule / 变更日志范围规则:** Only changes to `lib/` (published-package runtime behavior) earn a CHANGELOG entry. Pure documentation updates (`README*.md`, `website/`, `CONTRIBUTING.md`) and `example/` changes must NOT get a CHANGELOG entry. The single exception is a **pure version-bump commit**.
   - Grep sanity check before committing: `grep -rn "old_version" README.md README_zh.md website/pages` must return NOTHING (only legitimate historical prose may remain; the `__ZAL_VERSION__` placeholder is expected and is not a real version).
   **Website (Nextra docs site):** `website/` is built by CI — `.github/workflows/docs.yml` runs `website/scripts/sync-docs.mjs --ci` whenever `website/**` or `pubspec.yaml` changes on `main`, and publishes `website/out/` to the root of the `gh-pages` branch. Version references in `website/pages/*.md` use the `__ZAL_VERSION__` placeholder, filled from `pubspec.yaml` at build time. `main` does not contain a generated `docs/` directory.
2. Locally verify before pushing:
   - `dart format .` — must report no changes.
   - `flutter analyze` — must pass with no errors.
   - `flutter test` — all unit tests green.
   - `flutter pub publish --dry-run` — confirm the package scores well on `pana` and no files are unintentionally excluded.
3. Commit on a branch, open PR, merge to `main` after the 3 required checks pass.
4. Tag (drives publishing): `git tag vX.Y.Z <commit> && git push origin vX.Y.Z`. The `vX.Y.Z` tag — NOT a branch — triggers `pub-publish.yml`. Never name a branch `vX.Y.Z`.
5. Archive branch (optional): create `release/vX.Y.Z` from the tagged commit via explicit refspec: `git push origin <commit>:refs/heads/release/vX.Y.Z`. These branches are inert and serve only as frozen snapshots.

### Pub publish validation pitfalls
`dart pub publish` (run by `pub-publish.yml`) performs validation that FAILS the build on certain warnings. Re-verify with `flutter pub publish --dry-run` before tagging.

- **Checked-in file ignored by `.gitignore`** — Pub flags any file that is BOTH in the git index AND matched by `.gitignore`. Fix by **untracking** the path (e.g. `git rm -r --cached .codebuddy`); `.pubignore` does NOT silence this check.
- **Top-level `docs/` directory** — do not reintroduce a checked-in `docs/`; the site is published to the `gh-pages` branch instead.
- **`.pubignore` usage** — keep `.codebuddy/`, `AGENTS.md`, `CONTRIBUTING.md`, `TODO.md` and `build/` out of the published tarball.

### Documentation site (GitHub Pages)
- Source content lives in `website/` (Nextra) and is the only hand-edited documentation source.
- GitHub Pages serves the **root** of the `gh-pages` branch (Source: "Deploy from a branch", branch `gh-pages`, folder `/ (root)`). This is a one-time repository setting. The branch is generated and force-pushed by CI, so never commit to it by hand.
- Live site: https://zero-labsco.github.io/zero-adaptive-link/
- Builds run in CI, not locally: pushes to `main` touching `website/**` or `pubspec.yaml` trigger `docs.yml`.
- To preview locally: `cd website && npm ci && npm run build` (output in `website/out/`), or `node website/scripts/sync-docs.mjs --ci`.
- `pubspec.yaml` has a `documentation:` field pointing to the site (rendered on pub.dev). Keep it in sync after the site URL is stable.

## New feature development checklist
- [ ] Confirm the change against `effective_dart` and the existing `lib/src/` structure.
- [ ] Expose any new public symbol through `lib/zero_adaptive_link.dart` only.
- [ ] Keep the runtime dependency list empty.
- [ ] Add or update unit / widget tests under `test/`.
- [ ] Run `dart format .`, `flutter analyze` and `flutter test` locally before pushing.
- [ ] Use a typed branch (`feat/...`) and a Conventional Commits PR title.
- [ ] Ensure the 3 required status checks pass before requesting review/merge.
- [ ] For user-facing changes, update `README.md`, `README_zh.md` and the `website/` source (the site is rebuilt and published by the `docs.yml` CI workflow once the change lands on `main`).
- [ ] For releases, bump `version` AND follow the **Mandatory version-bump checklist** above (pubspec, README.md, README_zh.md, `website/pages/*.md` via the `__ZAL_VERSION__` placeholder, CHANGELOG.md). Tag `vX.Y.Z` (triggers publish), and optionally push a `release/vX.Y.Z` archive branch via explicit refspec.
