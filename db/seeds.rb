# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

User.create (:email => 'admin@torrentdam.com', :password => 'password', :password_confirmation => 'password', :first_name => 'Valerio', :last_name =>'Ponte', :admin => true)

