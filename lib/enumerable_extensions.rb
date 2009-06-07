module EnumerableExtensions

  def max_by(&proc)
    max_obj = nil
    max_val = nil
    is_first = true
    each do |obj|
      val = proc.call(obj)
      if is_first || val > max_val
        max_obj = obj
        max_val = val
      end
      is_first = false
    end
    max_obj
  end
  
end