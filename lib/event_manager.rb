require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
reg_time_to_print = []
day_to_print = []
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_number(number)
  if number.length == 10
    "#{number[0]}#{number[1]}#{number[2]}-#{number[3]}#{number[4]}#{number[5]}-#{number[6]}#{number[7]}#{number[8]}#{number[9]}"
  elsif number.length == 10 && number[0] == 1
    number = number[1..10]
  else
    number = "No number"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  number = clean_number(row[:homephone].gsub(/[^0-9]/, ""))
  zipcode = clean_zipcode(row[:zipcode])
  reg_time = row[:regdate]
  #legislators = legislators_by_zipcode(zipcode)

  #form_letter = erb_template.result(binding)

  #save_thank_you_letter(id,form_letter)
 
  reg_time_to_print.push(DateTime.strptime(reg_time,"%m/%d/%y %H:%M").hour)
  day_to_print.push(DateTime.strptime(reg_time,"%m/%d/%y %H:%M").wday.to_s
  .gsub("0", "Sun")
  .gsub("1", "Mon")
  .gsub("2", "Tue")
  .gsub("3", "Wed")
  .gsub("4", "Thu")
  .gsub("5", "Fri")
  .gsub("6", "Sat")
  )

  #puts "#{name} #{reg_time_to_print}"
end

#Manages the count of peak hours
popular_time = Hash.new(0)
reg_time_to_print.each {|time| popular_time[time] += 1}
p "The most popular hour for registration is: #{popular_time.sort_by { |time,number| number}.last[0]}"

popular_day = Hash.new(0)
day_to_print.each {|day| popular_day[day] += 1}
p "The most popular day is:#{popular_day.sort_by {|day, number| number}.last[0]}"

