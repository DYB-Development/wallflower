# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.1.0] - 2026-10-07

### Added
- An install generator that copies a migration for the tasks table, each task belonging to the person who started it and optionally to an account.
- A Tasks page served under the path the host mounts the engine at, behind the host's sign-in check and in the layout the host names.
- Settings naming the host's sign-in method, current person method, current account method and layout.
- `Wallflower.register_kind` registers a kind of task by its key, title and runner class name, and an app whose runner class does not exist fails to boot.
- `Wallflower.start` returns a queued task and enqueues the job that marks it running, calls its runner, and marks it finished with the time it finished.
- A runner reports progress with `task.set_total` and `task.advance`.
- A runner attaches a result file with `task.attach_result`, a finished task's page offers a Download button, and the file goes only to the person who started the task.
- A task page shows the person who started it the kind's title, the task's status and a progress bar of done against total, updated live over Turbo Streams, and answers anyone else with not found.
