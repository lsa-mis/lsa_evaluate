# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_08_05_195047) do
  create_table "action_text_rich_texts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.text "body", size: :long
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "address_types", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "kind", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "id_unq_idx", unique: true
    t.index ["kind"], name: "index_address_types_on_kind", unique: true
  end

  create_table "addresses", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "phone"
    t.string "country"
    t.bigint "address_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_type_id"], name: "address_type_id_idx"
    t.index ["address_type_id"], name: "index_addresses_on_address_type_id"
    t.index ["id"], name: "id_unq_idx", unique: true
  end

  create_table "assignments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "container_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["container_id"], name: "index_assignments_on_container_id"
    t.index ["role_id", "user_id", "container_id"], name: "index_assignments_on_role_user_container", unique: true
    t.index ["role_id"], name: "index_assignments_on_role_id"
    t.index ["user_id"], name: "index_assignments_on_user_id"
  end

  create_table "campuses", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "campus_descr", null: false
    t.integer "campus_cd", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campus_cd"], name: "campus_cd_unq_idx", unique: true
    t.index ["campus_descr"], name: "campus_descr_idx"
    t.index ["campus_descr"], name: "campus_descr_unq_idx", unique: true
    t.index ["id"], name: "id_unq_idx", unique: true
  end

  create_table "categories", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "kind"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_categories_on_kind", unique: true
  end

  create_table "class_level_requirements", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "contest_instance_id", null: false
    t.bigint "class_level_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["class_level_id"], name: "index_class_level_requirements_on_class_level_id"
    t.index ["contest_instance_id", "class_level_id"], name: "index_clr_on_ci_and_cl", unique: true
    t.index ["contest_instance_id"], name: "index_class_level_requirements_on_contest_instance_id"
  end

  create_table "class_levels", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "containers", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "department_id", null: false
    t.bigint "visibility_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["department_id"], name: "index_containers_on_department_id"
    t.index ["visibility_id"], name: "index_containers_on_visibility_id"
  end

  create_table "contest_descriptions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "container_id", null: false
    t.bigint "status_id", null: false
    t.string "name", null: false
    t.string "short_name"
    t.text "eligibility_rules"
    t.text "notes"
    t.string "created_by", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["container_id"], name: "index_contest_descriptions_on_container_id"
    t.index ["status_id"], name: "index_contest_descriptions_on_status_id"
  end

  create_table "contest_instances", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "status_id", null: false
    t.bigint "contest_description_id", null: false
    t.datetime "date_open", null: false
    t.datetime "date_closed", null: false
    t.text "notes"
    t.boolean "judging_open", default: false, null: false
    t.integer "judging_rounds", default: 1
    t.bigint "category_id", null: false
    t.boolean "has_course_requirement", default: false, null: false
    t.boolean "judge_evaluations_complete", default: false, null: false
    t.text "course_requirement_description"
    t.boolean "recletter_required", default: false, null: false
    t.boolean "transcript_required", default: false, null: false
    t.integer "maximum_number_entries_per_applicant", default: 1, null: false
    t.string "created_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "category_id_idx"
    t.index ["category_id"], name: "index_contest_instances_on_category_id"
    t.index ["contest_description_id"], name: "contest_description_id_idx"
    t.index ["contest_description_id"], name: "index_contest_instances_on_contest_description_id"
    t.index ["id"], name: "id_unq_idx", unique: true
    t.index ["status_id"], name: "index_contest_instances_on_status_id"
    t.index ["status_id"], name: "status_id_idx"
  end

  create_table "departments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "dept_id", null: false
    t.text "dept_description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
  end

  create_table "editable_contents", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "page", null: false
    t.string "section", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["page", "section"], name: "index_editable_contents_on_page_and_section", unique: true
  end

  create_table "profiles", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "first_name", default: "", null: false
    t.string "last_name", default: "", null: false
    t.bigint "class_level_id"
    t.bigint "school_id"
    t.bigint "campus_id"
    t.string "major"
    t.bigint "department_id"
    t.date "grad_date", null: false
    t.string "degree", null: false
    t.boolean "receiving_financial_aid", default: false, null: false
    t.boolean "accepted_financial_aid_notice", default: false, null: false
    t.text "financial_aid_description"
    t.string "hometown_publication"
    t.string "pen_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "home_address_id"
    t.bigint "campus_address_id"
    t.integer "umid", null: false
    t.boolean "campus_employee", default: false, null: false
    t.index ["campus_address_id"], name: "index_profiles_on_campus_address_id"
    t.index ["campus_id"], name: "campus_id_idx"
    t.index ["campus_id"], name: "index_profiles_on_campus_id"
    t.index ["class_level_id"], name: "class_level_id_idx"
    t.index ["class_level_id"], name: "index_profiles_on_class_level_id"
    t.index ["department_id"], name: "index_profiles_on_department_id"
    t.index ["home_address_id"], name: "index_profiles_on_home_address_id"
    t.index ["id"], name: "id_unq_idx", unique: true
    t.index ["school_id"], name: "index_profiles_on_school_id"
    t.index ["school_id"], name: "school_id_idx"
    t.index ["user_id"], name: "index_profiles_on_user_id"
    t.index ["user_id"], name: "user_id_idx"
  end

  create_table "roles", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "kind"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "schools", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "id_unq_idx", unique: true
  end

  create_table "statuses", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "kind", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_statuses_on_kind", unique: true
  end

  create_table "testingrsmokes", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_roles", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uniqname"
    t.string "provider"
    t.string "uid"
    t.string "principal_name"
    t.string "display_name"
    t.string "person_affiliation"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "visibilities", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "kind", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "address_types"
  add_foreign_key "assignments", "containers"
  add_foreign_key "assignments", "roles"
  add_foreign_key "assignments", "users"
  add_foreign_key "class_level_requirements", "class_levels"
  add_foreign_key "class_level_requirements", "contest_instances"
  add_foreign_key "containers", "departments"
  add_foreign_key "containers", "visibilities"
  add_foreign_key "contest_descriptions", "containers"
  add_foreign_key "contest_descriptions", "statuses"
  add_foreign_key "contest_instances", "categories"
  add_foreign_key "contest_instances", "contest_descriptions"
  add_foreign_key "contest_instances", "statuses"
  add_foreign_key "profiles", "addresses", column: "campus_address_id"
  add_foreign_key "profiles", "addresses", column: "home_address_id"
  add_foreign_key "profiles", "campuses"
  add_foreign_key "profiles", "class_levels"
  add_foreign_key "profiles", "departments"
  add_foreign_key "profiles", "schools"
  add_foreign_key "profiles", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
