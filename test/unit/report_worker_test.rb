require File.dirname(__FILE__) + '/../test_helper'
require File.join(File.dirname(__FILE__) + "/../bdrb_test_helper")
require "report_worker"


class ReportWorkerTest < Test::Unit::TestCase

  def setup
    @worker = ReportWorker.new
  end

  #TODO
  def test_delete_temporary_reports
    assert_nothing_raised do
      @worker.delete_temporary_reports
    end
  end
  
end
