module GoalsHelper

  def get_desc_for_goal_completion_condition(code)
    case code
    when :at_least then 'Co najmniej'
    when :at_most then 'Co najwyżej'
    end
  end



  def finished_goals_header_text
    text = 'Zakończone plany'
    text += ': brak' if @finished_goals.empty?
    text
  end

  def actual_goals_header_text
    text = 'Aktualne plany'
    text += ': brak' if @actual_goals.empty?
    text
  end







end
