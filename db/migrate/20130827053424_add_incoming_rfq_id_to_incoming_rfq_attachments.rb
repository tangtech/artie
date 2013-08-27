class AddIncomingRfqIdToIncomingRfqAttachments < ActiveRecord::Migration
  def change
    add_column :incoming_rfq_attachments, :incoming_rfq_id, :integer
  end
end
