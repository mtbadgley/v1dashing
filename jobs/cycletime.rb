require_relative '../lib/v1cycletime.rb'

current_cycletime = 0.0

SCHEDULER.every '1m', :first_in => 0 do |job|
  v1cycletime = V1CycleTime.new
  last_cycletime = current_cycletime
  current_cycletime = v1cycletime.GetRollingCycleTime(21,'Scope:1093','In Progress','Accepted').round(1)
  send_event('cycletime', { current: current_cycletime, last: last_cycletime, moreinfo: "In Progres > Accepted" })
end