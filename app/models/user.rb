# == Schema Information
# Schema version: 8
#
# Table name: users
#
#  id              :integer(11)   not null, primary key
#  name            :string(255)   
#  hashed_password :string(255)   
#  salt            :string(255)   
#  email           :string(255)   
#  active          :boolean(1)    not null
#

require 'digest/sha1'

class User < ActiveRecord::Base
  
  has_many :categories
  has_many :transfers
  has_many :currencies
  has_many :visible_currencies,
           :class_name => 'Currency',
           :finder_sql => 'SELECT c.* FROM currencies c WHERE (c.user_id = #{id} OR c.user_id is null)' #THIS IS REALLY IMPORTANT TO BE SINGLE QUOTED !!
  
  has_many :exchanges
  has_many :visible_exchanges,
           :class_name => 'Exchange',
           :finder_sql => 'SELECT e.* FROM exchanges e WHERE (e.user_id = #{id} OR e.user_id is null)' #THIS IS REALLY IMPORTANT TO BE SINGLE QUOTED !!
  
  validates_presence_of     :name
  validates_presence_of     :email
  validates_uniqueness_of   :name,
                            :message =>'User with that name already exists'
  validates_format_of       :email,
                            :with => %r{\b[a-zA-Z0-9._%-]+@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,4}\b},
                            :message => 'Wrong address format'
 
  attr_accessor :password_confirmation
  validates_confirmation_of :password,
                            :message => 'Given passwords was not the same'

  def validate
    errors.add_to_base('Missing password') if hashed_password.blank?
  end

  def top_categories
    top = []
    for c in self.categories do 
      top << c if c.parent_category.nil?
    end
    return top
  end
  
  ############################
  # @author: Jaroslaw Plebanski
  def before_destroy
    transfers.each do |t|
      t.transfer_items.each {|i| i.destroy }
      t.destroy
    end
    categories.each {|c| c.destroy}
  end
  
  ##############################
  # @author: Robert Pankowecki
  # @author: Jaroslaw Plebanski
  def self.authenticate(name, password)
    user = self.find_by_name(name)
    if user
      expected_password = encrypted_password(password, user.salt)
      if user.hashed_password != expected_password or !user.active
        user = nil
      end
    end
    user
  end
  
  
  
  
  
  # 'password' is a virtual attribute
  
  def password
    @password
  end
  
  def password=(pwd)
    @password = pwd
    return if pwd.blank?
    create_new_salt
    self.hashed_password = User.encrypted_password(self.password, self.salt)
  end


  #######
  private
  #######

  def self.encrypted_password(password, salt)
    string_to_hash = password + "wibble" + salt  # 'wibble' makes it harder to guess
    Digest::SHA1.hexdigest(string_to_hash)
  end
  
  def create_new_salt
    self.salt = self.object_id.to_s + rand.to_s
  end
  
  public

  def to_hash
    Digest::SHA1.hexdigest(self.name + self.hashed_password + "ala ma kota" + self.salt)	
  end

end

