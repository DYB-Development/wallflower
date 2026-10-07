# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- An install generator that copies a migration for the tasks table, each task belonging to the person who started it and optionally to an account.
- A Tasks page served under the path the host mounts the engine at, behind the host's sign-in check and in the layout the host names.
- Settings naming the host's sign-in method, current person method, current account method and layout.
