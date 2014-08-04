require 'HTTParty'
require 'json'
require 'date'
require_relative './v1conn.rb'

class V1Conversations
	$v1conn = V1conn.new
	$v1queryurl = "#{$v1conn.baseurl}/query.v1"

	def GetAvatarUrl(oid,contenttype)
		
		fileext = ".png"
		if contenttype.include? "jpeg"
			fileext = ".jpg"
		elsif contenttype.include? "jpg"
			fileext = ".jpg"
		end

		filename = oid.split(":")[1]
		filepath = "public/avatar/#{filename}#{fileext}"
		fileurl = "./avatar/#{filename}#{fileext}"

		image = "#{$v1conn.baseurl}/image.img/#{filename}"
		if !File.file?(filepath)
			file = File.open(filepath, "wb") do |f|
				f.write HTTParty.get(image, :basic_auth => $v1conn.auth)
			end
		end
		return fileurl
	end

	def GetConversations(teamoid)

		query = '[{
					"from": "Expression",
					"select": [ "Author.Name",
					"Author.Avatar.ID",
					"Author.Avatar.ContentType", 
					"Content", 
					"AuthoredAt" ],
					"filter": [ "Conversation.Room.Team=\'' + teamoid + '\'" ],
					"sort": "-AuthoredAt",
					"page": { "start" : 0, "size": 10 }
				}]'

		queryresult = HTTParty.get($v1queryurl, :body => query, :basic_auth => $v1conn.auth, :output => 'json')
		conversations = queryresult[0]

		comments = ""

		conversations.each do |conversation|
			name = conversation["Author.Name"]
			content = conversation["Content"]
			avatarcontenttype = conversation["Author.Avatar.ContentType"]
			avataroid = conversation["Author.Avatar.ID"]["_oid"]
			avatarurl = GetAvatarUrl(avataroid, avatarcontenttype)
			comment = '{ "name": "' + name + '", "body": "' + content + '", "avatar": "' + avatarurl + '" },'
			comments += comment
		end


		if comments.length > 0
			comments = "[ " + comments[0..-2] + " ]"
		end 
		
		return comments
	end
end
