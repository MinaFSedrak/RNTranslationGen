# Changelog

## [1.5.0] - 2025-12-09

### Added

- New `--noEmit` flag to verify types without generating files (similar to `tsc --noEmit`).
- New `--help` and `-h` flags for built-in documentation.
- Type validation mode that compares generated types against existing files.
- Updated README with `--noEmit` usage examples and CI/CD pipeline use case.
- Perfect for detecting out-of-sync translations in CI/CD pipelines.

### Changed

- Enhanced error messages for type validation failures.
- Renamed generated files from `translations.d.ts` and `translations.ts` to `translations.types.d.ts` and `translations.types.ts` for better clarity.

## [1.4.2] - 2025-12-09

### Added

- Config file support for `excludeKey` and `disableEslintQuotes` flags.
- JSON config now supports: `excludeKey` and `disableEslintQuotes` properties.
- YAML config now supports: `excludeKey` and `disableEslintQuotes` properties.
- Updated README with complete config file examples.

### Changed

- Config files can now fully replace CLI arguments for all options.

## [1.4.1] - 2025-12-09

### Added

- Enhanced package.json metadata with `main`, `files`, and improved `bin` configuration.
- Better npm package structure for improved module resolution.

## [1.4.0] - 2025-12-09

### Added

- New `--disable-eslint-quotes` CLI flag to control eslint quote disabling in generated files.
- Updated shell script to support the `--disable-eslint-quotes` option.
- Updated README with usage instructions and documentation for the new flag.

### Changed

- Default behavior now generates files without `/* eslint-disable quotes */` comments.
- To include eslint disable comments, use the `--disable-eslint-quotes` flag.

## [1.3.0] - 2025-03-01

### Added

- New `--exclude-key` CLI option to unwrap and exclude a top-level key (e.g., `"translation"`) from JSON before generating types.
- Updated shell script to support the `--exclude-key` option.
- Updated README with usage instructions for the new `--exclude-key` feature.

## [1.2.1] - 2025-02-27

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
