class CreateParts < ActiveRecord::Migration
  def change
    create_table :parts do |t|
      t.string :customer_domain
      t.string :part_number
      t.string :part_revision
      t.string :part_ecn
      t.string :drawing_number
      t.string :drawing_revision
      t.string :description
      t.string :psl
      t.string :material_temperature
      t.string :material_class
      t.text :material_specification_short
      t.text :material_specification_full
      t.text :process_specification_short
      t.text :process_specification_full
      t.text :stamping_specification_full
      t.boolean :stamping_specification_psl
      t.string :stamping_type
      t.string :stamping_information
      t.attachment :attached_bom

      t.timestamps
    end
  end
end
