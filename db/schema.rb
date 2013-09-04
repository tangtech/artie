# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130904040445) do

  create_table "customers", :force => true do |t|
    t.string   "name"
    t.string   "short_name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "domain"
    t.string   "branch"
  end

  create_table "drawings", :force => true do |t|
    t.string   "customer_domain"
    t.string   "drawing_number"
    t.string   "drawing_revision"
    t.string   "shape"
    t.float    "round_outside_diameter"
    t.float    "round_inside_diameter"
    t.float    "round_length"
    t.float    "flat_length"
    t.float    "flat_width"
    t.float    "flat_thickness"
    t.string   "dimension_unit"
    t.float    "weight"
    t.string   "weight_unit"
    t.text     "threads"
    t.string   "attached_drawing_file_name"
    t.string   "attached_drawing_content_type"
    t.integer  "attached_drawing_file_size"
    t.datetime "attached_drawing_updated_at"
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
    t.boolean  "approved",                      :default => false
    t.integer  "approver_user_id"
  end

  add_index "drawings", ["drawing_number", "drawing_revision"], :name => "index_drawings_on_drawing_number_and_drawing_revision", :unique => true

  create_table "incoming_rfq_attachments", :force => true do |t|
    t.string   "attached_file_file_name"
    t.string   "attached_file_content_type"
    t.integer  "attached_file_file_size"
    t.datetime "attached_file_updated_at"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.integer  "incoming_rfq_id"
  end

  create_table "incoming_rfq_items", :force => true do |t|
    t.integer  "incoming_rfq_id"
    t.string   "part_number"
    t.string   "description"
    t.integer  "quantity"
    t.date     "required_delivery_date"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.boolean  "customer_material",      :default => false
  end

  create_table "incoming_rfqs", :force => true do |t|
    t.string   "from"
    t.text     "subject"
    t.text     "text_body"
    t.text     "html_body"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "originator"
  end

  create_table "parts", :force => true do |t|
    t.string   "customer_domain"
    t.string   "part_number"
    t.string   "part_revision"
    t.string   "part_ecn"
    t.string   "drawing_number"
    t.string   "drawing_revision"
    t.string   "description"
    t.string   "psl"
    t.string   "material_temperature"
    t.string   "material_class"
    t.text     "material_specification_short"
    t.text     "material_specification_full"
    t.text     "process_specification_short"
    t.text     "process_specification_full"
    t.text     "stamping_specification_full"
    t.boolean  "stamping_specification_psl"
    t.string   "stamping_type"
    t.string   "stamping_information"
    t.string   "attached_bom_file_name"
    t.string   "attached_bom_content_type"
    t.integer  "attached_bom_file_size"
    t.datetime "attached_bom_updated_at"
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
    t.boolean  "approved",                     :default => false
    t.integer  "approver_user_id"
  end

  add_index "parts", ["part_number", "part_revision"], :name => "index_parts_on_part_number_and_part_revision", :unique => true

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.string   "password_digest"
    t.string   "remember_token"
    t.boolean  "admin",                       :default => false
    t.boolean  "internal_user",               :default => false
    t.boolean  "internal_user_part_approver", :default => false
    t.boolean  "internal_user_rfq_approver",  :default => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["remember_token"], :name => "index_users_on_remember_token"

end
