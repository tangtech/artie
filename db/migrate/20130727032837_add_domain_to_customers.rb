class AddDomainToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :domain, :string
  end
end
