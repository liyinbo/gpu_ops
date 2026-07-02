# Documentation

Documentation is organized by ownership boundary.

## Platform

Shared GPU cluster operations live under `doc/platform/`.

- `doc/platform/requirements.md`
- `doc/platform/implement-roadmap.md`
- `doc/platform/implement-status.md`
- `doc/platform/test-cases.md`
- `doc/platform/runbooks/`

## Tasks

Each task owns its own control documents and runbooks under `doc/tasks/<task>/`.

Required task control documents:

- `requirements.md`
- `implement-roadmap.md`
- `implement-status.md`
- `test-cases.md`

Current tasks:

- `doc/tasks/tts/` - realtime TTS serving, streaming synthesis, and voice clone workloads.
