# Wallflower

Background task tracking for Rails apps: a person starts long-running work, follows its status and progress, and gets its result when it finishes.

## Installation

Add the gem and run its install generator, which copies the migrations for its tables and a Stimulus controller to `app/javascript/controllers/wallflower/catch_up_controller.js`:

```ruby
gem "wallflower"
```

```bash
bundle install
bin/rails generate wallflower:install
bin/rails db:migrate
```

After updating the gem, run its update generator to copy any migrations added since it was installed and the latest copy of its Stimulus controller, then migrate:

```bash
bin/rails generate wallflower:update
bin/rails db:migrate
```

Mount the engine at the path its pages should live under:

```ruby
mount Wallflower::Engine => "/background"
```

## Configuration

Every setting has a default, so set only what differs in your app:

```ruby
Wallflower.configure do |config|
  config.authentication_method = :authenticate_user! # runs before every Wallflower page
  config.current_person_method = :current_user       # returns the person who starts and views tasks
  config.current_account_method = nil                # returns the account a task belongs to, when there is one
  config.layout = "application"                      # the layout Wallflower's pages are drawn in
end
```

## Kinds and runners

A kind is a type of task the app offers, such as an export. Register each one in an initializer with its key, its title and the name of its runner class:

```ruby
Wallflower.register_kind :export_transactions, title: "Export transactions", runner: "ExportTransactionsRunner"
```

An app whose registered runner class does not exist fails to boot, with a message naming the class.

A runner is a plain class whose `call` receives the task. The task carries the `params`, `person` and `account` it was started with, and the runner reports progress on it while it works:

```ruby
class ExportTransactionsRunner
  def call(task)
    rows = Transaction.where(month: task.params["month"])
    task.set_total(rows.count)
    rows.find_each { |row| export(row); task.advance }
  end
end
```

A runner that produces a file attaches it as the task's result:

```ruby
task.attach_result(io: StringIO.new(csv), filename: "transactions.csv")
```

A runner whose result is a page in the app, such as a report, links the task to it:

```ruby
task.link_result(console_report_path(report))
```

A finished task's page then offers an Open report button. The page itself stays the app's to draw.

A runner that works through rows can refuse one it cannot take, with a label for the row and a reason:

```ruby
task.refuse(label: "Row 4", reason: "Amount is missing")
```

Call `task.advance` for every row, refused or not. `advance` saves at most once a second, so calling it for every row of a large task does not slow it down, and the final count is saved when the task finishes. A finished task's page shows how many rows were changed (rows done less rows refused) and how many were refused, and lists each refused row with its reason.

A finished task's page then offers a Download button. The file is sent through Wallflower's own route, which gives it only to the person who started the task and answers anyone else with not found.

## Starting a task

```ruby
task = Wallflower.start(kind: :export_transactions, person: current_user, account: current_account, params: { "month" => "2026-10" })
```

The task is returned queued and its job is enqueued. When the job runs, the task is marked running, its runner is called, and when the runner returns the task is marked finished with the time it finished.

## When a task finishes

Set `on_finish` to run code once with the task when it finishes, such as sending the person a notification through the app's own notification system:

```ruby
Wallflower.configure do |config|
  config.on_finish = ->(task) { TaskFinishedNotifier.with(task: task).deliver(task.person) }
end
```

With no `on_finish` set, tasks still run to the end.

## When a task fails

A runner that raises marks its task failed. The task keeps the error's message, its page shows it beside how far the task got, the error is reported through `Rails.error`, and `on_finish` runs once with the failed task.

A task still running with no update for longer than `stall_after`, one hour by default, is marked failed by `Wallflower::SweepJob`, with a reason saying it stalled. Schedule the sweep the way the app schedules any recurring job, for example in Solid Queue's `config/recurring.yml`:

```yaml
production:
  wallflower_sweep:
    class: Wallflower::SweepJob
    schedule: every 10 minutes
```

```ruby
Wallflower.configure do |config|
  config.stall_after = 30.minutes
  config.keep_for = 90.days # unset by default, which keeps every task forever
end
```

With `keep_for` set, the same sweep deletes each finished or failed task that ended longer ago than that, with its file and its refused rows. Queued and running tasks stay, however old. With it unset, nothing is ever deleted.

## The task list

The engine's root lists the tasks the signed-in person started in the current account, newest first. Each row shows the kind's title, the status as a coloured badge, the progress and when it was started, links to the task's page, and updates while the task runs.

## The task page

A task's page lives at `tasks/:id` under the engine's mount path. The person who started the task sees its kind's title, its status and, once the runner has set a total, a progress bar of done against total. The page listens for changes to its task over Turbo Streams, so its status and progress update without a reload, in a browser and in the Hotwire Native iOS app alike. Anyone else, and the same person viewing from another account, gets a not-found response.

The task page and the task list reload in place when they are shown again after being hidden, such as when the iOS app returns from the background, so they show changes broadcast while they could not receive them. A page that stays visible makes no extra request. The copied controller is registered by the host's own Stimulus setup, as `wallflower--catch-up`.

Wallflower's pages are drawn with keystone_ui, and live updates need Action Cable and turbo-rails, which the host's layout already loads for Turbo Streams.
