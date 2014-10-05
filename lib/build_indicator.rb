require 'rubygems'

require 'blinky'
require 'optparse'
require 'yaml'

def list_lights
  begin
    blinky_controller.lights.each do |light|
      puts light.serial_number
    end
  rescue Blinky::NoSupportedDevicesFound
    puts 'No lights found!'
  end
end

def run_server
  config_file = "#{File.dirname __FILE__}/../config/jenkins.yml"
  config = YAML.load_file config_file

  config['blink1_mappings'].each do |serial_number, project_name|
    spawn_control_thread serial_number, project_name, config
  end
  while true do end # threads do all the work
end

def spawn_control_thread serial_number, project_name, config
  light_for_project = blinky_controller.lights.select{|l| l.serial_number == serial_number}.first
  jenkins_opts = { user: config['username'], password: config['password'], include: project_name }
  cctray_url = "https://#{config['hostname']}/cc.xml"
  Thread.new { light_for_project.watch_cctray_server cctray_url, jenkins_opts }
end

def blinky_controller
  @blinky_controller ||= Blinky.new
end

options = {}
opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"
  opts.on("-s", "--server", "Start listener server")         { |v| options[:mode] = :server }
  opts.on("-l", "--list",   "List visible blink(1) serials") { |v| options[:mode] = :list }
end
opt_parser.parse!

case options[:mode]
  when :list
    list_lights
  when :server
    run_server
  else
    puts opt_parser
    exit 1
end

