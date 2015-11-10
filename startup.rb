require 'rubygems'
require 'java'
require 'jrubycipango'

require './sip_servlet.rb'

ip_address = ARGV[0] || "0.0.0.0"

params={
  :host_ip_address => ip_address , 
  :http_port => 8080
}


server = JRubyCipango::CipangoServer.new  params   
server.add_sip_servlet MyServlet.new    
server.add_rackup                          

server.start


