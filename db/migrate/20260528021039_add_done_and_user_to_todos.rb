class AddDoneAndUserToTodos < ActiveRecord::Migration[8.1]
  def change
    add_column :todos, :done, :boolean, default: false, null: false
    add_reference :todos, :user, null: true, foreign_key: true
  end
end
