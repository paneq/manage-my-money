module Periodable

  def set_period(args)
    self.period_start = args[0]
    self.period_end = args[1]
    self.period_type = args[2] if self.respond_to? :period_type=
  end

end
