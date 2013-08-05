class AddBranchToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :branch, :string
  end
end
