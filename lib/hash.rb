class Hash
  def +(item)
    if item.class == Hash
      item.each_pair do |key, value|
        if self[key] == nil
          self[key] = value 
        else
          self[key] += value 
        end
      end
    else
      raise "Add only possible for two hashes"
    end
  end

  def -(item)
    if item.class == Hash
      item.each_pair do |key, value|
        if self[key] == nil
          self[key] = -value
        else
          self[key] -= value
        end
      end
    else
      raise "subtraction only possible for two hashes"
    end
  end
  

  # lets through the keys in the argument
  # >> {:one => 1, :two => 2, :three => 3}.pass(:one)
  # => {:one=>1}
  def pass(*keys)
    tmp = self.clone
    tmp.delete_if {|k,v| ! keys.include?(k) }
    tmp
  end

  # blocks the keys in the arguments
  # >> {:one => 1, :two => 2, :three => 3}.block(:one)
  # => {:two=>2, :three=>3}
  def block(*keys)
    tmp = self.clone
    tmp.delete_if {|k,v| keys.include?(k) }
    tmp
  end

  def first
    return [ self.keys[0], self[self.keys[0]] ] if self.size > 0
    return nil
  end unless method_defined?(:first) #compatibility mode for ruby 1.8.7

end


class HashWithIndifferentAccess

  # lets through the keys in the argument
  # >> {:one => 1, :two => 2, :three => 3}.pass(:one)
  # => {:one=>1}
  def pass(*keys)
    keys = keys.map do |k|
      if k.is_a?(Symbol)
        k.to_s
      else
        k
      end
    end
    tmp = self.clone
    tmp.delete_if {|k,v| ! keys.include?(k) }
    tmp
  end

  # blocks the keys in the arguments
  # >> {:one => 1, :two => 2, :three => 3}.block(:one)
  # => {:two=>2, :three=>3}
  def block(*keys)
    keys = keys.map do |k|
      if k.is_a?(Symbol)
        k.to_s
      else
        k
      end
    end
    tmp = self.clone
    tmp.delete_if {|k,v| keys.include?(k) }
    tmp
  end

end