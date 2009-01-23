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

ActiveRecord::Schema.define(:version => 20090123032747) do

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
    t.string   "filename",           :default => "",    :null => false
    t.string   "content_type",       :default => "",    :null => false
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
    t.boolean  "enable_upload",               :default => false, :null => false
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

  add_index "auto_grade_settings", ["assignment_id"], :name => "auto_grade_settings_assignment_id_index", :unique => true

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

  create_table "class_attendances", :force => true do |t|
    t.integer "class_period_id", :default => 0,    :null => false
    t.integer "user_id",         :default => 0,    :null => false
    t.integer "course_id",       :default => 0,    :null => false
    t.boolean "correct_key",     :default => true, :null => false
  end

  create_table "class_periods", :force => true do |t|
    t.integer  "course_id",  :default => 0,    :null => false
    t.boolean  "open",       :default => true, :null => false
    t.string   "key",        :default => "",   :null => false
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.integer  "position"
  end

  create_table "comments", :force => true do |t|
    t.integer  "post_id",                  :default => 0,  :null => false
    t.integer  "user_id",                  :default => 0,  :null => false
    t.text     "body",                                     :null => false
    t.text     "body_html",                                :null => false
    t.datetime "created_at",                               :null => false
    t.string   "ip",         :limit => 15, :default => "", :null => false
    t.integer  "course_id",                :default => 0,  :null => false
  end

  create_table "course_informations", :id => false, :force => true do |t|
    t.integer "course_id"
    t.string  "meeting_days"
    t.string  "meeting_time"
    t.string  "office_hours"
    t.string  "room"
  end

  add_index "course_informations", ["course_id"], :name => "course_informations_course_id_index", :unique => true

  create_table "course_outcomes", :force => true do |t|
    t.integer  "course_id"
    t.text     "outcome",                    :null => false
    t.integer  "position"
    t.integer  "parent",     :default => -1, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "course_outcomes_program_outcomes", :id => false, :force => true do |t|
    t.integer  "course_outcome_id",  :default => 0, :null => false
    t.integer  "program_outcome_id", :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "course_outcomes_program_outcomes", ["course_outcome_id", "program_outcome_id"], :name => "courses_outcomes_program_outcomes_unique", :unique => true

  create_table "course_outcomes_rubrics", :id => false, :force => true do |t|
    t.integer  "course_outcome_id", :default => 0, :null => false
    t.integer  "rubric_id",         :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "course_outcomes_rubrics", ["course_outcome_id", "rubric_id"], :name => "course_outcomes_rubrics_unique", :unique => true

  create_table "course_settings", :id => false, :force => true do |t|
    t.integer "course_id"
    t.boolean "enable_blog",                        :default => true,  :null => false
    t.boolean "blog_comments",                      :default => true,  :null => false
    t.boolean "enable_gradebook",                   :default => true,  :null => false
    t.boolean "enable_documents",                   :default => true,  :null => false
    t.boolean "enable_prog_assignments",            :default => true,  :null => false
    t.boolean "enable_svn",                         :default => false, :null => false
    t.text    "svn_server"
    t.boolean "enable_rss",                         :default => true,  :null => false
    t.boolean "ta_course_information",              :default => false, :null => false
    t.boolean "ta_course_documents",                :default => false, :null => false
    t.boolean "ta_course_assignments",              :default => false, :null => false
    t.boolean "ta_course_gradebook",                :default => false, :null => false
    t.boolean "ta_course_users",                    :default => false, :null => false
    t.boolean "ta_course_blog_post",                :default => false, :null => false
    t.boolean "ta_course_blog_edit",                :default => false, :null => false
    t.boolean "ta_course_settings",                 :default => false, :null => false
    t.boolean "ta_view_student_files",              :default => true,  :null => false
    t.boolean "ta_grade_individual",                :default => true,  :null => false
    t.boolean "ta_send_email",                      :default => false, :null => false
    t.boolean "enable_forum",                       :default => true,  :null => false
    t.boolean "enable_forum_topic_create",          :default => false, :null => false
    t.boolean "enable_attendance",                  :default => false, :null => false
    t.boolean "enable_project_teams",               :default => false, :null => false
    t.boolean "enable_quizzes",                     :default => true,  :null => false
    t.boolean "ta_create_quizzes",                  :default => false, :null => false
    t.boolean "enable_wiki",                        :default => false, :null => false
    t.text    "email_signature",                                       :null => false
    t.boolean "enable_outcomes",                    :default => false, :null => false
    t.boolean "ta_edit_outcomes",                   :default => false, :null => false
    t.boolean "ta_view_quiz_results",               :default => false, :null => false
    t.boolean "ta_view_survey_results",             :default => false, :null => false
    t.boolean "ta_view_already_graded_assignments", :default => false, :null => false
    t.boolean "ta_manage_attendance",               :default => false, :null => false
  end

  add_index "course_settings", ["course_id"], :name => "course_settings_course_id_index", :unique => true

  create_table "course_template_outcomes", :force => true do |t|
    t.integer  "course_template_id"
    t.text     "outcome",                            :null => false
    t.integer  "position"
    t.integer  "parent",             :default => -1, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "course_template_outcomes_program_outcomes", :id => false, :force => true do |t|
    t.integer  "course_template_outcome_id", :default => 0, :null => false
    t.integer  "program_outcome_id",         :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "course_template_outcomes_program_outcomes", ["course_template_outcome_id", "program_outcome_id"], :name => "course_template_outcomes_program_outcomes_unique", :unique => true

  create_table "course_templates", :force => true do |t|
    t.string   "title",      :default => "",   :null => false
    t.string   "start_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "approved",   :default => true, :null => false
  end

  create_table "course_templates_programs", :id => false, :force => true do |t|
    t.integer  "course_template_id", :default => 0, :null => false
    t.integer  "program_id",         :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "courses", :force => true do |t|
    t.integer "term_id",           :default => 0,     :null => false
    t.string  "title",             :default => "",    :null => false
    t.string  "short_description"
    t.boolean "open",              :default => true,  :null => false
    t.boolean "public",            :default => false, :null => false
  end

  create_table "courses_crns", :id => false, :force => true do |t|
    t.integer "course_id", :default => 0, :null => false
    t.integer "crn_id",    :default => 0, :null => false
  end

  add_index "courses_crns", ["course_id", "crn_id"], :name => "courses_crns_course_id_index", :unique => true

  create_table "courses_programs", :id => false, :force => true do |t|
    t.integer  "course_id",  :default => 0, :null => false
    t.integer  "program_id", :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "courses_programs", ["course_id", "program_id"], :name => "index_courses_programs_on_course_id_and_program_id", :unique => true

  create_table "courses_users", :force => true do |t|
    t.integer "user_id",           :default => 0,     :null => false
    t.integer "course_id",         :default => 0,     :null => false
    t.boolean "course_student",    :default => true,  :null => false
    t.boolean "course_instructor", :default => false, :null => false
    t.boolean "course_guest",      :default => false, :null => false
    t.boolean "course_assistant",  :default => false, :null => false
  end

  add_index "courses_users", ["user_id", "course_id"], :name => "courses_users_user_id_index", :unique => true

  create_table "crns", :force => true do |t|
    t.string "crn",   :limit => 20, :default => "", :null => false
    t.string "name",                :default => "", :null => false
    t.string "title"
  end

  create_table "documents", :force => true do |t|
    t.integer  "course_id",       :default => 0,     :null => false
    t.integer  "position",        :default => 0,     :null => false
    t.string   "title",           :default => "",    :null => false
    t.string   "filename",        :default => "",    :null => false
    t.string   "content_type",    :default => "",    :null => false
    t.text     "comments"
    t.text     "comments_html"
    t.datetime "created_at",                         :null => false
    t.string   "extension"
    t.string   "size"
    t.boolean  "published",       :default => true,  :null => false
    t.integer  "document_parent", :default => 0,     :null => false
    t.boolean  "folder",          :default => false, :null => false
    t.boolean  "podcast_folder",  :default => false, :null => false
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

  create_table "file_comments", :force => true do |t|
    t.integer "user_turnin_file_id", :default => 0, :null => false
    t.integer "line_number",         :default => 0, :null => false
    t.integer "user_id",             :default => 0, :null => false
    t.text    "comments"
  end

  add_index "file_comments", ["user_turnin_file_id", "line_number"], :name => "file_comments_file_line_number_idx", :unique => true
  add_index "file_comments", ["user_turnin_file_id"], :name => "file_line_number_idx"

  create_table "file_styles", :force => true do |t|
    t.integer "user_turnin_file_id", :default => 0,     :null => false
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

  add_index "file_styles", ["user_turnin_file_id"], :name => "file_line_number_idx"

  create_table "forum_posts", :force => true do |t|
    t.string   "headline",       :default => "", :null => false
    t.text     "post",                           :null => false
    t.text     "post_html",                      :null => false
    t.integer  "forum_topic_id", :default => 0,  :null => false
    t.integer  "parent_post",    :default => 0,  :null => false
    t.integer  "user_id",        :default => 0,  :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.integer  "replies"
    t.integer  "last_user_id"
  end

  create_table "forum_topics", :force => true do |t|
    t.integer  "course_id",   :default => 0,    :null => false
    t.string   "topic",       :default => "",   :null => false
    t.integer  "position",    :default => 0,    :null => false
    t.boolean  "allow_posts", :default => true, :null => false
    t.integer  "user_id",     :default => 0,    :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "post_count",  :default => 0,    :null => false
    t.datetime "last_post",                     :null => false
  end

  create_table "grade_categories", :force => true do |t|
    t.string  "category"
    t.integer "course_id", :default => 0, :null => false
  end

  create_table "grade_entries", :force => true do |t|
    t.integer  "grade_item_id"
    t.integer  "user_id"
    t.integer  "course_id"
    t.float    "points"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "comment"
  end

  add_index "grade_entries", ["grade_item_id"], :name => "grade_entries_grade_item_id_index"
  add_index "grade_entries", ["user_id"], :name => "grade_entries_user_id_index"

  create_table "grade_items", :force => true do |t|
    t.string  "name"
    t.date    "date"
    t.float   "points"
    t.string  "display_type",      :limit => 1
    t.boolean "visible",                        :default => true, :null => false
    t.integer "grade_category_id"
    t.integer "assignment_id"
    t.integer "course_id",                      :default => 0,    :null => false
  end

  create_table "grade_queues", :force => true do |t|
    t.integer  "user_id",        :default => 0,     :null => false
    t.integer  "assignment_id",  :default => 0,     :null => false
    t.integer  "user_turnin_id", :default => 0,     :null => false
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.boolean  "serviced",       :default => false, :null => false
    t.boolean  "acknowledged",   :default => false, :null => false
    t.boolean  "queued",         :default => false, :null => false
    t.boolean  "failed",         :default => false, :null => false
    t.text     "message"
    t.string   "batch"
    t.integer  "course_id"
  end

  add_index "grade_queues", ["batch"], :name => "grade_queues_batch_index"

  create_table "grade_weights", :force => true do |t|
    t.integer "grade_category_id", :default => 0,   :null => false
    t.float   "percentage",        :default => 0.0, :null => false
    t.integer "gradebook_id",      :default => 0,   :null => false
  end

  create_table "gradebooks", :id => false, :force => true do |t|
    t.integer "course_id"
    t.boolean "weight_grades", :default => false, :null => false
    t.boolean "show_total",    :default => true,  :null => false
  end

  add_index "gradebooks", ["course_id"], :name => "gradebooks_course_id_index", :unique => true

  create_table "io_check_results", :force => true do |t|
    t.integer  "io_check_id",    :default => 0,   :null => false
    t.integer  "user_id",        :default => 0,   :null => false
    t.integer  "user_turnin_id", :default => 0,   :null => false
    t.text     "output",                          :null => false
    t.text     "diff_report",                     :null => false
    t.float    "match_percent",  :default => 0.0, :null => false
    t.datetime "created_at",                      :null => false
  end

  add_index "io_check_results", ["io_check_id", "user_turnin_id"], :name => "index_io_check_results_on_io_check_id_and_user_turnin_id", :unique => true

  create_table "io_checks", :force => true do |t|
    t.string  "name",            :default => "",    :null => false
    t.text    "description"
    t.integer "assignment_id",   :default => 0,     :null => false
    t.text    "input",                              :null => false
    t.text    "output",                             :null => false
    t.float   "tolerance",       :default => 1.0,   :null => false
    t.boolean "ignore_newlines", :default => false, :null => false
    t.boolean "show_input",      :default => false, :null => false
    t.boolean "student_level",   :default => false, :null => false
  end

  add_index "io_checks", ["assignment_id"], :name => "io_checks_assignment_id_index"
  add_index "io_checks", ["name", "assignment_id"], :name => "io_checks_name_by_assignment", :unique => true

  create_table "journal_entry_stop_reasons", :id => false, :force => true do |t|
    t.integer "journal_id"
    t.integer "journal_stop_reason_id"
  end

  add_index "journal_entry_stop_reasons", ["journal_id", "journal_stop_reason_id"], :name => "journal_entry_stop_reasons_journal_id_index", :unique => true

  create_table "journal_entry_tasks", :id => false, :force => true do |t|
    t.integer "journal_id"
    t.integer "journal_task_id"
  end

  add_index "journal_entry_tasks", ["journal_id", "journal_task_id"], :name => "journal_entry_tasks_journal_id_index", :unique => true

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

  add_index "journal_fields", ["assignment_id"], :name => "journal_fields_assignment_id_index", :unique => true

  create_table "journal_stop_reasons", :force => true do |t|
    t.string  "reason"
    t.integer "course_id", :default => 0, :null => false
  end

  create_table "journal_tasks", :force => true do |t|
    t.string  "task"
    t.integer "course_id", :default => 0, :null => false
  end

  create_table "journals", :force => true do |t|
    t.integer  "assignment_id",     :default => 0, :null => false
    t.integer  "user_id",           :default => 0, :null => false
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer  "interruption_time"
    t.boolean  "completed"
    t.text     "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notifications", :force => true do |t|
    t.integer  "user_id",      :default => 0,     :null => false
    t.text     "notification",                    :null => false
    t.text     "link"
    t.boolean  "emailed",      :default => false, :null => false
    t.boolean  "acknowledged", :default => false, :null => false
    t.integer  "view_count",   :default => 0,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notifications", ["user_id", "emailed"], :name => "index_notifications_on_user_id_and_emailed"
  add_index "notifications", ["user_id"], :name => "index_notifications_on_user_id"

  create_table "posts", :force => true do |t|
    t.integer  "course_id",       :default => 0,     :null => false
    t.integer  "user_id",         :default => 0,     :null => false
    t.boolean  "featured",        :default => false, :null => false
    t.string   "title",           :default => "",    :null => false
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
    t.string  "execute_command",     :default => "",   :null => false
    t.string  "extension",           :default => "",   :null => false
  end

  create_table "programs", :force => true do |t|
    t.string   "title",      :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "programs_users", :force => true do |t|
    t.integer  "user_id",         :default => 0,     :null => false
    t.integer  "program_id",      :default => 0,     :null => false
    t.boolean  "program_manager", :default => true,  :null => false
    t.boolean  "program_auditor", :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "programs_users", ["user_id", "program_id"], :name => "index_programs_users_on_user_id_and_program_id", :unique => true

  create_table "project_teams", :force => true do |t|
    t.integer "course_id", :default => 0,  :null => false
    t.string  "team_id",   :default => "", :null => false
    t.string  "name",      :default => "", :null => false
  end

  create_table "quiz_attempt_answers", :force => true do |t|
    t.integer  "quiz_attempt_id",         :default => 0,     :null => false
    t.integer  "quiz_question_id",        :default => 0,     :null => false
    t.integer  "quiz_question_answer_id"
    t.text     "text_answer"
    t.boolean  "correct",                 :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "quiz_attempt_answers", ["quiz_attempt_id"], :name => "index_quiz_attempt_answers_on_quiz_attempt_id"
  add_index "quiz_attempt_answers", ["quiz_question_id"], :name => "index_quiz_attempt_answers_on_quiz_question_id"

  create_table "quiz_attempts", :force => true do |t|
    t.integer  "quiz_id",    :default => 0,     :null => false
    t.integer  "user_id",    :default => 0,     :null => false
    t.integer  "save_count", :default => 0,     :null => false
    t.boolean  "completed",  :default => false, :null => false
    t.float    "score"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "quiz_attempts", ["quiz_id"], :name => "index_quiz_attempts_on_quiz_id"
  add_index "quiz_attempts", ["user_id"], :name => "index_quiz_attempts_on_user_id"

  create_table "quiz_question_answers", :force => true do |t|
    t.integer  "quiz_question_id", :default => 0,     :null => false
    t.integer  "position"
    t.text     "answer_text"
    t.boolean  "correct",          :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "quiz_questions", :force => true do |t|
    t.integer  "quiz_id",         :default => 0,     :null => false
    t.integer  "position"
    t.text     "question"
    t.boolean  "text_response",   :default => false, :null => false
    t.boolean  "multiple_choice", :default => true,  :null => false
    t.boolean  "checkbox",        :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "quizzes", :force => true do |t|
    t.integer "assignment_id",         :default => 0,     :null => false
    t.integer "attempt_maximum",       :default => -1,    :null => false
    t.boolean "random_questions",      :default => false, :null => false
    t.integer "number_of_questions",   :default => -1,    :null => false
    t.boolean "linear_score",          :default => false, :null => false
    t.boolean "survey",                :default => false, :null => false
    t.boolean "available_to_auditors", :default => false, :null => false
    t.boolean "anonymous",             :default => false, :null => false
    t.boolean "entry_exit",            :default => false, :null => false
    t.integer "course_id",             :default => 0,     :null => false
  end

  add_index "quizzes", ["assignment_id"], :name => "index_quizzes_on_assignment_id", :unique => true
  add_index "quizzes", ["course_id"], :name => "index_quizzes_on_course_id"

  create_table "rubric_entries", :force => true do |t|
    t.integer  "assignment_id",  :default => 0,     :null => false
    t.integer  "user_id",        :default => 0,     :null => false
    t.integer  "rubric_id",      :default => 0,     :null => false
    t.boolean  "full_credit",    :default => false, :null => false
    t.boolean  "partial_credit", :default => false, :null => false
    t.boolean  "no_credit",      :default => false, :null => false
    t.text     "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rubric_entries", ["assignment_id"], :name => "index_rubric_entries_on_assignment_id"
  add_index "rubric_entries", ["user_id", "rubric_id"], :name => "index_rubric_entries_on_user_id_and_rubric_id", :unique => true

  create_table "rubrics", :force => true do |t|
    t.integer  "assignment_id",                :default => 0,    :null => false
    t.integer  "course_id",                    :default => 0,    :null => false
    t.text     "primary_trait",                                  :null => false
    t.text     "no_credit_criteria",                             :null => false
    t.integer  "no_credit_points",             :default => 0,    :null => false
    t.text     "part_credit_criteria",                           :null => false
    t.integer  "part_credit_points",           :default => 0,    :null => false
    t.text     "full_credit_criteria",                           :null => false
    t.integer  "full_credit_points",           :default => 0,    :null => false
    t.boolean  "visible_before_grade_release", :default => true, :null => false
    t.boolean  "visible_after_grade_release",  :default => true, :null => false
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rubrics", ["assignment_id"], :name => "index_rubrics_on_assignment_id"
  add_index "rubrics", ["course_id"], :name => "index_rubrics_on_course_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "sessions_session_id_index"

  create_table "settings", :force => true do |t|
    t.string "name",        :default => "", :null => false
    t.text   "value",                       :null => false
    t.text   "description",                 :null => false
  end

  add_index "settings", ["name"], :name => "index_settings_on_name", :unique => true

  create_table "style_checks", :force => true do |t|
    t.string  "name"
    t.text    "description"
    t.text    "example"
    t.boolean "bias",        :default => true, :null => false
  end

  add_index "style_checks", ["name"], :name => "style_checks_name_index", :unique => true

  create_table "team_documents", :force => true do |t|
    t.integer  "project_team_id", :default => 0,  :null => false
    t.integer  "user_id",         :default => 0,  :null => false
    t.string   "filename",        :default => "", :null => false
    t.string   "content_type",    :default => "", :null => false
    t.string   "extension"
    t.string   "size"
    t.datetime "created_at",                      :null => false
  end

  create_table "team_emails", :force => true do |t|
    t.integer  "project_team_id", :default => 0,  :null => false
    t.integer  "user_id",         :default => 0,  :null => false
    t.string   "subject",         :default => "", :null => false
    t.text     "message",                         :null => false
    t.datetime "created_at",                      :null => false
  end

  create_table "team_members", :force => true do |t|
    t.integer "project_team_id", :default => 0, :null => false
    t.integer "user_id",         :default => 0, :null => false
    t.integer "course_id",       :default => 0, :null => false
  end

  add_index "team_members", ["user_id", "course_id"], :name => "team_members_user_id_index"

  create_table "team_wiki_pages", :force => true do |t|
    t.integer  "project_team_id", :default => 0,  :null => false
    t.string   "page",            :default => "", :null => false
    t.text     "content",                         :null => false
    t.text     "content_html",                    :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.integer  "user_id",         :default => 0,  :null => false
    t.integer  "revision",        :default => 1,  :null => false
  end

  add_index "team_wiki_pages", ["project_team_id", "page", "revision"], :name => "team_wiki_pages_project_team_id_index", :unique => true

  create_table "temp_files", :force => true do |t|
    t.text     "filename"
    t.datetime "save_until"
  end

  create_table "terms", :force => true do |t|
    t.string  "term",     :limit => 10, :default => "",    :null => false
    t.integer "year",                   :default => 0,     :null => false
    t.string  "semester", :limit => 15, :default => "",    :null => false
    t.boolean "current",                :default => false
    t.boolean "open",                   :default => true
  end

  create_table "user_turnin_files", :force => true do |t|
    t.integer  "user_turnin_id"
    t.boolean  "directory_entry",   :default => false, :null => false
    t.integer  "directory_parent",  :default => 0,     :null => false
    t.integer  "position",          :default => 0,     :null => false
    t.string   "filename",          :default => "",    :null => false
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
  end

  create_table "users", :force => true do |t|
    t.string  "uniqueid",            :limit => 15, :default => "",    :null => false
    t.string  "password"
    t.string  "preferred_name"
    t.string  "first_name",                        :default => "",    :null => false
    t.string  "middle_name"
    t.string  "last_name",                         :default => "",    :null => false
    t.boolean "instructor",                        :default => false, :null => false
    t.boolean "admin",                             :default => false, :null => false
    t.string  "affiliation"
    t.string  "personal_title"
    t.string  "office_hours"
    t.string  "phone_number"
    t.string  "email",                             :default => "",    :null => false
    t.boolean "activated",                         :default => false, :null => false
    t.string  "activation_token",                  :default => "",    :null => false
    t.string  "forgot_token",                      :default => "",    :null => false
    t.boolean "enabled",                           :default => true,  :null => false
    t.boolean "auditor",                           :default => false, :null => false
    t.boolean "program_coordinator",               :default => false, :null => false
  end

  create_table "wikis", :force => true do |t|
    t.integer  "course_id",     :default => 0,    :null => false
    t.string   "page",          :default => "",   :null => false
    t.text     "content",                         :null => false
    t.text     "content_html",                    :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.integer  "user_id",       :default => 0,    :null => false
    t.integer  "revision",      :default => 1,    :null => false
    t.boolean  "user_editable", :default => true, :null => false
  end

  add_index "wikis", ["course_id", "page", "revision"], :name => "index_wikis_on_course_id_and_page_and_revision", :unique => true

end
