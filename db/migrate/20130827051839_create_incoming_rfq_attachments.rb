class CreateIncomingRfqAttachments < ActiveRecord::Migration
  def change
    create_table :incoming_rfq_attachments do |t|
      t.string :filename
      t.attachment :attached_file

      t.timestamps
    end
  end
end
