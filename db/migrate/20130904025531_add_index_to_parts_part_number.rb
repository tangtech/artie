class AddIndexToPartsPartNumber < ActiveRecord::Migration
  def change
    add_index :parts, [:part_number, :part_revision], unique: true
  end
end
