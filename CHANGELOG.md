# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- `Connect-AppExpiry` — interactive and app-only (certificate) auth against Microsoft Graph
- `Get-AppExpiry` — reports client secret / certificate expiry for Entra ID app registrations, with `-ExpiringInDays` and `-IncludeExpired` filters
- `Export-AppExpiryReport` — CSV/HTML export
- CI (Pester + PSScriptAnalyzer) and PowerShell Gallery publish workflows
