#!/usr/bin/env ruby

require 'rubygems'
require 'flowdock'
require 'json'
require 'optparse'
require 'date'
require 'colorize'

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: flowdock.rb --user=<github user> --api-token=<flowdock token> --organization=<flowdock organization> --flow=<flow>\n
                 Used for retrieving github history from flowdock"
  opts.on("--api-token APITOKEN]", "Provide personal api token created here: https://flowdock.com/account/tokens ") do |a|
    options[:api_token] = a
  end
  opts.on("--organization ORG", "Name of your organization - you can get it from flowdock app URL") do |o|
    options[:organization] = o
  end
  opts.on("--flow FLOW", "Name of the flow - you can get it from flowdock app URL") do |f|
    options[:flow] = f
  end
  opts.on("--user USER", "Your github user") do |u|
    options[:user] = u
  end
  opts.on("-v", "--verbose", "Enable verbosity") do |v|
    options[:verbose] = v
  end
  opts.on("-n", "--number-of-messages NUMMESSAGES", Integer, "Number of messages to retrieve - default = 100") do |n|
    options[:number] = n
  end
  opts.on("-t", "--timezone-offset TIMEOFFSET", String, "Offset from UTC time to add/subtract when showing time") do |t|
    options[:timeoffset] = t
  end
  opts.on("-r", "--reverse-sort", "Reverse sort of messages (from descending to ascending)") do |s|
    options[:sort] = s
  end
end.parse!

if not options[:api_token] or not options[:organization] or not options[:user] or not options[:flow]
  puts "Please run with --help"
  exit
end

if not options[:number]
  options[:number] = 100
else
  puts "Getting no. of #{options[:number]} messages"
end

if options[:verbose]
  puts "Using api_token: '#{options[:api_token]}'"
end

api_token_client = Flowdock::Client.new(api_token: options[:api_token])
last_id_msg_url = "/flows/#{options[:organization]}/#{options[:flow]}/messages?app=influx&limit=1"

flow_last_msg_id = api_token_client.get(last_id_msg_url)[0]["id"].to_i

puts "Last msg: #{flow_last_msg_id}"

if options[:number] >= 100
  num_requests = (options[:number] / 100.0).ceil
  flow_messages = []
  until_id = (flow_last_msg_id - (num_requests * 100)) + 100
  puts "More than 100 messages specified - using pagination with #{num_requests} requests"
  num_requests.times do
    flow_url = "/flows/#{options[:organization]}/#{options[:flow]}/messages?app=influx&limit=100&search=#{options[:user]}&until_id=#{until_id}&event=activity"
    if options[:verbose]
      puts "Making request until ID #{until_id} on URL #{flow_url}"
    end
    flow_messages = flow_messages + api_token_client.get(flow_url)
    until_id += 100
  end
else
  flow_url = "/flows/#{options[:organization]}/#{options[:flow]}/messages?app=influx&limit=#{options[:number]}?search=#{options[:user]}"
  flow_messages = api_token_client.get(flow_url)
end

flow_messages = flow_messages.uniq

flow_messages = flow_messages.sort_by { |k| k["id"] }

if options[:sort]
  flow_messages = flow_messages.reverse
end

if options[:verbose]
  puts JSON.pretty_generate(flow_messages)
end

# this is final structure
days_events = {}

flow_messages.each do |message|
  # rewrite list of messages and index them by date
  begin
    author = message['author']['name']
  rescue
    author = ''
  end
    # iterate over messages that have proper author supplied in args
    # create following structure:
    # for every date have a list of tickets with list of events for every ticket
    #
    if author == options[:user]
      begin
        created_at = Date.parse( message['created_at']).to_s
        title = message['thread']['title']

        id = message['id']

        if !days_events.has_key? created_at
          # add entry for the day if doesnt exist
          days_events[created_at] = {}
        end

        if !days_events[created_at].has_key? title
          days_events[created_at][title] = {}
        end

        days_events[created_at][title][id] = {}

        if options[:timeoffset]
          time_details = DateTime.parse(message['created_at']).to_time
          time_offset_seconds = (60 * 60 *  options[:timeoffset].to_i)
          time_details = time_details + time_offset_seconds
          timezone = "UTC #{options[:timeoffset].to_s}"
        else
          time_details = DateTime.parse(message['created_at']).to_time
          puts "Using UTC timezone"
          timezone = 'UTC'
        end

        hour = time_details.strftime("%H")
        minute = time_details.strftime("%M")
        second = time_details.strftime("%S")

        days_events[created_at][title][id]['title_message'] = message['title'] || ''
        days_events[created_at][title][id]['time_of_day'] = "#{hour}:#{minute}:#{second} (#{timezone} timezone)"
        days_events[created_at][title][id]['url'] = message['thread']['external_url']
        days_events[created_at][title][id]['source'] = message['thread']['source']['application']['name']
        days_events[created_at][title][id]['body'] = message['body'].gsub(/<\/?[^>]*>/, "")

      rescue Exception => e
        puts "Couldnt get all arguments from message"
        raise e
      end
    end
end

days_events.each_pair do |day, events|
  puts ""
  puts "BEGINNING OF DATE: #{day}".green
  events.each_pair do |event_title, event_events|
    puts "  -> Activity name: #{event_title}".colorize(:color => :light_blue).underline
    event_events.each_pair do |event_id, event_data|
      puts "    * Activity id: #{event_id}".to_s.colorize(:color => :blue)
      puts "     * source : #{event_data['source']}"
      puts "     * time   : #{event_data['time_of_day']}"
      puts "     * url    : #{event_data['url']}"
      if !event_data['body'].empty?
        puts "     * message: #{event_data['body'][0..250].colorize(:color => :white)} [...]"
      end
      if !event_data['title_message'].empty?
        puts "     * details: #{event_data['title_message'].gsub(/<\/?[^>]*>/, "")}"
      end
    end
  end
  puts "END OF DATE: #{day}".green
end

def extract_repo_fromo_fields(fields)
  # accept list of Hashes
  fields.each do |field|
    if field['label'] == 'repository'
      return field['value'].gsub(/<\/?[^>]*>/, "")
    end
  end
end
