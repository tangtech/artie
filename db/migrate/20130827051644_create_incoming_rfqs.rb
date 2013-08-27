class CreateIncomingRfqs < ActiveRecord::Migration
  def change
    create_table :incoming_rfqs do |t|
      t.string :from
      t.text :subject
      t.text :text_body
      t.text :html_body

      t.timestamps
    end
  end
end
