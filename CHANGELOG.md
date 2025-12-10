# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-12-10

### Added
- Ruby 3.x support while maintaining backward compatibility with Ruby 2.7.2+
- CI/CD testing across multiple Ruby versions (2.7.6, 3.0, 3.1.4, 3.2, 3.3)
- This CHANGELOG file to track project changes

### Changed
- Updated development dependencies to latest versions for Ruby 3.x compatibility
- Improved test compatibility by replacing Rails-specific matchers with pure Ruby alternatives

### Fixed
- Test failures related to `be_blank` matcher incompatibility with pure Ruby

### Milestone
- **First stable release (1.0.0)** - Marking API stability and Ruby 3.x support

## [0.7.3] - Previous Release

### Added
- PIX payment functionality
- Collection order management
- Dynamic QR code generation
- Payment order processing
- Payout operations
- Refund capabilities
- Account limit management

### Features
- FitBank REST API wrapper classes
- Comprehensive entity models
- Error handling and validation
- VCR cassettes for testing
- Factory Bot test factories
- SimpleCov code coverage

[Unreleased]: https://github.com/latamgateway/fitbank_api/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/latamgateway/fitbank_api/compare/v0.7.3...v1.0.0
[0.7.3]: https://github.com/latamgateway/fitbank_api/releases/tag/v0.7.3