class AddApproverToParts < ActiveRecord::Migration
  def change
    add_column :parts, :approved, :boolean, default: false
    add_column :parts, :approver_user_id, :integer
  end
end
