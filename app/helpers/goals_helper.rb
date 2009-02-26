module GoalsHelper

  def get_desc_for_goal_completion_condition(code)
    case code
    when :at_least then 'Co najmniej'
    when :at_most then 'Co najwyżej'
    end
  end

end
