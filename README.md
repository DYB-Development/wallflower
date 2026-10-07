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
