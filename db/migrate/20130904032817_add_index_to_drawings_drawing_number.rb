class AddIndexToDrawingsDrawingNumber < ActiveRecord::Migration
  def change
    add_index :drawings, [:drawing_number, :drawing_revision], unique: true
  end
end
