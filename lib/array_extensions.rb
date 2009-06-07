module ArrayExtensions
  def shuffle
    array = self.clone
    n = array.size
    while n > 1 do
      n-=1
      k = Kernel.rand(n+1)
      tmp = array[k]
      array[k] = array[n]
      array[n] = tmp
    end
    array
  end #unless method_defined?(:shuffle)


  def shuffle!
    n = self.size
    while n > 1 do
      n-=1
      k = Kernel.rand(n+1)
      tmp = self[k]
      self[k] = self[n]
      self[n] = tmp
    end

  end #unless method_defined?(:shuffle!)

  def comb(n = size)
    if size < n or n < 0
    elsif n == 0
      yield([])
    else
      self[1..-1].comb(n) do |x|
        yield(x)
      end
      self[1..-1].comb(n - 1) do |x|
        yield([first] + x)
      end
    end
  end

  
  def combination(n = size)
    array = []
    comb(n) {|c| array << c}
    array
  end

end