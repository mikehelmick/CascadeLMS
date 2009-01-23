class AddCourseTemplateApproval < ActiveRecord::Migration
  def self.up
      add_column( :course_templates, :approved, :boolean, :null => false, :default => true )
    end

    def self.down
      remove_column( :course_templates, :approved )
  end
end
