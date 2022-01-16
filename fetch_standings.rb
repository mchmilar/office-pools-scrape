# require 'nokogiri'
require 'csv'
# require 'byebug'
# require 'pry-byebug'
require 'open-uri'

uri = 'https://www.officepools.com/nhl/classic/298729/data-2019.10.11.07.08.08.178734.js'
res = open(uri).read.split("pointsMonth")[1]
    
groups = res.scan(/~[^~]+(?!~)/)
groups_array = Array.new

today = Time.now.strftime("%Y-%m-%d")

# last two regex matches are garbage
groups.first(groups.size - 2).each do |group|
  group = group.split("|")
  name = group[1] 
  point_total = group[group.size - 2]
  games_played = group[81]
  groups_array << { name: name, point_total: point_total, games_played: games_played }
end

groups_array.sort! { |a,b| a[:name] <=> b[:name] }

timestamp = Time.now.to_s.split(' ').first(2).join('-')

CSV.open("./points-per-game/#{today}.csv", 'w+') do |csv|
  csv << ['name', 'points_per_game']
  groups_array.each do |group|
    csv << [group[:name], '%.2f' % (group[:point_total].to_f / group[:games_played].to_f)]
  end
end

CSV.open("./total-points/#{today}.csv", 'w+') do |csv|
  csv << ['name', 'point_total']
  groups_array.each do |group|
    csv << [group[:name], group[:point_total]]
  end
end

CSV.open('ppg-season.csv', 'a') do |csv|
  # header = ['Date']
  # groups_array.each { |group| header << group[:name] }
  # csv << header

  todays_row = [today]
  groups_array.each { |group| todays_row << '%.2f' % (group[:point_total].to_f / group[:games_played].to_f) }
  csv << todays_row
end

CSV.open('total-season.csv', 'a') do |csv|
  # header = ['Date']
  # groups_array.each { |group| header << group[:name] }
  # csv << header

  todays_row = [today]
  groups_array.each { |group| todays_row << group[:point_total] }
  csv << todays_row
end
