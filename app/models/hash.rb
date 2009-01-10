# 
# hash.rb
# 
# Created on Nov 12, 2008, 11:06:31 AM
# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

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

end
