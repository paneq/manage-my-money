class GoalWorker < BackgrounDRb::MetaWorker
  set_worker_name :goal_worker
  def create(args = nil)
    # this method is called, when worker is loaded for the first time
  end

  def create_goals_for_next_cycle
    logger.info Time.now.to_s + ' create_goals_for_next_cycle starts'

    #startujemy raz dziennie

    goals = Goal.find_cyclic_goals_to_copy
    logger.info 'No goals to copy' if goals.empty?
    goals.each do |g|
      begin
        new_g = g.create_next_goal_in_cycle
        new_g.save!
      rescue
        logger.error $!, $!.backtrace
      end
    end

  end


end

