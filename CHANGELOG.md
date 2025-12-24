# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.1.0] - 2025-12-24

### Added
- **Anti-Takeover Rules**: Explicit rules preventing Claude from doing work itself when tools are slow
  - New Rule #5: "Claude NEVER does the work itself"
  - Detailed WRONG vs CORRECT response table for common scenarios
  - Escalation path: wait → retry → simplify → ask user → NEVER take over
- Enhanced error handling table with "⚠️ NEVER Do This" column

### Changed
- **Refactored all task delegation scripts** with improved readability and structure:
  - `gemini-task.ps1` / `gemini-task.sh` - Better parameter names, modular functions
  - `opencode-task.ps1` / `opencode-task.sh` - Clear anti-takeover warnings in output
- Scripts now display explicit reminders: "DO NOT take over and run tests yourself!"
- Timeout errors now suggest proper escalation instead of encouraging takeover

### Fixed
- Addressed issue where Claude would bypass team structure when OpenCode was slow
- Scripts now reinforce conductor-only behavior in error messages

## [3.0.0] - 2025-12-24

### Changed
- **BREAKING**: Renamed plugin from `ai` to `conductor`
- **BREAKING**: Commands renamed from `/ai:*` to `/conductor:*`
  - `/ai:init` → `/conductor:init`
  - `/ai:check` → `/conductor:check`
  - `/ai:work` → `/conductor:work`
- Rebranded from "AI Team" to "Conductor" metaphor
- Updated all skill names:
  - `ai-team-manager` → `conductor-orchestrator`
  - `ai-team-learning` → `conductor-learning`
  - `gemini-manager` → `conductor-gemini`
  - `opencode-manager` → `conductor-opencode`

### Added
- **UI/UX Design Phase** (Phase 2): Generates detailed design specs BEFORE development
  - Color palette with hex codes
  - Typography specifications
  - Spacing system
  - Component styles
  - Responsive breakpoints
- **UI/UX Validation Phase** (Phase 6): Validates implementation AFTER QA
  - Compares final result against original specs
  - Compliance scoring (8+/10 = approved)
  - Automatic fix loop for high-impact deviations
- New workflow phases:
  - Phase 2: UI/UX Design (pre-development)
  - Phase 6: UI/UX Validation (post-QA)
- MIT License file
- Comprehensive README with badges and installation methods

## [2.3.0] - 2025-12-24

### Added
- Optional UI/UX Designer role for design review
- Design quality assessment in learning loop
- UI/UX review phase after development (now moved to validation)

## [2.2.0] - 2025-12-20

### Added
- Pre-flight checks for Gemini and OpenCode availability
- Configurable model selection via `.claude/ai-team-config.yaml`
- `/ai:init` command for initialization
- `/ai:check` command for pre-flight verification

### Changed
- Model configuration now loaded from config file
- Better error messages when tools missing

## [2.1.0] - 2025-12-15

### Added
- Multi-agent workflow with learning loop
- `ai-team-learning` skill for knowledge capture
- `/ai:work` command for automated development cycles
- Session logging and retrospectives
- Pattern and error tracking in `.claude/learnings/`

### Changed
- Enhanced workflow with QA testing via OpenCode
- Playwright MCP integration for browser testing

## [2.0.0] - 2025-12-10

### Added
- OpenCode integration for QA testing
- `ai-team-manager` skill for full team workflow
- `opencode-manager` skill for OpenCode-only delegation
- Dev ↔ QA feedback loop

### Changed
- Expanded from Gemini-only to multi-agent team

## [1.0.0] - 2025-12-01

### Added
- Initial release
- `gemini-manager` skill
- Claude as manager, Gemini as builder pattern
- Basic verification workflow

[3.0.0]: https://github.com/alchemiststudiosDOTai/conductor/compare/v2.3.0...v3.0.0
[2.3.0]: https://github.com/alchemiststudiosDOTai/conductor/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/alchemiststudiosDOTai/conductor/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/alchemiststudiosDOTai/conductor/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/alchemiststudiosDOTai/conductor/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/alchemiststudiosDOTai/conductor/releases/tag/v1.0.0
