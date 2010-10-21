require 'digest/sha1'

class User < ActiveRecord::Base
  validates_length_of :password, :within => 5..40
  validates_presence_of :email, :password, :password_confirmation, :first_name, :last_name
  validates_uniqueness_of :email
  validates_confirmation_of :password
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "Invalid"  
  attr_protected :id
	has_many :torrents
  #attr_accessible :first_name, :last_name
  attr_accessor :password, :password_confirmation

  def self.authenticate(email, pass)
    u=find(:first, :conditions=>["email = ?", email])
    return nil if u.nil?
    return u.id if User.encrypt(pass)==u.hashed_password
    nil
  end  

  def password=(pass)
    @password=pass
    self.hashed_password = User.encrypt(@password)
  end


  
  protected

  def self.encrypt(pass)
    Digest::SHA1.hexdigest(pass)
  end

 

end
