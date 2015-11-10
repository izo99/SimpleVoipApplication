require 'dm-core'
require 'dm-migrations' 

class User 
  include DataMapper::Resource
  property :id, Serial, :unique => true  
  property :name, String, :length => 2..30, :required => true
  property :surname, String, :length => 2..30, :required => true
  property :username, String, :unique => true, :length => 3..30, :required => true
  property :password, String, :length => 5..30, :required => true
 # property :location, String, :length => 2..100, :required => false
  property :role, Integer, :required =>true
 # property :contact_status, Boolean, :required => false
 # property :signup_date, DateTime, :required => false


 has n, :registrations
  #has n, :contacts, :child_key => [ :source_id ]
 #has n, :sipcontacts, self, :through => :contacts, :via => :target

#	def remove_contact(contact)			
#			contacts.all(:target_id => contact.Id).destroy!
#			save
#	end
end

class Registration
 include DataMapper::Resource
  property :id, Serial
  property :registration_time, Time, :default => Time.now
  property :location, String, :required => true
 property :expire_time, Time, :default => Time.now
	
 belongs_to :user
 
end

#class Contact
#  include DataMapper::Resource 
 # property :add_date, DateTime, :default => DateTime.now
#  belongs_to :source, 'User', :key => true	
#  belongs_to :target, 'User', :key => true
#end 
#DataMapper.finalize
