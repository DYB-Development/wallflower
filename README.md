# Wallflower

Background task tracking for Rails apps: a person starts long-running work, follows its status and progress, and gets its result when it finishes.

## Installation

Add the gem and run its install generator, which copies a migration for its tasks table:

```ruby
gem "wallflower"
```

```bash
bundle install
bin/rails generate wallflower:install
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

## Starting a task

```ruby
task = Wallflower.start(kind: :export_transactions, person: current_user, account: current_account, params: { "month" => "2026-10" })
```

The task is returned queued and its job is enqueued. When the job runs, the task is marked running, its runner is called, and when the runner returns the task is marked finished with the time it finished.

## The task page

A task's page lives at `tasks/:id` under the engine's mount path. The person who started the task sees its kind's title, its status and, once the runner has set a total, a progress bar of done against total. The page listens for changes to its task over Turbo Streams, so its status and progress update without a reload, in a browser and in the Hotwire Native iOS app alike. Anyone else, and the same person viewing from another account, gets a not-found response.

Wallflower's pages are drawn with keystone_ui, and live updates need Action Cable and turbo-rails, which the host's layout already loads for Turbo Streams.
