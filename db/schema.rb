# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130310212924) do

  create_table "a_plus", :force => true do |t|
    t.integer  "item_id",    :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "a_plus", ["item_id", "user_id"], :name => "index_a_plus_on_item_id_and_user_id", :unique => true
  add_index "a_plus", ["item_id"], :name => "index_a_plus_on_item_id"
  add_index "a_plus", ["user_id"], :name => "index_a_plus_on_user_id"

  create_table "announcements", :force => true do |t|
    t.string   "headline"
    t.text     "text"
    t.datetime "start"
    t.datetime "end"
    t.integer  "user_id"
    t.text     "text_html"
  end

  create_table "assignment_documents", :force => true do |t|
    t.integer  "assignment_id"
    t.integer  "position"
    t.string   "filename",                              :null => false
    t.string   "content_type",                          :null => false
    t.datetime "created_at",                            :null => false
    t.string   "extension"
    t.string   "size"
    t.boolean  "add_to_all_turnins", :default => false, :null => false
    t.boolean  "keep_hidden",        :default => false, :null => false
  end

  create_table "assignment_pmd_settings", :force => true do |t|
    t.integer "assignment_id"
    t.integer "style_check_id"
    t.boolean "enabled",        :default => true, :null => false
  end

  create_table "assignments", :force => true do |t|
    t.integer  "course_id"
    t.integer  "position"
    t.string   "title"
    t.datetime "open_date"
    t.datetime "due_date"
    t.datetime "close_date"
    t.text     "description"
    t.text     "description_html"
    t.boolean  "file_uploads",                :default => false, :null => false
    t.boolean  "enable_upload",               :default => true,  :null => false
    t.boolean  "enable_journal",              :default => true,  :null => false
    t.boolean  "programming",                 :default => true,  :null => false
    t.boolean  "use_subversion",              :default => true,  :null => false
    t.string   "subversion_server"
    t.string   "subversion_development_path"
    t.string   "subversion_release_path"
    t.boolean  "auto_grade",                  :default => false, :null => false
    t.integer  "grade_category_id"
    t.boolean  "released",                    :default => false, :null => false
    t.boolean  "team_project",                :default => false, :null => false
    t.boolean  "quiz_assignment",             :default => false, :null => false
    t.boolean  "visible",                     :default => true,  :null => false
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "user_id",                     :default => 0,     :null => false
  end

  create_table "auto_grade_settings", :id => false, :force => true do |t|
    t.integer "assignment_id"
    t.boolean "student_style",     :default => true,  :null => false
    t.boolean "style",             :default => true,  :null => false
    t.boolean "student_io_check",  :default => false, :null => false
    t.boolean "io_check",          :default => false, :null => false
    t.boolean "student_autograde", :default => false, :null => false
    t.boolean "autograde",         :default => false, :null => false
  end

  add_index "auto_grade_settings", ["assignment_id"], :name => "index_auto_grade_settings_on_assignment_id", :unique => true

  create_table "autocompletes", :force => true do |t|
    t.string   "category",   :null => false
    t.string   "value",      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "autocompletes", ["category", "value"], :name => "index_autocompletes_on_category_and_value", :unique => true
  add_index "autocompletes", ["category"], :name => "index_autocompletes_on_category"

  create_table "basic_graders", :force => true do |t|
  end

  create_table "bdrb_job_queues", :force => true do |t|
    t.binary   "args"
    t.string   "worker_name"
    t.string   "worker_method"
    t.string   "job_key"
    t.integer  "taken"
    t.integer  "finished"
    t.integer  "timeout"
    t.integer  "priority"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "archived_at"
    t.string   "tag"
    t.string   "submitter_info"
    t.string   "runner_info"
    t.string   "worker_key"
    t.datetime "scheduled_at"
  end

  create_table "bj_config", :primary_key => "bj_config_id", :force => true do |t|
    t.text "hostname"
    t.text "key"
    t.text "value"
    t.text "cast"
  end

  create_table "bj_job", :primary_key => "bj_job_id", :force => true do |t|
    t.text     "command"
    t.text     "state"
    t.integer  "priority"
    t.text     "tag"
    t.integer  "is_restartable"
    t.text     "submitter"
    t.text     "runner"
    t.integer  "pid"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.text     "env"
    t.text     "stdin"
    t.text     "stdout"
    t.text     "stderr"
    t.integer  "exit_status"
  end

  create_table "bj_job_archive", :primary_key => "bj_job_archive_id", :force => true do |t|
    t.text     "command"
    t.text     "state"
    t.integer  "priority"
    t.text     "tag"
    t.integer  "is_restartable"
    t.text     "submitter"
    t.text     "runner"
    t.integer  "pid"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "archived_at"
    t.text     "env"
    t.text     "stdin"
    t.text     "stdout"
    t.text     "stderr"
    t.integer  "exit_status"
  end

  create_table "class_attendances", :force => true do |t|
    t.integer "class_period_id",                   :null => false
    t.integer "user_id",                           :null => false
    t.integer "course_id",                         :null => false
    t.boolean "correct_key",     :default => true, :null => false
  end

  create_table "class_periods", :force => true do |t|
    t.integer  "course_id",                    :null => false
    t.boolean  "open",       :default => true, :null => false
    t.string   "key",                          :null => false
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.integer  "position"
  end

  create_table "comments", :force => true do |t|
    t.integer  "post_id",                  :null => false
    t.integer  "user_id",                  :null => false
    t.text     "body",                     :null => false
    t.text     "body_html",                :null => false
    t.datetime "created_at",               :null => false
    t.string   "ip",         :limit => 15, :null => false
    t.integer  "course_id",                :null => false
  end

  create_table "course_informations", :id => false, :force => true do |t|
    t.integer "course_id"
    t.string  "meeting_days"
    t.string  "meeting_time"
    t.string  "office_hours"
    t.string  "room"
  end

  add_index "course_informations", ["course_id"], :name => "index_course_informations_on_course_id", :unique => true

  create_table "course_outcomes", :force => true do |t|
    t.integer  "course_id"
    t.text     "outcome",                    :null => false
    t.integer  "position"
    t.integer  "parent",     :default => -1, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "course_outcomes_program_outcomes", :id => false, :force => true do |t|
    t.integer  "course_outcome_id",                     :null => false
    t.integer  "program_outcome_id",                    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "level_some",         :default => false, :null => false
    t.boolean  "level_moderate",     :default => false, :null => false
    t.boolean  "level_extensive",    :default => true,  :null => false
  end

  add_index "course_outcomes_program_outcomes", ["course_outcome_id", "program_outcome_id"], :name => "courses_outcomes_program_outcomes_unique", :unique => true

  create_table "course_outcomes_rubrics", :id => false, :force => true do |t|
    t.integer  "course_outcome_id", :null => false
    t.integer  "rubric_id",         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "course_outcomes_rubrics", ["course_outcome_id", "rubric_id"], :name => "course_outcomes_rubrics_unique", :unique => true

  create_table "course_settings", :id => false, :force => true do |t|
    t.integer "course_id"
    t.boolean "enable_blog",                           :default => true,  :null => false
    t.boolean "blog_comments",                         :default => true,  :null => false
    t.boolean "enable_gradebook",                      :default => true,  :null => false
    t.boolean "enable_documents",                      :default => true,  :null => false
    t.boolean "enable_prog_assignments",               :default => false, :null => false
    t.boolean "enable_svn",                            :default => false, :null => false
    t.text    "svn_server"
    t.boolean "enable_rss",                            :default => true,  :null => false
    t.boolean "ta_course_information",                 :default => false, :null => false
    t.boolean "ta_course_documents",                   :default => false, :null => false
    t.boolean "ta_course_assignments",                 :default => false, :null => false
    t.boolean "ta_course_gradebook",                   :default => false, :null => false
    t.boolean "ta_course_users",                       :default => false, :null => false
    t.boolean "ta_course_blog_post",                   :default => false, :null => false
    t.boolean "ta_course_blog_edit",                   :default => false, :null => false
    t.boolean "ta_course_settings",                    :default => false, :null => false
    t.boolean "ta_view_student_files",                 :default => true,  :null => false
    t.boolean "ta_grade_individual",                   :default => true,  :null => false
    t.boolean "ta_send_email",                         :default => false, :null => false
    t.boolean "enable_forum",                          :default => true,  :null => false
    t.boolean "enable_forum_topic_create",             :default => false, :null => false
    t.boolean "enable_attendance",                     :default => false, :null => false
    t.boolean "enable_project_teams",                  :default => true,  :null => false
    t.boolean "enable_quizzes",                        :default => true,  :null => false
    t.boolean "ta_create_quizzes",                     :default => false, :null => false
    t.boolean "enable_wiki",                           :default => false, :null => false
    t.text    "email_signature",                                          :null => false
    t.boolean "enable_outcomes",                       :default => true,  :null => false
    t.boolean "ta_edit_outcomes",                      :default => false, :null => false
    t.boolean "ta_view_quiz_results",                  :default => false, :null => false
    t.boolean "ta_view_survey_results",                :default => false, :null => false
    t.boolean "ta_view_already_graded_assignments",    :default => false, :null => false
    t.boolean "ta_manage_attendance",                  :default => false, :null => false
    t.boolean "team_enable_wiki",                      :default => true,  :null => false
    t.boolean "team_enable_email",                     :default => true,  :null => false
    t.boolean "team_enable_documents",                 :default => true,  :null => false
    t.boolean "team_documents_instructor_upload_only", :default => false, :null => false
    t.boolean "team_show_members",                     :default => true,  :null => false
  end

  add_index "course_settings", ["course_id"], :name => "index_course_settings_on_course_id", :unique => true

  create_table "course_shares", :force => true do |t|
    t.integer  "user_id",                        :null => false
    t.integer  "course_id",                      :null => false
    t.boolean  "assignments", :default => false, :null => false
    t.boolean  "documents",   :default => false, :null => false
    t.boolean  "blogs",       :default => false, :null => false
    t.boolean  "outcomes",    :default => false, :null => false
    t.boolean  "rubrics",     :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "wiki",        :default => false, :null => false
  end

  add_index "course_shares", ["user_id", "course_id"], :name => "index_course_shares_on_user_id_and_course_id", :unique => true

  create_table "course_template_outcomes", :force => true do |t|
    t.integer  "course_template_id"
    t.text     "outcome",                            :null => false
    t.integer  "position"
    t.integer  "parent",             :default => -1, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "course_template_outcomes_program_outcomes", :id => false, :force => true do |t|
    t.integer  "course_template_outcome_id",                    :null => false
    t.integer  "program_outcome_id",                            :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "level_some",                 :default => false, :null => false
    t.boolean  "level_moderate",             :default => false, :null => false
    t.boolean  "level_extensive",            :default => true,  :null => false
  end

  add_index "course_template_outcomes_program_outcomes", ["course_template_outcome_id", "program_outcome_id"], :name => "course_template_outcomes_program_outcomes_unique", :unique => true

  create_table "course_templates", :force => true do |t|
    t.string   "title",                        :null => false
    t.string   "start_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "approved",   :default => true, :null => false
  end

  create_table "course_templates_programs", :id => false, :force => true do |t|
    t.integer  "course_template_id", :null => false
    t.integer  "program_id",         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "course_twitters", :force => true do |t|
    t.integer  "course_id",                          :null => false
    t.boolean  "twitter_enabled", :default => false, :null => false
    t.boolean  "auth_success",    :default => false, :null => false
    t.string   "request_token",                      :null => false
    t.string   "request_secret",                     :null => false
    t.string   "auth_url",                           :null => false
    t.string   "access_token"
    t.string   "access_secret"
    t.string   "twitter_name"
    t.string   "twitter_id"
    t.string   "auth_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "course_twitters", ["course_id"], :name => "index_course_twitters_on_course_id", :unique => true

  create_table "courses", :force => true do |t|
    t.integer "term_id",                             :null => false
    t.string  "title",                               :null => false
    t.string  "short_description"
    t.boolean "course_open",       :default => true, :null => false
    t.boolean "public",            :default => true, :null => false
  end

  add_index "courses", ["term_id"], :name => "index_courses_on_term_id"

  create_table "courses_crns", :id => false, :force => true do |t|
    t.integer "course_id", :null => false
    t.integer "crn_id",    :null => false
  end

  add_index "courses_crns", ["course_id", "crn_id"], :name => "index_courses_crns_on_course_id_and_crn_id", :unique => true

  create_table "courses_programs", :id => false, :force => true do |t|
    t.integer  "course_id",  :null => false
    t.integer  "program_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "courses_programs", ["course_id", "program_id"], :name => "index_courses_programs_on_course_id_and_program_id", :unique => true

  create_table "courses_users", :force => true do |t|
    t.integer "user_id",                                   :null => false
    t.integer "course_id",                                 :null => false
    t.boolean "course_student",         :default => true,  :null => false
    t.boolean "course_instructor",      :default => false, :null => false
    t.boolean "course_guest",           :default => false, :null => false
    t.boolean "course_assistant",       :default => false, :null => false
    t.integer "term_id",                :default => 0
    t.integer "crn_id",                 :default => 0
    t.integer "position",               :default => 1000,  :null => false
    t.boolean "dropped",                :default => false, :null => false
    t.boolean "audit_opt_in",           :default => false, :null => false
    t.boolean "propose_student",        :default => false, :null => false
    t.boolean "reject_propose_student", :default => false, :null => false
    t.boolean "propose_guest",          :default => false, :null => false
    t.boolean "reject_propose_guest",   :default => false, :null => false
  end

  add_index "courses_users", ["user_id", "course_id"], :name => "index_courses_users_on_user_id_and_course_id", :unique => true
  add_index "courses_users", ["user_id", "term_id"], :name => "user_term_idx"

  create_table "crns", :force => true do |t|
    t.string "crn",   :limit => 20, :null => false
    t.string "name",                :null => false
    t.string "title"
  end

  create_table "document_accesses", :id => false, :force => true do |t|
    t.integer  "document_id"
    t.integer  "user_id"
    t.integer  "course_id"
    t.datetime "created_at"
  end

  add_index "document_accesses", ["document_id"], :name => "index_document_accesses_on_document_id"
  add_index "document_accesses", ["user_id", "course_id"], :name => "index_document_accesses_on_user_id_and_course_id"

  create_table "documents", :force => true do |t|
    t.integer  "course_id",                          :null => false
    t.integer  "position",                           :null => false
    t.string   "title",                              :null => false
    t.string   "filename",                           :null => false
    t.string   "content_type",                       :null => false
    t.text     "comments"
    t.text     "comments_html"
    t.datetime "created_at",                         :null => false
    t.string   "extension"
    t.string   "size"
    t.boolean  "published",       :default => true,  :null => false
    t.integer  "document_parent", :default => 0,     :null => false
    t.boolean  "folder",          :default => false, :null => false
    t.boolean  "podcast_folder",  :default => false, :null => false
    t.boolean  "link",            :default => false, :null => false
    t.text     "url"
    t.integer  "user_id",         :default => 0,     :null => false
  end

  create_table "extensions", :force => true do |t|
    t.integer  "assignment_id"
    t.integer  "user_id"
    t.datetime "extension_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "extensions", ["assignment_id", "user_id"], :name => "extension_assignment_user_idx", :unique => true
  add_index "extensions", ["assignment_id"], :name => "extension_assignment_id_idx"

  create_table "feed_subscriptions", :force => true do |t|
    t.integer  "feed_id",                       :null => false
    t.integer  "user_id",                       :null => false
    t.boolean  "send_email", :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "caught_up",  :default => false, :null => false
  end

  add_index "feed_subscriptions", ["feed_id", "user_id"], :name => "feed_user_idx", :unique => true
  add_index "feed_subscriptions", ["feed_id"], :name => "index_feed_subscriptions_on_feed_id"
  add_index "feed_subscriptions", ["user_id"], :name => "index_feed_subscriptions_on_user_id"

  create_table "feeds", :force => true do |t|
    t.integer "user_id"
    t.integer "course_id"
  end

  add_index "feeds", ["course_id"], :name => "index_feeds_on_course_id", :unique => true
  add_index "feeds", ["user_id"], :name => "index_feeds_on_user_id", :unique => true

  create_table "feeds_items", :force => true do |t|
    t.integer  "feed_id",   :null => false
    t.integer  "item_id",   :null => false
    t.datetime "timestamp"
  end

  add_index "feeds_items", ["feed_id", "item_id"], :name => "index_feeds_items_on_feed_id_and_item_id", :unique => true
  add_index "feeds_items", ["feed_id"], :name => "index_feeds_items_on_feed_id"

  create_table "file_comments", :force => true do |t|
    t.integer "user_turnin_file_id", :null => false
    t.integer "line_number",         :null => false
    t.integer "user_id",             :null => false
    t.text    "comments"
  end

  add_index "file_comments", ["user_turnin_file_id", "line_number"], :name => "file_comments_file_line_number_idx", :unique => true
  add_index "file_comments", ["user_turnin_file_id"], :name => "file_line_number_idx"

  create_table "file_styles", :force => true do |t|
    t.integer "user_turnin_file_id",                    :null => false
    t.integer "begin_line"
    t.integer "begin_column"
    t.integer "end_line"
    t.integer "end_column"
    t.string  "package"
    t.string  "class_name"
    t.text    "message"
    t.integer "style_check_id"
    t.boolean "suppressed",          :default => false, :null => false
  end

  add_index "file_styles", ["user_turnin_file_id"], :name => "file_line_num_idx"

  create_table "forum_posts", :force => true do |t|
    t.string   "headline",       :null => false
    t.text     "post",           :null => false
    t.text     "post_html",      :null => false
    t.integer  "forum_topic_id", :null => false
    t.integer  "parent_post",    :null => false
    t.integer  "user_id",        :null => false
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.integer  "replies"
    t.integer  "last_user_id"
  end

  add_index "forum_posts", ["parent_post"], :name => "forum_posts_parent_post_index"

  create_table "forum_topics", :force => true do |t|
    t.integer  "course_id",                     :null => false
    t.string   "topic",                         :null => false
    t.integer  "position",                      :null => false
    t.boolean  "allow_posts", :default => true, :null => false
    t.integer  "user_id",                       :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "post_count",                    :null => false
    t.datetime "last_post"
  end

  create_table "forum_watches", :id => false, :force => true do |t|
    t.integer  "forum_topic_id", :null => false
    t.integer  "user_id",        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "forum_watches", ["forum_topic_id", "user_id"], :name => "index_forum_watches_on_forum_topic_id_and_user_id", :unique => true

  create_table "grade_categories", :force => true do |t|
    t.string  "category"
    t.integer "course_id", :default => 0, :null => false
  end

  add_index "grade_categories", ["course_id"], :name => "grade_category_course_idx"

  create_table "grade_entries", :force => true do |t|
    t.integer  "grade_item_id"
    t.integer  "user_id"
    t.integer  "course_id"
    t.float    "points"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "comment"
  end

  add_index "grade_entries", ["grade_item_id"], :name => "index_grade_entries_on_grade_item_id"
  add_index "grade_entries", ["user_id"], :name => "index_grade_entries_on_user_id"

  create_table "grade_items", :force => true do |t|
    t.string  "name"
    t.date    "date"
    t.float   "points"
    t.string  "display_type",      :limit => 1
    t.boolean "visible",                        :default => true, :null => false
    t.integer "grade_category_id"
    t.integer "assignment_id"
    t.integer "course_id",                                        :null => false
    t.integer "position",                       :default => 1000, :null => false
  end

  create_table "grade_queues", :force => true do |t|
    t.integer  "user_id",                           :null => false
    t.integer  "assignment_id",                     :null => false
    t.integer  "user_turnin_id",                    :null => false
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.boolean  "serviced",       :default => false, :null => false
    t.boolean  "acknowledged",   :default => false, :null => false
    t.boolean  "queued",         :default => false, :null => false
    t.boolean  "failed",         :default => false, :null => false
    t.text     "message"
    t.string   "batch"
    t.integer  "course_id",      :default => -1,    :null => false
  end

  add_index "grade_queues", ["batch"], :name => "index_grade_queues_on_batch"

  create_table "grade_weights", :force => true do |t|
    t.integer "grade_category_id",                  :null => false
    t.float   "percentage",        :default => 0.0, :null => false
    t.integer "gradebook_id",                       :null => false
  end

  create_table "gradebooks", :id => false, :force => true do |t|
    t.integer "course_id"
    t.boolean "weight_grades", :default => false, :null => false
    t.boolean "show_total",    :default => true,  :null => false
  end

  add_index "gradebooks", ["course_id"], :name => "index_gradebooks_on_course_id", :unique => true

  create_table "io_check_results", :force => true do |t|
    t.integer  "io_check_id",    :null => false
    t.integer  "user_id",        :null => false
    t.integer  "user_turnin_id", :null => false
    t.text     "output",         :null => false
    t.text     "diff_report",    :null => false
    t.float    "match_percent",  :null => false
    t.datetime "created_at",     :null => false
  end

  add_index "io_check_results", ["io_check_id", "user_turnin_id"], :name => "index_io_check_results_on_io_check_id_and_user_turnin_id", :unique => true

  create_table "io_checks", :force => true do |t|
    t.string  "name",                               :null => false
    t.text    "description"
    t.integer "assignment_id",                      :null => false
    t.text    "input",                              :null => false
    t.text    "output",                             :null => false
    t.float   "tolerance",       :default => 1.0,   :null => false
    t.boolean "ignore_newlines", :default => false, :null => false
    t.boolean "show_input",      :default => false, :null => false
    t.boolean "student_level",   :default => false, :null => false
  end

  add_index "io_checks", ["assignment_id"], :name => "index_io_checks_on_assignment_id"
  add_index "io_checks", ["name", "assignment_id"], :name => "io_checks_name_by_assignment", :unique => true

  create_table "item_comments", :force => true do |t|
    t.integer  "item_id",                                     :null => false
    t.integer  "user_id",                                     :null => false
    t.text     "body",                                        :null => false
    t.text     "body_html",                                   :null => false
    t.boolean  "edited",                   :default => false, :null => false
    t.string   "ip",         :limit => 15,                    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "item_comments", ["item_id"], :name => "item_comments_item_id_index"

  create_table "item_shares", :force => true do |t|
    t.integer "item_id",                      :null => false
    t.integer "user_id"
    t.integer "course_id"
    t.boolean "emailed",   :default => false, :null => false
  end

  add_index "item_shares", ["item_id"], :name => "index_item_shares_on_item_id"

  create_table "items", :force => true do |t|
    t.integer  "user_id",                                :null => false
    t.integer  "course_id"
    t.text     "body",                                   :null => false
    t.text     "body_html",                              :null => false
    t.boolean  "enable_comments",      :default => true, :null => false
    t.boolean  "enable_reshare",       :default => true, :null => false
    t.boolean  "public",               :default => true, :null => false
    t.integer  "assignment_id"
    t.integer  "graded_assignment_id"
    t.integer  "post_id"
    t.integer  "document_id"
    t.integer  "wiki_id"
    t.integer  "forum_post_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "comment_count",        :default => 0,    :null => false
    t.integer  "aplus_count",          :default => 0,    :null => false
    t.string   "recent_commenters",    :default => "",   :null => false
    t.integer  "unique_commenters",    :default => 0,    :null => false
  end

  add_index "items", ["assignment_id"], :name => "index_items_on_assignment_id", :unique => true
  add_index "items", ["document_id"], :name => "index_items_on_document_id", :unique => true
  add_index "items", ["forum_post_id"], :name => "index_items_on_forum_post_id", :unique => true
  add_index "items", ["graded_assignment_id"], :name => "index_items_on_graded_assignment_id", :unique => true
  add_index "items", ["post_id"], :name => "index_items_on_post_id", :unique => true
  add_index "items", ["user_id"], :name => "index_items_on_user_id"
  add_index "items", ["wiki_id"], :name => "index_items_on_wiki_id", :unique => true

  create_table "journal_entry_stop_reasons", :id => false, :force => true do |t|
    t.integer "journal_id"
    t.integer "journal_stop_reason_id"
  end

  add_index "journal_entry_stop_reasons", ["journal_id", "journal_stop_reason_id"], :name => "journal_stop_reasons_idx", :unique => true

  create_table "journal_entry_tasks", :id => false, :force => true do |t|
    t.integer "journal_id"
    t.integer "journal_task_id"
  end

  add_index "journal_entry_tasks", ["journal_id", "journal_task_id"], :name => "index_journal_entry_tasks_on_journal_id_and_journal_task_id", :unique => true

  create_table "journal_fields", :id => false, :force => true do |t|
    t.integer "assignment_id"
    t.boolean "start_time",          :default => true, :null => false
    t.boolean "end_time",            :default => true, :null => false
    t.boolean "interruption_time",   :default => true, :null => false
    t.boolean "completed",           :default => true, :null => false
    t.boolean "task",                :default => true, :null => false
    t.boolean "reason_for_stopping", :default => true, :null => false
    t.boolean "comments",            :default => true, :null => false
  end

  add_index "journal_fields", ["assignment_id"], :name => "index_journal_fields_on_assignment_id", :unique => true

  create_table "journal_stop_reasons", :force => true do |t|
    t.string  "reason"
    t.integer "course_id", :default => 0, :null => false
  end

  create_table "journal_tasks", :force => true do |t|
    t.string  "task"
    t.integer "course_id", :default => 0, :null => false
  end

  create_table "journals", :force => true do |t|
    t.integer  "assignment_id",     :null => false
    t.integer  "user_id",           :null => false
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer  "interruption_time"
    t.boolean  "completed"
    t.text     "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notifications", :force => true do |t|
    t.integer  "user_id",                                :null => false
    t.text     "notification",                           :null => false
    t.text     "link"
    t.boolean  "emailed",             :default => false, :null => false
    t.boolean  "acknowledged",        :default => false, :null => false
    t.integer  "view_count",          :default => 0,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "item_id"
    t.boolean  "aplus",               :default => false, :null => false
    t.boolean  "comment",             :default => false, :null => false
    t.string   "recent_users"
    t.integer  "course_id"
    t.boolean  "proposal"
    t.integer  "followed_by_user_id"
  end

  add_index "notifications", ["item_id"], :name => "index_notifications_on_item_id"
  add_index "notifications", ["user_id", "course_id", "proposal"], :name => "notifications_proposal_index"
  add_index "notifications", ["user_id", "emailed"], :name => "index_notifications_on_user_id_and_emailed"
  add_index "notifications", ["user_id"], :name => "index_notifications_on_user_id"

  create_table "posts", :force => true do |t|
    t.integer  "course_id",                          :null => false
    t.integer  "user_id",                            :null => false
    t.boolean  "featured",        :default => false, :null => false
    t.string   "title",                              :null => false
    t.text     "body",                               :null => false
    t.text     "body_html",                          :null => false
    t.boolean  "enable_comments", :default => true,  :null => false
    t.datetime "created_at",                         :null => false
    t.boolean  "published",       :default => true,  :null => false
  end

  create_table "program_outcomes", :force => true do |t|
    t.integer  "program_id"
    t.text     "outcome",    :null => false
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "programming_languages", :force => true do |t|
    t.string  "name"
    t.boolean "enable_compile_step", :default => true, :null => false
    t.string  "compile_command"
    t.string  "executable_name"
    t.string  "execute_command",                       :null => false
    t.string  "extension",                             :null => false
  end

  create_table "programs", :force => true do |t|
    t.string   "title",                         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "enable_api", :default => false, :null => false
  end

  create_table "programs_users", :force => true do |t|
    t.integer  "user_id",                            :null => false
    t.integer  "program_id",                         :null => false
    t.boolean  "program_manager", :default => true,  :null => false
    t.boolean  "program_auditor", :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "programs_users", ["user_id", "program_id"], :name => "index_programs_users_on_user_id_and_program_id", :unique => true

  create_table "project_teams", :force => true do |t|
    t.integer "course_id", :null => false
    t.string  "team_id",   :null => false
    t.string  "name",      :null => false
  end

  create_table "quiz_attempt_answers", :force => true do |t|
    t.integer  "quiz_attempt_id",                            :null => false
    t.integer  "quiz_question_id",                           :null => false
    t.integer  "quiz_question_answer_id"
    t.text     "text_answer"
    t.boolean  "correct",                 :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "quiz_attempt_answers", ["quiz_attempt_id"], :name => "index_quiz_attempt_answers_on_quiz_attempt_id"
  add_index "quiz_attempt_answers", ["quiz_question_id"], :name => "index_quiz_attempt_answers_on_quiz_question_id"

  create_table "quiz_attempts", :force => true do |t|
    t.integer  "quiz_id",                       :null => false
    t.integer  "user_id",                       :null => false
    t.integer  "save_count",                    :null => false
    t.boolean  "completed",  :default => false, :null => false
    t.float    "score"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "quiz_attempts", ["quiz_id"], :name => "index_quiz_attempts_on_quiz_id"
  add_index "quiz_attempts", ["user_id"], :name => "index_quiz_attempts_on_user_id"

  create_table "quiz_question_answers", :force => true do |t|
    t.integer  "quiz_question_id",                    :null => false
    t.integer  "position"
    t.text     "answer_text"
    t.boolean  "correct",          :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "answer_text_html"
  end

  add_index "quiz_question_answers", ["quiz_question_id"], :name => "quiz_question_answers_question_id"

  create_table "quiz_questions", :force => true do |t|
    t.integer  "quiz_id",                            :null => false
    t.integer  "position"
    t.text     "question"
    t.boolean  "text_response",   :default => false, :null => false
    t.boolean  "multiple_choice", :default => true,  :null => false
    t.boolean  "checkbox",        :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "score_question",  :default => true,  :null => false
    t.text     "question_html"
  end

  add_index "quiz_questions", ["quiz_id"], :name => "quiz_questions_quiz_id"

  create_table "quizzes", :force => true do |t|
    t.integer "assignment_id",                            :null => false
    t.integer "attempt_maximum",       :default => -1,    :null => false
    t.boolean "random_questions",      :default => false, :null => false
    t.integer "number_of_questions",   :default => -1,    :null => false
    t.boolean "linear_score",          :default => false, :null => false
    t.boolean "survey",                :default => false, :null => false
    t.boolean "available_to_auditors", :default => false, :null => false
    t.boolean "anonymous",             :default => false, :null => false
    t.boolean "entry_exit",            :default => false, :null => false
    t.integer "course_id",                                :null => false
    t.boolean "show_elapsed",          :default => true,  :null => false
  end

  add_index "quizzes", ["assignment_id"], :name => "index_quizzes_on_assignment_id", :unique => true
  add_index "quizzes", ["course_id"], :name => "index_quizzes_on_course_id"

  create_table "rubric_entries", :force => true do |t|
    t.integer  "assignment_id",                     :null => false
    t.integer  "user_id",                           :null => false
    t.integer  "rubric_id",                         :null => false
    t.boolean  "full_credit",    :default => false, :null => false
    t.boolean  "partial_credit", :default => false, :null => false
    t.boolean  "no_credit",      :default => false, :null => false
    t.text     "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "above_credit",   :default => false, :null => false
    t.boolean  "custom_score",   :default => false, :null => false
    t.float    "score"
  end

  add_index "rubric_entries", ["assignment_id"], :name => "index_rubric_entries_on_assignment_id"
  add_index "rubric_entries", ["user_id", "rubric_id"], :name => "index_rubric_entries_on_user_id_and_rubric_id", :unique => true

  create_table "rubric_levels", :force => true do |t|
    t.string   "l1_name",    :null => false
    t.string   "l2_name",    :null => false
    t.string   "l3_name",    :null => false
    t.string   "l4_name",    :null => false
    t.integer  "course_id",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rubric_levels", ["course_id"], :name => "index_rubric_levels_on_course_id", :unique => true

  create_table "rubrics", :force => true do |t|
    t.integer  "assignment_id",                                  :null => false
    t.integer  "course_id",                                      :null => false
    t.text     "primary_trait",                                  :null => false
    t.text     "no_credit_criteria",                             :null => false
    t.float    "no_credit_points",             :default => 0.0,  :null => false
    t.text     "part_credit_criteria",                           :null => false
    t.float    "part_credit_points",           :default => 0.0,  :null => false
    t.text     "full_credit_criteria",                           :null => false
    t.float    "full_credit_points",           :default => 0.0,  :null => false
    t.boolean  "visible_before_grade_release", :default => true, :null => false
    t.boolean  "visible_after_grade_release",  :default => true, :null => false
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "above_credit_criteria",                          :null => false
    t.float    "above_credit_points",          :default => 0.0,  :null => false
  end

  add_index "rubrics", ["assignment_id"], :name => "index_rubrics_on_assignment_id"
  add_index "rubrics", ["course_id"], :name => "index_rubrics_on_course_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"

  create_table "settings", :force => true do |t|
    t.string "name",        :null => false
    t.text   "value",       :null => false
    t.text   "description", :null => false
  end

  add_index "settings", ["name"], :name => "index_settings_on_name", :unique => true

  create_table "statuses", :force => true do |t|
    t.string   "name",       :null => false
    t.text     "value",      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "statuses", ["name"], :name => "index_statuses_on_name", :unique => true

  create_table "style_checks", :force => true do |t|
    t.string  "name"
    t.text    "description"
    t.text    "example"
    t.boolean "bias",        :default => true, :null => false
  end

  add_index "style_checks", ["name"], :name => "index_style_checks_on_name", :unique => true

  create_table "team_documents", :force => true do |t|
    t.integer  "project_team_id", :null => false
    t.integer  "user_id",         :null => false
    t.string   "filename",        :null => false
    t.string   "content_type",    :null => false
    t.string   "extension"
    t.string   "size"
    t.datetime "created_at",      :null => false
  end

  create_table "team_emails", :force => true do |t|
    t.integer  "project_team_id", :null => false
    t.integer  "user_id",         :null => false
    t.string   "subject",         :null => false
    t.text     "message",         :null => false
    t.datetime "created_at",      :null => false
  end

  create_table "team_filters", :force => true do |t|
    t.integer  "assignment_id",   :null => false
    t.integer  "project_team_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "team_filters", ["assignment_id", "project_team_id"], :name => "index_team_filters_on_assignment_id_and_project_team_id", :unique => true

  create_table "team_members", :force => true do |t|
    t.integer "project_team_id", :null => false
    t.integer "user_id",         :null => false
    t.integer "course_id",       :null => false
  end

  add_index "team_members", ["user_id", "course_id"], :name => "index_team_members_on_user_id_and_course_id"

  create_table "team_wiki_pages", :force => true do |t|
    t.integer  "project_team_id",                :null => false
    t.string   "page",                           :null => false
    t.text     "content",                        :null => false
    t.text     "content_html",                   :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.integer  "user_id",                        :null => false
    t.integer  "revision",        :default => 1, :null => false
  end

  add_index "team_wiki_pages", ["project_team_id", "page", "revision"], :name => "index_team_wiki_pages_on_project_team_id_and_page_and_revision", :unique => true

  create_table "temp_files", :force => true do |t|
    t.text     "filename"
    t.datetime "save_until"
  end

  create_table "terms", :force => true do |t|
    t.string  "term",     :limit => 10,                    :null => false
    t.integer "year",                                      :null => false
    t.string  "semester", :limit => 15,                    :null => false
    t.boolean "current",                :default => false
    t.boolean "open",                   :default => true
  end

  create_table "user_profiles", :id => false, :force => true do |t|
    t.integer  "user_id"
    t.string   "major"
    t.string   "year"
    t.text     "about_me"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_profiles", ["user_id"], :name => "index_user_profiles_on_user_id", :unique => true

  create_table "user_turnin_files", :force => true do |t|
    t.integer  "user_turnin_id"
    t.boolean  "directory_entry",                      :null => false
    t.integer  "directory_parent",                     :null => false
    t.integer  "position",                             :null => false
    t.string   "filename",                             :null => false
    t.datetime "created_at",                           :null => false
    t.string   "extension"
    t.boolean  "main",              :default => false, :null => false
    t.boolean  "main_candidate",    :default => false, :null => false
    t.boolean  "gradable",          :default => false, :null => false
    t.text     "gradable_message"
    t.boolean  "gradable_override", :default => false, :null => false
    t.integer  "user_id"
    t.boolean  "auto_added",        :default => false, :null => false
    t.boolean  "hidden",            :default => false, :null => false
  end

  add_index "user_turnin_files", ["user_turnin_id", "filename", "directory_parent"], :name => "unique_filename_idx", :unique => true

  create_table "user_turnins", :force => true do |t|
    t.integer  "assignment_id"
    t.integer  "user_id"
    t.integer  "position"
    t.boolean  "sealed",          :default => false, :null => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.boolean  "finalized",       :default => false, :null => false
    t.integer  "project_team_id"
    t.boolean  "force_update",    :default => true,  :null => false
  end

  create_table "users", :force => true do |t|
    t.string  "uniqueid",            :limit => 100,                    :null => false
    t.string  "password"
    t.string  "preferred_name"
    t.string  "first_name",                                            :null => false
    t.string  "middle_name"
    t.string  "last_name",                                             :null => false
    t.boolean "instructor",                                            :null => false
    t.boolean "admin",                              :default => false, :null => false
    t.string  "affiliation"
    t.string  "personal_title"
    t.string  "office_hours"
    t.string  "phone_number"
    t.string  "email",                                                 :null => false
    t.boolean "activated",                          :default => false, :null => false
    t.string  "activation_token",                   :default => "",    :null => false
    t.string  "forgot_token",                       :default => "",    :null => false
    t.boolean "enabled",                            :default => true,  :null => false
    t.boolean "auditor",                            :default => false, :null => false
    t.boolean "program_coordinator",                :default => false, :null => false
    t.boolean "ever_ldap_auth",                     :default => false, :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["uniqueid"], :name => "index_users_on_uniqueid", :unique => true

  create_table "wikis", :force => true do |t|
    t.integer  "course_id",                       :null => false
    t.string   "page",                            :null => false
    t.text     "content",                         :null => false
    t.text     "content_html",                    :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.integer  "user_id",                         :null => false
    t.integer  "revision",      :default => 1,    :null => false
    t.boolean  "user_editable", :default => true, :null => false
  end

  add_index "wikis", ["course_id", "page", "revision"], :name => "index_wikis_on_course_id_and_page_and_revision", :unique => true

end
