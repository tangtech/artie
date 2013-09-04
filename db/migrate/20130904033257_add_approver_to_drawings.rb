class AddApproverToDrawings < ActiveRecord::Migration
  def change
    add_column :drawings, :approved, :boolean, default: false
    add_column :drawings, :approver_user_id, :integer
  end
end
