class CreateIncomingRfqItems < ActiveRecord::Migration
  def change
    create_table :incoming_rfq_items do |t|
      t.integer :incoming_rfq_id
      t.string :part_number
      t.string :description
      t.integer :quantity
      t.date :required_delivery_date

      t.timestamps
    end
  end
end
