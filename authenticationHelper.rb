require 'sinatra/base'
module Sinatra
  module SessionAuth
    module Helpers
    	def current_user
    		@current_user||=(session[:user_id])? User.first(:id=>session[:user_id]) : nil
    	end
			def authorize_admin!									
			  redirect '/login' unless authorized? && current_user.role == 1
			end
      def authorized?
        session[:authorized]
      end
      
      def authorize!
        redirect '/login' unless authorized?
      end
      
      def signout!
        session[:authorized] = false
        session[:user_id]=0
      end
    end

   def self.registered(app)
      app.helpers SessionAuth::Helpers
      
      app.get '/login' do
        erb :login, layout:false
      end
      
      app.get '/signup' do
        erb :signup, layout:false
      end
      
      app.post '/login' do
      	user=User.first(:username=>params[:username].strip, :password=> params[:password].strip)
        if user
          session[:authorized] = true
          session[:user_id]=user.id
          redirect '/'
        else
          signout!
          flash.now[:error]="Your username or password is wrong."
          erb :login, layout:false
        end
      end
      
     app.post '/signup' do
					#role=1;
					#if(params[:name][:username].strip=='admin')
					#		role = 1
					#end
			
      
      #	user=User.create(:username=>params[:username], :password=> params[:password], :name=>params[:name], :surname=>params[:surname], :role=>role)
		u=User.new
		u.name=params[:name]
		u.surname=params[:lastname]
		u.username=params[:username]
		u.password=params[:password]
		u.role=1
		u.save
		
        if u.saved?
          session[:authorized] = true
          session[:user_id]=u.id
          redirect '/'
        else	       
		puts "ne valja"
        	flash.now[:errors]=u.errors
          erb :signup, layout:false
        end
      end
      
      app.get "/signout" do
        signout!
        redirect "/"
      end

    end
  end
  register SessionAuth
end
