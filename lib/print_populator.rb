#require ...
#class PrintPopulator < SystemCategoriesPopulator
#  @@level=-1
#  def self.n(options, &children)
#    @@level += 1
#    puts "|   "*@@level + "|-- " + options[:name]
#    array = []
#    children.call(array) if block_given?
#    puts "|   "*(@@level+1) if block_given?
#    @@level -= 1
#  end
#end
#MyPop.load_data