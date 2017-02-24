class AddLastVisitAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_visit_at, :timestamp
  end
end
