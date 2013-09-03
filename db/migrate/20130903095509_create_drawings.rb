class CreateDrawings < ActiveRecord::Migration
  def change
    create_table :drawings do |t|
      t.string :customer_domain
      t.string :drawing_number
      t.string :drawing_revision
      t.string :shape
      t.float :round_outside_diameter
      t.float :round_inside_diameter
      t.float :round_length
      t.float :flat_length
      t.float :flat_width
      t.float :flat_thickness
      t.string :dimension_unit
      t.float :weight
      t.string :weight_unit
      t.text :threads
      t.attachment :attached_drawing

      t.timestamps
    end
  end
end
