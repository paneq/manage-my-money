class ReportWorker < BackgrounDRb::MetaWorker
  set_worker_name :report_worker
  def create(args = nil)
    # this method is called, when worker is loaded for the first time
  end

  def delete_temporary_reports
    logger.info Time.now.to_s + ' delete_temporary_reports starts'
    reports = Report.find :all, :conditions => ["temporary = ? AND updated_at < ? ", true, 5.hours.ago]
    deleted_reports = 0
    non_deleted_reports = []
    reports.each do |r|
      if r.delete
        deleted_reports += 1
      else
        non_deleted_reports << r
      end
    end
    if reports.size > 0
      logger.info "Deleted #{deleted_reports} reports from #{reports.count}"
      logger.info "Problems deleting #{non_deleted_reports}" if deleted_reports < reports.count
    else
      logger.info "No reports to delete"
    end
  end
end

