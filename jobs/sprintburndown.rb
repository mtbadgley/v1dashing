require 'json'
require_relative '../lib/v1sprintburndown.rb'

SCHEDULER.every '1m', first_in: 0 do |job|
	v1sprintburndown = V1SprintBurndown.new
	data = v1sprintburndown.GetBurndownPoints("Scope:1093","")
	datax = JSON.parse(data)
	send_event('burndownchart', points: datax, title: v1sprintburndown.title)
end