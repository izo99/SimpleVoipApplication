require 'sinatra'
require 'dm-core'
require "dm-migrations"
require "dm-validations"
require 'bcrypt'
require "dm-serializer/to_json"
require 'sinatra/flash'
require 'json'
require 'data_mapper'
require 'java'
require "./resource.rb"
require 'tilt/erb'


require_relative './authenticationHelper'
  
configure do
  DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite:///#{Dir.pwd}/database.db"))
  DataMapper.finalize
  DataMapper.auto_upgrade!	
end


get '/' do	
authorize!
	@users = User.all :order=> :id.desc
	erb :home
end

post '/' do	
    u=User.new
	u.name=params[:name]
	u.surname=params[:lastname]
	u.username=params[:username]
	u.password=params[:password]
	u.role=1
	u.save
	redirect '/'
end

get '/clicktocall' do
	erb :clicktocall
end
post '/clicktocall' do
	puts "*********************************"
	puts request.env['java.servlet_context']
	puts "********************************"
	puts request.env['java.servlet_request']
	puts "********************************"
	puts $servlet_context
	puts "***********************************"
	puts request.env['jruby.rack.version']
	puts "***********************************"
	puts request.env['jruby.rack.rack.release']
	puts "***************************************"
	puts request.env['jruby.rack.context']
	puts "**************************************"
	
	
     userReg=User.first(:id=>params[:clickToCallID].to_i)
     myReg = Registration.first(:user_id=>session[:user_id].to_i)
     
	 http_session = env['java.servlet_request'].session
	 app_session = http_session.application_session

	 @factory = http_session.servlet_context.getAttribute("javax.servlet.sip.SipFactory")
			
	if myReg
	puts "Found my registration"
		if userReg
			puts "Found called user"
			from_user = @factory.create_uri(myReg.location)
			
			puts userReg.id
			locations=Registration.all(:user_id=>userReg.id)
			
			if locations 
				inviteRequests=Array.new
				locations.each do |loc|
					puts loc.location
					callTo=@factory.create_uri(loc.location)
					newRequest=@factory.create_request(app_session,"INVITE",from_user,callTo)
					newRequest.add_header("ClickToCall","true")
					puts newRequest
					inviteRequests.push(newRequest)
				end
				app_session.set_attribute("inviteRequests",inviteRequests)
				inviteRequests.each do |request|
					request.session.set_attribute("inviteRequests",inviteRequests)
					request.send
						
				end
			else
			success="User is not online."
			end
		else
		success="Could not establish connection to user"
		end
	else
		flash.now[:errormessage]="Your SIP client is disconected"
    end
	redirect '/clicktocall'
end


