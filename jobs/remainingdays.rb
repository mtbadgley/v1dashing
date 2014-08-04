require_relative '../lib/v1remainingdays.rb'

current_remainingdays = 0

SCHEDULER.every '1m', first_in: 0 do |job|
	v1remainingdays = V1RemainingDays.new
	last_remainingdays = current_remainingdays
	current_remainingdays = v1remainingdays.GetRemainingDays("Scope:1093")
	send_event('remainingdays', { current: current_remainingdays, title: v1remainingdays.title, moreinfo: v1remainingdays.moreinfo })
end
