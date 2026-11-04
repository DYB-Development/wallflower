---
name: wallflower-info
description: Use to learn what wallflower offers — background tasks, task types and runners, task statuses and progress, results, and the task pages.
tools: Read
scope: background tasks — starting long-running work, following its status and progress, and getting its result
---

This local explains wallflower and the vocabulary the other two locals use. It makes no changes.

## What wallflower is

Wallflower is a Rails engine for background task tracking. A person starts long-running work, follows its status and progress, and gets its result when it finishes.

Reach for it when an app has work that runs in a background job and the person who started it needs to see how far it has got and collect what it produced. The engine provides a task list and a task page, both drawn with keystone_ui. Both update over Turbo Streams while a task runs, in a browser and in the Hotwire Native iOS app, and reload in place when they are shown again after being hidden.

## Interface

This local documents no commands, because wallflower declares none for it. The install local owns adding the gem to an app: its generators, mounting its engine, its settings and scheduling its recurring sweep. The develop local owns building on it: registering task types, writing runners, starting tasks, and reporting progress and results from a runner.

## How to use it

- To hook wallflower into an app or update it there, use `wallflower-install`.
- To add a task type or change what a task does, use `wallflower-develop`.

## Conventions

- **Task**: one run of long-running work, stored with the params, person and account it was started with.
- **Task type**: a type of task the app offers, such as an export, with a key, a title and the name of its runner class.
- **Runner**: a plain class whose `call` receives the task and does the work.
- **Person**: the record that started a task. Only that person can see the task.
- **Account**: the optional record a task belongs to. When the app names a current account, a person sees only the tasks in that account.
- **Status**: `queued`, `running`, `finished` or `failed`.
- **Progress**: rows done against a total, once the runner has set a total.
- **Result**: a file attached to the task, which its page offers as a Download button, or a link to a page in the app, which its page offers as an Open report button.
- **Refusal**: a row the runner could not take, stored with a label and a reason. A finished task's page shows rows changed, which is rows done less refusals, and lists each refusal.
- **Failed**: the status of a task whose runner raised an error, or of a running task with no update for longer than the stall limit, which is one hour by default. The task keeps a message saying why.
- **Sweep**: the recurring job that marks stalled tasks as failed and, when a retention period is set, deletes tasks that ended longer ago than that period.
