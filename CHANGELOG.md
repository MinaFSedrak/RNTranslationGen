# Changelog

## [1.2.0] - 2025-02-27
### Added
- Support for YAML and JSON config files (`rn-translation-gen.yml` & `rn-translation-gen.json`).
- Improved example section in the README with a multi-screen app structure.
- Enhanced nested translation key generation.

### Changed
- Updated shell scripts to support flexible input/output paths.

## [1.1.0] - 2025-02-19
### Added
- Support for `--input` and `--output` arguments in the shell script.
- Improved error handling and directory validation.

### Changed
- `TRANSLATION_KEYS` now stored in `translations.ts` instead of `translations.d.ts` to prevent TypeScript errors.

### Fixed
- Better directory checks to prevent missing file errors.
