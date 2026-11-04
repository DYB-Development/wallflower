---
name: wallflower-install
description: Use to hook wallflower into a project — adding the gem, running its install and update generators, mounting its engine, configuring it, and scheduling its sweep job.
tools: Bash, Read, Edit
scope: background tasks — starting long-running work, following its status and progress, and getting its result
---

This local follows these steps exactly and invents none. Where a step says to ask the developer, it asks and does not pick.

## What wallflower is
A Rails engine for background task tracking: hook it in when a person in the app starts long-running work, follows its status and progress, and gets its result when it finishes.

## Interface
- `bin/rails generate wallflower:install` — copies the five migrations for the gem's tables and its Stimulus controller into a new host.
- `bin/rails generate wallflower:update` — copies the four migrations that came after the tasks table and the Stimulus controller into a host that already installed the gem.
- `mount Wallflower::Engine` — serves the task list and task pages under the path the host mounts it at.
- `Wallflower.configure` — sets the host's sign-in check, person and account methods, layout, finish hook, stall limit and keep period.
- `Wallflower::SweepJob` — the recurring job that marks stalled tasks failed and deletes old tasks.

## How to use it
1. Confirm the host meets what the gem needs:
   - Ruby 3.1.0 or later, and Rails 7.0 or later.
   - An `ApplicationController`, since Wallflower's controllers inherit from it.
   - Active Job (`active_job/railtie`) with a backend that runs enqueued jobs, since each task's work and the sweep run as jobs.
   - Active Storage (`active_storage/engine`) with its tables, since each task can hold an attached result file.
   - Action Cable (`action_cable/engine`), since live updates on Wallflower's pages need it.
   - A Stimulus setup in the host, since the generators copy a Stimulus controller into it.

   The gem does not declare Active Job, Active Storage or Action Cable as dependencies. If any item is missing, stop and ask the developer how to add it.

2. Add the gem to the host's `Gemfile` and install it. This also brings in its dependencies, `keystone_ui` 0.37.0 or later and `turbo-rails` 2.0 or later.

   ```ruby
   gem "wallflower"
   ```

   ```bash
   bundle install
   ```

3. Wallflower's pages are drawn with `keystone_ui`, and these steps do not set it up in the host. Ask the developer whether `keystone_ui` is already set up in this app, and how they want it handled if it is not.

4. Run the install generator and migrate.

   ```bash
   bin/rails generate wallflower:install
   bin/rails db:migrate
   ```

   The generator writes these host files:
   - `db/migrate/*_create_wallflower_tasks.rb`
   - `db/migrate/*_create_wallflower_refusals.rb`
   - `db/migrate/*_add_result_url_to_wallflower_tasks.rb`
   - `db/migrate/*_add_error_message_to_wallflower_tasks.rb`
   - `db/migrate/*_add_started_at_to_wallflower_tasks.rb`
   - `app/javascript/controllers/wallflower/catch_up_controller.js`

5. Confirm the host's Stimulus setup registers the copied controller as `wallflower--catch-up`, the name Wallflower's pages use. The controller imports from `@hotwired/stimulus` and calls `Turbo.visit` on the window.

6. Ask the developer which path Wallflower's pages should live under, then mount the engine at that path in `config/routes.rb`. This example uses `/background`.

   ```ruby
   mount Wallflower::Engine => "/background"
   ```

7. Create `config/initializers/wallflower.rb` and set only the values that differ from the defaults. Ask the developer about each setting below rather than picking.

   ```ruby
   Wallflower.configure do |config|
     config.authentication_method = :authenticate_user!
     config.current_person_method = :current_user
     config.current_account_method = nil
     config.layout = "application"
     config.on_finish = ->(task) { }
     config.stall_after = 1.hour
     config.keep_for = 90.days
   end
   ```

   - `authentication_method` defaults to `:authenticate_user!`. It names a method on the host's `ApplicationController` that runs before every Wallflower page.
   - `current_person_method` defaults to `:current_user`. It names a method on the host's `ApplicationController` that returns the record of the person who starts and views tasks.
   - `current_account_method` is unset by default. Ask whether tasks belong to an account in this app. When it names a method on the host's `ApplicationController`, a person sees only their tasks in the account it returns. When it is unset, a person sees all their tasks.
   - `layout` defaults to `"application"`. It names the host layout Wallflower's pages are drawn in. That layout must load Action Cable and `turbo-rails` for live updates to work.
   - `on_finish` is unset by default. It is a callable that receives the task, and it is called when a task finishes, when a task fails, and when the sweep marks a task stalled. With it unset, tasks still run to the end.
   - `stall_after` defaults to `1.hour`. A task still running with no update for longer than this is marked failed by the sweep.
   - `keep_for` is unset by default, which keeps every task forever. When it is set, the sweep deletes each finished or failed task that ended longer ago than this, with its file and its rows in `wallflower_refusals`. Queued and running tasks stay, however old.

8. Schedule `Wallflower::SweepJob` to run on a recurring schedule. It takes no arguments. Ask the developer how this app schedules recurring jobs and how often the sweep should run. Without a schedule, stalled tasks are not marked failed and `keep_for` deletes nothing. In an app that uses Solid Queue, add this to `config/recurring.yml`:

   ```yaml
   production:
     wallflower_sweep:
       class: Wallflower::SweepJob
       schedule: every 10 minutes
   ```

## Conventions
- After install, open the mount path while signed in. The page has the heading `Tasks`.
- After updating the gem, run the update generator and migrate:

  ```bash
  bin/rails generate wallflower:update
  bin/rails db:migrate
  ```

- The update generator does not copy the migration that creates the tasks table, so a host that has not installed the gem runs the install generator instead.
- Running the update generator again adds no second copy of a migration the host already has.
- Defining the types of task an app offers, writing the classes that do the work, and starting tasks are out of scope here. They belong to the develop local.
