#!/usr/bin/env ruby
##this script will upload all filesfrom a folder to rackspace Cloud files account
#
require 'rubygems'
require 'cloudfiles'
require 'optparse'
require 'fileutils'

#init cloud conecction to rackspace
def init_could(username,key)
 
 begin
        cf = CloudFiles::Connection.new(:username => username, :api_key => key)
 rescue CloudFiles::Exception::Authentication
	STDERR.puts "Not authenticated"
        exit
 rescue CloudFiles::Exception::ExpiredAuthToken
	STDERR.puts "Token Expired"
        exit
 rescue CloudFiles::Exception::Connection
	STDERR.puts "Connection Error, Aborted"
        exit
 rescue CloudFiles::Exception::InvalidResponse
	STDERR.puts "Invalid response"
        exit
 end

 return cf
end
#verify that container exists if not created it
def check_container(name)
  begin
     container=CF.container(name)
     container.make_public unless container.cdn_enabled?
     puts container.cdn_url if container.cdn_enabled?
     count=container.count
  rescue CloudFiles::Exception::NoSuchContainer
     container=CF.create_container(name)
     container.make_public
     count=container.count
  rescue CloudFiles::Exception::InvalidResponse
	STDERR.puts "FAIL: Invalid response container"
        exit
  end
        return count
end
#publish file to container
def publish(file,target_name,container)
   begin
        container = CF.container(container)
        object = container.create_object target_name, false
        file=File.read(file)
        object.write file
        return object.public_url
   rescue CloudFiles::Exception::InvalidResponse
	 STDERR.puts "FAIL: Invalid response publish"
        return nil
   end
end
#read files from a folder
def read_files(file_path)
	list=Dir.entries(file_path)
	return list
end
options={}
option_parser = OptionParser.new do |opts|
 executable_name = File.basename($PROGRAM_NAME)
  opts.banner = "Usage: #{executable_name} [options] folder name"

  executable_name = File.basename($PROGRAM_NAME)
  opts.banner = "Copy files from folder to Cloud
  
  Usage: #{executable_name} [options]
  "
  opts.on('-f folder','Indicate folder to be copied') do |folder_name|
    options[:folder_name] = folder_name
  end
  opts.on('-u user','Rackspace user name') do |username|
    options[:username] = username
  end
  opts.on('-k key','Rackspace API key') do |apikey|
    options[:apikey] = apikey
  end
  opts.on('-c container','Rackspace container') do |container|
   options[:container] = container
  end
 
end
#read options switches
begin
  option_parser.parse!
  if options.empty?
    puts "error: you must supply folder, container, username and apikey"
    puts
    puts option_parser.help
    exit 1
  else
    container = options[:container]
    apikey = options[:apikey]
    username = options[:username]
    folder_name = options[:folder_name]
  end
    rescue OptionParser::InvalidArgument => ex
         STDERR.puts ex.message
         STDERR.puts option_parser
end

#Initialize cloud
CF=init_could(username,apikey)

#set variable values
count=0
unless check_container(container)==995
        #Read all contents from target folder
	Dir.foreach(folder_name) do |wfile|
		unless File::directory?(wfile)
			publish(folder_name + '/' + wfile,wfile,container)
			count+=1
		end
	end
	puts count.to_s + " files uploaded to container " + container
else

puts 'Container error over 1000 files'

end
