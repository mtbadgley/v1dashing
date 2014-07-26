require 'json'
require_relative '../lib/v1velocitytrend.rb'

SCHEDULER.every '1m', first_in: 0 do |job|
  v1velocitytrend = V1VelocityTrend.new
  data = v1velocitytrend.GetVelocityTrend("Scope:1093","",3)

  datax = JSON.parse(data)
  send_event('velocitytrend', points: datax)
end