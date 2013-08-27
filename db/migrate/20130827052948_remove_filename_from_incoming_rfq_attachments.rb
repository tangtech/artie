class RemoveFilenameFromIncomingRfqAttachments < ActiveRecord::Migration
  def up
    remove_column :incoming_rfq_attachments, :filename
  end

  def down
    add_column :incoming_rfq_attachments, :filename, :string
  end
end
