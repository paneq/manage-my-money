class DataPopulator

  #Populate db by calling load_data method (should be implemented in Subclass)
  #Also prints info about populated items
  def self.populate
    @@model_class = self.to_s.gsub(/(.*)Populator/, '\1').singularize.constantize

    time = Time.now - 1.hour #FIXME time zone db issue!!!

    self.load_data

    populated = @@model_class.count(:conditions => ['updated_at >= ?', time])
    puts "Populated #{populated} #{@@model_class}. Total: #{@@model_class.count} in DB."

  end


  protected

  #this is shortening of method used for creating model objects
  #internally it uses 'create_or_update', so concrete model should implement it
  def self.n(options, &children)
    @@model_class.create_or_update(options, &children)
  end


  #Should be implemented in Subclass
  def self.load_data
    throw 'NoImplementedError'
  end


end
