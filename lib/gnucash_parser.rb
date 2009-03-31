class GnucashParser; class << self
  def parse(content, user)
    return "#{Date.today}: parsed for user #{user}  #{content}"
  end
end; end