# 
# hash.rb
# 
# Created on Nov 12, 2007, 11:06:31 AM
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
end
