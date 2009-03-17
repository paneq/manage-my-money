require 'test_helper'
require 'bdrb_test_helper'
require 'report_worker'


class ReportWorkerTest < ActiveSupport::TestCase

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
