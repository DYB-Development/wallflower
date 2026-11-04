---
name: wallflower-develop
description: Use PROACTIVELY for adding long-running work that a person starts and follows in a Rails app, such as an export or a report, including registering the kind of task, writing its runner, starting it, reporting progress, attaching a result file, linking a result page and refusing rows — MUST BE USED instead of hand-rolling a background job with its own status column, progress tracking, status page or file download.
tools: Bash, Read, Write, Edit, Grep
scope: background tasks — starting long-running work, following its status and progress, and getting its result
---

This local implements background tasks with Wallflower. It always registers a kind, writes the kind's runner, and starts the task through `Wallflower.start`, asking the developer each decision listed below before writing code.

## What wallflower is

Wallflower tracks long-running work in a Rails app: a person starts a task, follows its status and progress on pages the gem provides, and gets its result when it finishes. Use this local when the app needs work that runs in the background and a person needs to see how it went.

## Interface

- `Wallflower.register_kind` — `Wallflower.register_kind(key, title:, runner:)` registers a type of task, with its key, the title people see, and the name of its runner class.
- `Wallflower.start` — `Wallflower.start(kind:, person:, account: nil, params: {})` creates a queued task, enqueues its job, and returns the task.
- `set_total` — `task.set_total(total)` saves the number of rows the task will work through.
- `advance` — `task.advance(by = 1)` adds to the rows done, saving at most once a second.
- `attach_result` — `task.attach_result(io:, filename:)` attaches a file as the task's result.
- `link_result` — `task.link_result(url)` saves the address of a page as the task's result.
- `refuse` — `task.refuse(label:, reason:)` records a row the runner could not take, with a label for the row and a reason.

## How to use it

1. Ask the developer these before writing code:
   - What is the kind's key, its title, and its runner's class name?
   - Who is the person who starts the task, and does it belong to an account?
   - What are the task's params?
   - Does the task work through rows, and can a row be refused?
   - Is the result a file, a page in the app, both, or nothing?
   - Where does the person go after starting the task?

2. Register the kind in an initializer:

   ```ruby
   Wallflower.register_kind :export_transactions, title: "Export transactions", runner: "ExportTransactionsRunner"
   ```

3. Write the runner as a class in the app. Wallflower calls `new` on it with no arguments, then `call` with the task. The app fails to boot, with a message naming the class, if the registered class does not exist.

   ```ruby
   class ExportTransactionsRunner
     def call(task)
       rows = Transaction.where(month: task.params["month"])
       task.set_total(rows.count)
       rows.find_each { |row| export(row); task.advance }
     end
   end
   ```

   The task is the only thing the runner receives. It carries `params`, `person` and `account` as they were passed to `Wallflower.start`.

4. For a task that works through rows, call `set_total` before the first row and `advance` for every row, refused or not:

   ```ruby
   task.refuse(label: "Row 4", reason: "Amount is missing")
   task.advance
   ```

   The page shows a progress bar only once a total is set, and a time-left estimate only while the task is running and at least five percent done. A finished task's page shows rows changed as rows done less rows refused, and lists each refused row with its reason. It shows `0 changed, 0 refused` for a runner that never calls `advance`.

5. Have the runner record the task's result, according to the developer's answer:
   - For a file, call `task.attach_result(io: StringIO.new(csv), filename: "transactions.csv")`. A finished task's page offers a Download button.
   - For a page in the app, call `task.link_result(address)`. A finished task's page offers an Open report button pointing at that address as given. The page itself is the app's to draw, and Wallflower adds no route helpers to the runner.

6. Start the task from the app's own code, passing params as a hash with string keys, since they are stored in a JSON column:

   ```ruby
   task = Wallflower.start(kind: :export_transactions, person: current_user, account: current_account, params: { "month" => "2026-10" })
   ```

   `person` is required and `account` is optional. `start` does not check that the kind is registered. The runner runs when the job runs, not during this call.

7. Send the person to the task. Its page is at `tasks/:id` under the path where the engine is mounted, and the list of tasks is at the root of that path.

## Conventions

- Pass the same person the app treats as the current person, since the task list, the task page and the download answer only that person.
- When the app has a current account configured, pass that same account, since those pages then show only tasks in that account and a task started with another account or none does not appear.
- The job sets the task's status, so a runner never sets it. The task is marked running before the runner is called and finished when the runner returns.
- To fail a task, let a `StandardError` leave the runner. The task is marked failed, its message is stored and shown to the person on the task's page, and the error is reported through `Rails.error`. Write that message for the person reading it, and do not rescue an error the person needs to see, since a runner that returns marks the task finished.
- A running task with no update for longer than the app's stall time, one hour by default, can be marked failed as stalled. Call `advance` or `set_total` often enough that a slow step does not reach that time.
- Installing the gem, setting up its pages, its configuration, code that runs when a task finishes, and scheduling stalled-task checks and old-task deletion are out of scope. They belong to the install local.
