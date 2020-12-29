require 'csv'
require 'byebug'
require 'pry-byebug'
require 'open-uri'
require 'yaml'
require_relative './sheets.rb'


uri = 'https://www.officepools.com/nhl/classic/298729/data-2019.10.11.07.08.08.178734.js'
res = open(uri).read.split("pointsMonth")[1]
    
groups = res.scan(/~[^~]+(?!~)/)
groups_array = Array.new

today = Time.now.strftime("%m/%d/%Y")

# last two regex matches are garbage
groups.first(groups.size - 2).each do |group|
  group = group.split("|")
  name = group[1] 
  point_total = group[group.size - 2]
  games_played = group[81]
  groups_array << { name: name, point_total: point_total, games_played: games_played }
end

groups_array.sort! { |a,b| a[:name] <=> b[:name] }


###

spreadsheet_id = '1z7tjr4iEbtDA8T1VttGg2IYyAkKA_mVAi8qGVfhUS_o'

service = Sheets.service
s = service.get_spreadsheet(spreadsheet_id)

last_row = YAML.load(File.read("last_row.yaml"))
response = service.get_spreadsheet_values(spreadsheet_id, "A#{last_row['last_row']}:A#{last_row['last_row']}")

if response.values[0][0] == today
  p "Values already exist for this date, exiting."
  exit(true)
end

total_points_row = [today]
groups_array.each { |group| total_points_row << group[:point_total] }

value_range = Google::Apis::SheetsV4::ValueRange.new(values: [total_points_row])

result = service.append_spreadsheet_value(spreadsheet_id, 'total!A1:AA1', value_range, value_input_option: 'USER_ENTERED')

ppg_row = [today]
groups_array.each { |group| ppg_row << '%.2f' % (group[:point_total].to_f / group[:games_played].to_f) }

value_range = Google::Apis::SheetsV4::ValueRange.new(values: [ppg_row])

result = service.append_spreadsheet_value(spreadsheet_id, 'ppg!A1:AA1', value_range, value_input_option: 'USER_ENTERED')

last_row['last_row'] = result.updates.updated_range.scan(/\d/).first
File.open('last_row.yaml', 'w') { |file| file.write(last_row.to_yaml) }