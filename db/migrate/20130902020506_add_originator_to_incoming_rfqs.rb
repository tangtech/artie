class AddOriginatorToIncomingRfqs < ActiveRecord::Migration
  def change
    add_column :incoming_rfqs, :originator, :string
  end
end
