require 'rubygems'

require 'blinky'
require 'yaml'

def spawn_control_thread serial_number, project_name, config
  @blinky_controller ||= Blinky.new

  jenkins_opts = { user: config['username'], password: config['password'], include: project_name }
  light_for_project = @blinky_controller.lights.select{|l| l.serial_number == serial_number}.first
  Thread.new { light_for_project.watch_cctray_server "https://#{config['hostname']}/cc.xml", jenkins_opts }
end

config_file = "#{File.dirname __FILE__}/../config/jenkins.yml"
config = YAML.load_file config_file

config['thing1_mappings'].each do |serial_number, project_name|
  spawn_control_thread serial_number, project_name, config
end

while true do end # threads do all the work
