class AddCustomerMaterialToIncomingRfqItems < ActiveRecord::Migration
  def change
    add_column :incoming_rfq_items, :customer_material, :boolean, default: false
  end
end
