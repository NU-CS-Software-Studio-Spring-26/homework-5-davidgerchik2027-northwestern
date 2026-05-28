# Homework 5 Submission

## Part 1 & 2: Repository Configuration & Rules

* **GitHub Repository / Branch Link**: https://github.com/NU-CS-Software-Studio-Spring-26/homework-5-davidgerchik2027-northwestern/tree/hw5
* **Cursorignore Link**: https://github.com/NU-CS-Software-Studio-Spring-26/homework-5-davidgerchik2027-northwestern/blob/hw5/.cursorignore
* **AGENTS.md Link**: https://github.com/NU-CS-Software-Studio-Spring-26/homework-5-davidgerchik2027-northwestern/blob/hw5/AGENTS.md
* **Rails Conventions Rule Link**: https://github.com/NU-CS-Software-Studio-Spring-26/homework-5-davidgerchik2027-northwestern/blob/hw5/.cursor/rules/rails-conventions.mdc
* **Security Rule Link**: https://github.com/NU-CS-Software-Studio-Spring-26/homework-5-davidgerchik2027-northwestern/blob/hw5/.cursor/rules/security.mdc

---

## Part 3: Various-Mode Prompting

### 1. Ask Mode (Investigate)

**Exact Prompt Used:**
> "Where in this codebase is how the create form posts and renders errors currently implemented? Cite the exact files and line numbers. Do not propose changes."

**Cursor Results Returned:**
* **Form View Rendering:** `app/views/todos/new.html.erb` at line 5 (invokes the shared form partial).
* **Form Action Target:** `app/views/todos/_form.html.erb` at line 1 (uses `form_with(model: todo)` to build the POST request structure).
* **Controller Route Processing:** `app/controllers/todos_controller.rb` at lines 23–35 (the `create` action processing the save and handling `status: :unprocessable_content` updates).
* **Error Listing View Logic:** `app/views/todos/_form.html.erb` at lines 2–12 (checks `todo.errors.any?` and displays `error.full_message` items dynamically).

**Manual Verification:**
* [ ] *Self-Check: Open these files on your machine right now. If the code lines match exactly, type "Confirmed: All paths and line citations are correct and match my local repository." here.*

### 2. Plan Mode (Blueprint)

---
name: Todo Done Ownership
overview: Add a `done` boolean to todos, wire a toggle action, and gate it so only the creator can toggle while all authenticated users can still read.
todos:
  - id: migration
    content: Write migration to add done boolean and user_id reference to todos
    status: pending
  - id: model
    content: "Add belongs_to :user (optional: true) to Todo model"
    status: pending
  - id: controller
    content: Stamp user on create; add toggle_done action with require_owner! guard
    status: pending
  - id: routes
    content: Add member patch :toggle_done inside resources :todos
    status: pending
  - id: views
    content: Display done status and conditional toggle button in _todo partial and show view
    status: pending
  - id: fixtures
    content: Add user and done fields to todos fixtures
    status: pending
  - id: tests
    content: Add model and controller tests for done default, owner toggle, and non-owner rejection
    status: pending
isProject: false
---

# Todo Done/Ownership Plan

## Assumptions
- A `User` model and `current_user` helper already exist (from the authentication layer).
- A `users` fixture file (`test/fixtures/users.yml`) already exists with at least two records (e.g. `alice` and `bob`).

---

## Data flow

```mermaid
flowchart TD
    A["PATCH /todos/:id/toggle_done"] --> B["TodosController#toggle_done"]
    B --> C{current_user\n== todo.user?}
    C -->|"yes"| D["todo.update!(done: !todo.done)"]
    C -->|"no"| E["redirect back, alert: Forbidden"]
    D --> F["redirect to todo, notice: updated"]
```

---

## Changes

### 1. Migration — new file `db/migrate/<timestamp>_add_done_and_user_to_todos.rb`
- `add_column :todos, :done, :boolean, default: false, null: false`
- `add_reference :todos, :user, null: true, foreign_key: true`
  - `null: true` avoids breaking existing rows; a follow-up data migration can backfill if needed.

### 2. Model — [`app/models/todo.rb`](app/models/todo.rb)
- Add `belongs_to :user, optional: true`
  - Keep `optional: true` to match the nullable column; tighten to `optional: false` once all rows have an owner.

### 3. Controller — [`app/controllers/todos_controller.rb`](app/controllers/todos_controller.rb)
- In `create`, set `@todo.user = current_user` before saving.
- Add a new `toggle_done` action:
  - Calls `set_todo` (already exists as a `before_action`).
  - Calls a new private `require_owner!` guard — returns HTTP 403 / redirects with an alert if `current_user != @todo.user`.
  - Flips `@todo.done` and saves.
  - Redirects back to the todo on success.
- Add `toggle_done` to the `before_action :set_todo` list.
- Keep `done` out of `todo_params` — it must only change through `toggle_done`, not through the general update form.

### 4. Routes — [`config/routes.rb`](config/routes.rb)
- Expand the `resources :todos` block:
  ```
  resources :todos do
    member do
      patch :toggle_done
    end
  end
  ```

### 5. Views

- [`app/views/todos/_todo.html.erb`](app/views/todos/_todo.html.erb)
  - Display current done status (e.g. a checkmark or "Done"/"Pending" label).
  - Conditionally render a toggle `button_to` pointing at `toggle_done_todo_path(todo)` only when `current_user == todo.user`.

- [`app/views/todos/show.html.erb`](app/views/todos/show.html.erb)
  - Same conditional toggle button as in the partial.

### 6. Fixtures — [`test/fixtures/todos.yml`](test/fixtures/todos.yml)
- Add `user: alice` (or whatever the fixture name is) and `done: false` to both `one` and `two`.

### 7. Tests

- [`test/models/todo_test.rb`](test/models/todo_test.rb)
  - Test that a todo without a user can still be saved (`optional: true`).
  - Test that `done` defaults to `false` on a new record.

- [`test/controllers/todos_controller_test.rb`](test/controllers/todos_controller_test.rb)
  - **`toggle_done` as the owner**: PATCH to `toggle_done_todo_url(@todo)` while signed in as the owning user → asserts `todo.reload.done` flipped and redirects to the todo.
  - **`toggle_done` as a non-owner**: PATCH while signed in as a different user → asserts `todo.reload.done` unchanged and response is a redirect/403.
  - **`create` stamps the owner**: POST to `todos_url` while signed in → asserts `Todo.last.user == current_user`.
  - Update existing tests that now need a signed-in session (if `current_user` is required by the controller).

### 3. Agent Mode (Execution)

**Exact Prompt Used:**
> "Execute Step 1 of our blueprint plan. Open your terminal tool and use the Rails CLI generator to create the migration file that adds a `done` boolean (defaulting to false, null: false) and a nullable `user` reference to the todos table. Do not run the migration, just create and configure the file."

**Actions Completed Autonomously by Agent:**
1. Ran `bin/rails generate migration AddDoneAndUserToTodos done:boolean user:references` in the integrated terminal layer.
2. Manually modified the generated migration file to append the `default: false, null: false` constraints onto the `done` column and adjusted the user reference to `null: true` to prevent data collision.
3. Intentionally halted before database execution to ensure a safety verification gate.

* **Generated Migration File Link**: https://github.com/NU-CS-Software-Studio-Spring-26/homework-5-davidgerchik2027-northwestern/blob/hw5/db/migrate/20260528021039_add_done_and_user_to_todos.rb

* **Note on Local Migration Bugfix**: The initial migration failed locally due to an unfulfilled SQLite foreign key constraint on a non-existent `users` table. Fixed by setting `foreign_key: false` in the migration file to allow local schema execution without authentication infrastructure.

### 4. Bad -> Good Prompt Rewrite

* **Deliberately Bad Prompt:** "fix the bug in todos"

* **Engineered Good Prompt:**
  1. **Context:** `app/models/todo.rb` and `test/models/todo_test.rb`.
  2. **Task:** Implement a model validation that prevents a Todo title from being blank or containing only whitespace characters.
  3. **Expected vs. Actual:** Currently, saving a todo with a title of `"   "` passes validation and creates an empty row in the UI. It should instead fail validation and append an error message (`"can't be blank"`) to the `:title` attribute.
  4. **Constraints:** Use standard Rails ActiveRecord validations. Do not add external gems to the Gemfile. Keep modifications strictly isolated to the model file.
  5. **Done When:** Running `bin/rails test test/models/todo_test.rb` passes successfully with a new automated test asserting that whitespace-only titles are rejected.
