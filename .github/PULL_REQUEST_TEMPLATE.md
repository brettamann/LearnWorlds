## Summary

<!-- 1–3 bullet points on what changed and why. -->

## Areas touched

- [ ] Spec (`specs/`)
- [ ] Schema (`schemas/`)
- [ ] Data file (`data/` or `content/`)
- [ ] App code (`app/lib/`)
- [ ] Tooling (`tools/`)
- [ ] CI / workflow

## Checklist

- [ ] Specs updated to reflect any behavioral changes
- [ ] Schema(s) updated if data shape changed
- [ ] Lint + format clean (`dart format`, `flutter analyze`)
- [ ] Tests added/updated where applicable
- [ ] Schema validation passes (`tools/scripts/validate-data.sh` when available)
- [ ] TTS harvester still parses cleanly if narration touched
- [ ] No assets/audio committed without art-direction review (per `specs/shared/art-direction.md`)
