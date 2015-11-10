require 'rubygems'
require 'jrubycipango'

# ------ definicije servleta ------------------------------
require 'java'

#java_import 'javax.servlet.sip.SipServlet'
class MyServlet<Java::javax.servlet.sip.SipServlet

  def doRegister(request)
#get username
	begin
    user_name = request.to.uri.user
    puts "REGISTER: #{user_name}"
	
	#check username in database
    user = User.first(:username=>user_name)
    puts user if user

    #Register or deregister if user exists, or return error

    if user
	#check expire field
      expires = request.expires
      expires = request.getAddressHeader("contact").expires if expires == -1
      expires = request.get_address_header("contact").expires if expires == -1
      if expires == 0
        puts "DEREGISTRACIJA: #{user_name}"
        remote_location = nil 
      else
        puts "REGISTRACIJA: #{user_name}"
        remote_ip = request.remote_addr
        remote_port = request.remote_port
        remote_uri = "sip:#{user_name}@#{remote_ip}:#{remote_port}"
        puts remote_location
      end
       new_reg = Registration.first(:user_id=>user.id, :location => remote_uri)	
					new_date = Time.now+expires				
					if 	new_reg            
						  new_reg.update(:expire_time => new_date)
					else			 									
							new_reg = Registration.create(:user_id=>user.id, :location=>remote_uri, :registration_time=>Time.now, :expire_time => new_date)     
					end 						
					 new_reg.save										
		   	

	#send response
      request.create_response(200).send
    else
      resp = request.create_response(405)
      resp.send
    end
	rescue Exception => e
				puts "doBye rescue"	
				puts e.message		
			end
  end
  
  def doInvite(request)		
	proxy = request.get_proxy
	user_name = request.to.uri.user
	user=User.first(:username=>user_name)
	if user
		registrations=Registration.all(:user_id=>user.id, :expire_time.gt=>Time.now)
		locations=Array.new
		if registrations
			registrations.each do |reg|
				context = request.session.servlet_context
				f = context.get_attribute('javax.servlet.sip.SipFactory')
				uri = f.create_uri(reg.location)
				locations.push(uri)
				puts "Proxying to #{uri}"
			end
			proxy.create_proxy_branches(locations)
			proxy.start_proxy
			else
			request.create_response(480).send		
			end
		end
	end
	
	def doBye(request)
	puts "BYE from"
	begin
		puts "BYE from"
				b2b = request.get_b2bua_helper
			current_session = request.get_session
			session2 = b2b.get_linked_session(current_session)
			session2.create_request("BYE").send if session2
			request.create_response(200).send if request.session.is_valid
			rescue Exception => e
				puts "doBye rescue"	
				puts e.message		
			end
	end
	
def doSuccessResponse(response)
begin
	request=response.request
	
	if request.get_header("ClickToCall") != nil #Received response to ClickToCall
	puts "detektovan c2c"
		b2b = request.b2bua_helper
		c2cSession=response.session
		if response.request.get_header("SuccessResponse") == "OK"	
		puts "send acks"		
			orgResponse = response.request.session.get_attribute("org_response")	
			puts orgResponse			
			ack = response.create_ack
			orgAck = org_response.create_ack
			copy_msg_content(response, org_ack)		
			ack.send								
			orgAck.send				
		else	
		puts "reverse call"
			inviteRequests=response.request.session.get_attribute("inviteRequests")
			if inviteRequests && inviteRequests.count>0
				inviteRequests.each do |request|
					if response.request.to.uri != request.to.uri
					puts "cancel other locations calls"
						request.create_cancel.send
					end
				end
			end
			
			#replace from and to
			from=response.to.uri
			to=response.from.uri
			appSession=response.session.application_session
			newRequest=@factory.create_request(appSession,"INVITE",from,to)
			puts newRequest
			puts "reverse request created"
			b2bNewRequest=b2b.create_request(newRequest)
			newSession=b2bNewRequest.session
			newSession.set_attribute("org_response",response)
			b2bNewRequest.set_header("SuccessResponse","OK")
			copy_msg_content(response,b2bNewRequest)
			b2b.link_sip_sessions(c2cSession,newSession)
			puts "sessions linked"
			b2bNewRequest.send
		end
	else
	puts "odgovor na regularan poziv"
	super
	end
	rescue Exception => e
			puts "doSuccess rescue"
			puts e.message
	end	
		
end
	
	
	def init(config)
    super
    @context = config.servlet_context
    @factory = @context.get_attribute('javax.servlet.sip.SipFactory')
		@util = @context.get_attribute('javax.servlet.sip.SipSessionsUtil')
  end
	
	def doProvisionalResponse(resp)			
	end
	
	def doAck(req)
	end
	
	def doRequest(request)
		super
	end

  def doResponse(resp)  						
    super
  end
  
   private
  def copy_msg_content(request, dest)
    dest.content_type = request.content_type
    dest.set_content(request.raw_content, request.content_type)
    dest.content_length = request.content_length
  end
end