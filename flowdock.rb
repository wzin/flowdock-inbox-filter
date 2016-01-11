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
  until_id = (flow_last_msg_id - (num_requests * options[:number]) + 100)
  puts "More than 100 messages specified - using pagination with #{num_requests} requests"
  num_requests.times do
    flow_url = "/flows/#{options[:organization]}/#{options[:flow]}/messages?app=influx&limit=100&search=#{options[:user]}&until_id=#{until_id}&event=activity"
    if options[:verbose]
      puts "Making request since ID #{until_id} on URL #{flow_url}"
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

flow_messages.each do |message|
  begin
    author = message['author']['name']
  rescue
    author = ''
  end
    if author == options[:user]
      begin
        id = message['id']
        body = message['body'].gsub(/<\/?[^>]*>/, "")
        source = message['thread']['source']['application']['name']
        title = message['thread']['title']
        external_url = message['thread']['external_url']
        created_at = Date.parse( message['created_at']).to_s
        puts "date: #{created_at}".green
        puts "   id: #{id}".blue
        puts "   source: #{source}".blue
        puts "   title: #{title}".blue
        puts "   url: #{external_url}".blue
        if !body.empty?
          puts "   message:      #{body}"
        end
        puts " "
      rescue
        puts "Couldnt get all arguments from message"
      end
    end
end
