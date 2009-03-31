require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'tasks/rails'

module AutocompleteTestHelper
  def execute_with_autocomplete(&proc)
    begin
      Rake::Task['ts:in'].invoke
      Rake::Task['ts:start'].invoke
      proc.call
    ensure
      Rake::Task['ts:stop'].invoke
    end
  end
end
