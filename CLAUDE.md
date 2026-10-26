# CLAUDE.md

@AGENTS.md

The file above is the full engineering standard for this repo (Clean Architecture + Bloc + Supabase + GetIt, exactly as the
professor teaches it). Read it as if it were written here. Deeper material, load on demand:

- `docs/standards/code-templates.md` — canonical Dart for every layer (entity → contract → data source → repo impl → use case → bloc → screen → DI → tests).
- `docs/standards/supabase-and-data.md` — Auth, migrations, queries, Storage, Realtime rules.
- `docs/standards/course-reference.md` — which lesson/lab teaches what, and how to refresh the professor's repos.
- `docs/design/03-design-system.md` — the VIGÍA design system (brand, tokens, components, Spanish copy deck); mockups in `docs/design/mockups/`.
- `docs/` (business rules, screens, decisions) and `data model/schema.sql` — domain truth for VIGÍA. Check them before inventing fields.

## Claude Code specifics

**Commands** (run from the repo root, Windows/PowerShell):

```bash
flutter pub get
flutter analyze                      # must be clean before you say "done"
flutter test                         # whole suite (offline, no Supabase needed)
flutter test test/unit/domain/       # one folder
flutter run -d chrome                # or -d windows / -d <android device>
```

**Workflow**
- Before touching a feature, state which layer each new file belongs to. For anything larger than one file, plan first
  (list files in build order: domain → data → use cases → bloc → screen → DI → tests) and let the user confirm.
- Prefer the dedicated tools (Read/Grep/Glob/Edit) over shell. Keep diffs small and focused; one concern per change.
- After editing, run the **pre-completion checklist** in `AGENTS.md` §11 (the `grep` guards + `flutter analyze` + `flutter test`)
  and report the real output.
- When the user is learning a layer, explain the "why" in two or three sentences and keep the code minimal; the course style is
  deliberately simple (no Freezed/codegen/`dartz`/`Either`/extra abstractions such as `BaseUseCase`, `Params` classes, or `Failure` hierarchies).
- If the request conflicts with the course standard, say so, recommend the course way, and let the user decide.
- Reply in Spanish when the user writes Spanish; code, comments, commits and docs stay in English.
- Never run `git commit`, `git push`, `git tag`, or create PRs unless asked. Sprint deliverables (tag, demo video, README flow
  instructions) are the student's to trigger — offer, don't assume.
- **Visual design is a system, not taste:** before touching any widget read `docs/design/03-design-system.md` (rules in `AGENTS.md` §6b)
  and look at `docs/design/mockups/*.html`. Tokens only, shared widgets first, Spanish copy, light and dark, and update the design
  document in the same change when the system evolves. The web rules in `.antigravity/rules/` are superseded.

## Keeping this up to date

If the professor changes a convention (new lab, new lesson), update `AGENTS.md` and `docs/standards/` in the same change and note the
source lesson file. If you find yourself explaining the same correction twice, it belongs in `AGENTS.md`.
