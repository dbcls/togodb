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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_06_20_113643) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "blank_nodes", id: :serial, force: :cascade do |t|
    t.integer "work_id"
    t.integer "class_map_id"
    t.integer "property_bridge_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "property_bridge_ids"
  end

  create_table "class_map_properties", id: :serial, force: :cascade do |t|
    t.string "property"
    t.string "label"
    t.boolean "is_literal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "class_map_property_settings", id: :serial, force: :cascade do |t|
    t.integer "class_map_id"
    t.integer "class_map_property_id"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "class_maps", id: :serial, force: :cascade do |t|
    t.integer "work_id"
    t.string "map_name"
    t.string "table_name"
    t.boolean "enable"
    t.integer "table_join_id"
    t.integer "bnode_id"
    t.integer "er_xpos"
    t.integer "er_ypos"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "db_connections", id: :serial, force: :cascade do |t|
    t.string "adapter"
    t.string "host"
    t.integer "port"
    t.string "database"
    t.string "username"
    t.integer "work_id"
    t.text "password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "namespace_settings", id: :serial, force: :cascade do |t|
    t.integer "work_id"
    t.integer "namespace_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "ontology"
    t.string "original_filename"
    t.boolean "is_ontology", default: false, null: false
  end

  create_table "namespaces", id: :serial, force: :cascade do |t|
    t.string "prefix"
    t.string "uri"
    t.boolean "is_default"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ontologies", id: :serial, force: :cascade do |t|
    t.integer "work_id"
    t.text "ontology"
    t.string "file_name"
    t.string "file_format"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "property_bridge_properties", id: :serial, force: :cascade do |t|
    t.string "property"
    t.string "label"
    t.boolean "is_literal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "property_bridge_property_settings", id: :serial, force: :cascade do |t|
    t.integer "property_bridge_id"
    t.integer "property_bridge_property_id"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "property_bridge_types", id: :serial, force: :cascade do |t|
    t.string "symbol"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "property_bridges", id: :serial, force: :cascade do |t|
    t.integer "work_id"
    t.string "map_name"
    t.integer "class_map_id"
    t.boolean "user_defined"
    t.string "column_name"
    t.boolean "enable"
    t.integer "property_bridge_type_id"
    t.integer "bnode_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", id: :serial, force: :cascade do |t|
    t.string "session_id", limit: 255, null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "table_joins", id: :serial, force: :cascade do |t|
    t.integer "work_id"
    t.integer "l_table_class_map_id"
    t.integer "l_table_property_bridge_id"
    t.integer "r_table_class_map_id"
    t.integer "r_table_property_bridge_id"
    t.integer "i_table_class_map_id"
    t.integer "i_table_l_property_bridge_id"
    t.integer "i_table_r_property_bridge_id"
    t.integer "class_map_id"
    t.integer "property_bridge_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "togodb_cc_mappings", id: :serial, force: :cascade do |t|
    t.string "licence", limit: 255
    t.string "url", limit: 255
  end

  create_table "togodb_column_values", id: :serial, force: :cascade do |t|
    t.integer "column_id"
    t.string "value", limit: 255
  end

  create_table "togodb_columns", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "internal_name", limit: 255
    t.string "data_type", limit: 255
    t.string "label", limit: 255
    t.boolean "enabled", default: true
    t.string "actions", limit: 255
    t.string "roles", limit: 255
    t.integer "position"
    t.text "html_link_prefix"
    t.string "html_link_suffix", limit: 255
    t.integer "list_disp_order"
    t.integer "show_disp_order"
    t.integer "dl_column_order"
    t.string "other_type", limit: 255
    t.string "web_services", limit: 255
    t.integer "num_decimal_places"
    t.string "comment", limit: 255
    t.integer "num_integer_digits"
    t.integer "num_fractional_digits"
    t.text "search_help1"
    t.text "search_help2"
    t.string "rdf_p_property_prefix", limit: 255
    t.string "rdf_p_property_term", limit: 255
    t.string "rdf_p_property", limit: 255
    t.string "rdf_o_class_prefix", limit: 255
    t.string "rdf_o_class_term", limit: 255
    t.string "rdf_o_class", limit: 255
    t.string "id_separator", limit: 255
    t.integer "table_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "togodb_creates", id: :serial, force: :cascade do |t|
    t.integer "table_id"
    t.text "uploded_file_path"
    t.string "file_format"
    t.boolean "header_line"
    t.integer "num_columns"
    t.text "sample_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "utf8_file_path"
    t.integer "user_id"
    t.string "mode"
  end

  create_table "togodb_data_release_histories", id: :serial, force: :cascade do |t|
    t.integer "dataset_id"
    t.datetime "released_at"
    t.datetime "submitted_at"
    t.string "status", limit: 255
    t.text "message"
    t.text "search_condition"
  end

  create_table "togodb_datasets", id: :serial, force: :cascade do |t|
    t.integer "table_id"
    t.string "name", limit: 255
    t.text "columns"
    t.boolean "all_columns"
    t.text "fasta_description"
    t.string "output_file_path", limit: 255
    t.integer "fasta_seq_column_id"
    t.text "filter_condition"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "togodb_db_metadata_dois", id: :serial, force: :cascade do |t|
    t.string "doi"
    t.integer "db_metadata_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "togodb_db_metadata_pubmeds", id: :serial, force: :cascade do |t|
    t.integer "pubmed_id"
    t.integer "db_metadata_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "togodb_db_metadatas", id: :serial, force: :cascade do |t|
    t.string "title", limit: 255
    t.text "description"
    t.text "creator"
    t.text "contributor"
    t.text "keyword"
    t.integer "creative_commons"
    t.text "licence"
    t.text "language_by_select"
    t.text "language"
    t.text "literature_reference"
    t.text "vocabulary"
    t.text "item_to_dataset_relation"
    t.text "frequency_of_change"
    t.text "agents"
    t.string "database_name", limit: 255
    t.string "email", limit: 255
    t.text "postal_mail"
    t.integer "established_year"
    t.integer "conditions_of_use"
    t.text "scope"
    t.text "standards"
    t.text "taxonomic_coverage"
    t.text "data_accessibility"
    t.text "data_release_frequency"
    t.text "versioning_period"
    t.text "documentation_available"
    t.text "user_support_options"
    t.text "data_submission_policy"
    t.text "relevant_publications"
    t.text "wikipedia_url"
    t.text "tools_available"
    t.integer "table_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "pubmed", limit: 255
    t.string "doi", limit: 255
    t.boolean "confirm_license", default: false
    t.index ["table_id"], name: "togodb_db_metadatas_table_id_key", unique: true
  end

  create_table "togodb_lexvo_mappings", id: :serial, force: :cascade do |t|
    t.string "language", limit: 255
    t.text "uri"
  end

  create_table "togodb_pages", id: :serial, force: :cascade do |t|
    t.integer "table_id"
    t.boolean "header_line", default: false
    t.integer "header_footer_lang", default: 1
    t.boolean "multiple_language", default: false
    t.text "view_css"
    t.text "view_header"
    t.text "view_body"
    t.text "quickbrowse"
    t.text "show_css"
    t.text "show_header"
    t.text "show_body"
    t.boolean "use_show_column_order", default: false
    t.boolean "disp_search_help", default: false
    t.string "search_help_lang", limit: 255, default: "1"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["table_id"], name: "togodb_pages_table_id_key", unique: true
  end

  create_table "togodb_roles", id: :serial, force: :cascade do |t|
    t.string "roles", limit: 255
    t.integer "table_id"
    t.integer "user_id"
    t.index ["table_id", "user_id"], name: "togodb_roles_table_id_user_id_key", unique: true
  end

  create_table "togodb_settings", id: :serial, force: :cascade do |t|
    t.string "label", limit: 255
    t.string "actions", limit: 255
    t.text "externals"
    t.string "html_title", limit: 255
    t.text "page_header"
    t.text "page_footer"
    t.text "html_head"
    t.integer "per_page"
    t.integer "table_id"
  end

  create_table "togodb_supplementary_files", id: :serial, force: :cascade do |t|
    t.string "original_filename"
    t.integer "togodb_table_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "json_for_file_tree"
    t.index ["togodb_table_id"], name: "index_togodb_supplementary_files_on_togodb_table_id"
    t.index ["togodb_table_id"], name: "togodb_supplementary_files_togodb_table_id_key", unique: true
  end

  create_table "togodb_syslogs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 1
    t.text "message"
    t.string "group", limit: 255
    t.datetime "created_at"
  end

  create_table "togodb_tables", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.boolean "enabled"
    t.boolean "imported"
    t.datetime "updated_at"
    t.boolean "sortable", default: true
    t.string "page_name", limit: 255
    t.string "dl_file_name", limit: 255
    t.integer "num_records", default: -1
    t.integer "creator_id"
    t.integer "record_name_col_id"
    t.integer "sort_col_id"
    t.boolean "disable_sort", default: false
    t.integer "pkey_col_id"
    t.string "record_name", limit: 255
    t.boolean "confirm_licence", default: false
    t.text "owl"
    t.datetime "created_at"
    t.string "resource_class", limit: 255
    t.string "resource_label", limit: 255
    t.string "migrate_ver", limit: 255
    t.integer "work_id"
    t.index ["name"], name: "togodb_tables_name_key", unique: true
  end

  create_table "togodb_users", id: :serial, force: :cascade do |t|
    t.string "login", limit: 255
    t.string "password", limit: 255
    t.string "flags", limit: 255
    t.string "tables", limit: 255
    t.boolean "deleted", default: false
    t.index ["login"], name: "togodb_users_login_key", unique: true
  end

  create_table "turtle_generations", id: :serial, force: :cascade do |t|
    t.integer "work_id"
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer "pid"
    t.string "status"
    t.string "path"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "works", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "comment"
    t.string "base_uri"
    t.integer "user_id"
    t.text "er_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "mapping_updated"
  end

  add_foreign_key "togodb_supplementary_files", "togodb_tables"
  add_foreign_key "togodb_tables", "works", name: "togodb_tables_work_id_fkey"
end
