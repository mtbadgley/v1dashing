require 'json'
require_relative '../lib/v1conversations.rb'

SCHEDULER.every '20s', first_in: 0 do |job|
	v1conversations = V1Conversations.new
	data = v1conversations.GetConversations("Team:1109")
	datax = JSON.parse(data)
	send_event('conversations', comments: datax )
end