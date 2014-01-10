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

ActiveRecord::Schema.define(:version => 20140110031857) do

  create_table "organization_hosts", :force => true do |t|
    t.integer  "organization_id", :null => false
    t.string   "host",            :null => false
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "organization_hosts", ["host"], :name => "index_organization_hosts_on_host", :unique => true

  create_table "organizations", :force => true do |t|
    t.string   "name"
    t.string   "code",                         :null => false
    t.boolean  "active",     :default => true, :null => false
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  add_index "organizations", ["code"], :name => "index_organizations_on_code", :unique => true

end
