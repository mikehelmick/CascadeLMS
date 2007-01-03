class CreateProgrammingLanguages < ActiveRecord::Migration
  def self.up
    create_table :programming_languages do |t|
      t.column :name, :string
      t.column :enable_compile_step, :boolean, :null => false, :default => true
      t.column :compile_command, :string
      t.column :executable_name, :string
      t.column :execute_command, :string, :null => false
      t.column :extension, :string, :null => false
    end
    
    ProgrammingLanguage.create :name => 'Java 1.5.0', :enable_compile_step => true, :compile_command => '/usr/bin/java {:mainfile}', :executable_name => '{:basename}.class', :execute_command => '/usr/bin/java {:basename}', :extension => 'java'
    #ProgrammingLanguage.create :name => 'Ruby', :enable_compile_step => false, :compile_command => '', :executable_name => '', :execute_command => '/usr/bin/java {:basename}'
    #ProgrammingLanguage.create :name => 'C (gcc)', :enable_compile_step => true, :compile_command => '/usr/bin/gcc -o a.out {:mainfile}', :executable_name => 'a.out', :execute_command => './a.out'
    #ProgrammingLanguage.create :name => 'C++ (g++)', :enable_compile_step => true, :compile_command => '/usr/bin/g++ -o a.out {:mainfile}', :executable_name => 'a.out', :execute_command => './a.out'
    #ProgrammingLanguage.create :name => 'Perl', :enable_compile_step => false, :compile_command => '', :executable_name => '', :execute_command => '/usr/bin/java {:basename}'
    
  end

  def self.down
    drop_table :programming_languages
  end
end
