class AddUserTypesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :internal_user, :boolean, default: false
    add_column :users, :internal_user_part_approver, :boolean, default: false
    add_column :users, :internal_user_rfq_approver, :boolean, default: false
  end
end
