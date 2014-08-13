#!/usr/bin/ruby

# Update the username, password, and baseurl
class V1conn
	def initialize
		@user = "andre"
		@pass = "andre"
		@auth = {:username => user, :password => pass}
		@baseurl = "http://win8/VersionOne"
	end

	attr_accessor :user
	attr_accessor :pass
	attr_accessor :auth
	attr_accessor :baseurl
end