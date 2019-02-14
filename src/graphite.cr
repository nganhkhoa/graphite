require "option_parser"
require "yaml"
require "./Setting"
require "./Utils"

VERSION = "0.1.0"

def cliParser

  settingFile = "setting.yml"

  OptionParser.parse! do |parser|
    parser.banner = "Usage ./graphite [options] [command]"
    parser.on("-h", "--help", "Display help") { puts parser; exit }
    parser.on("-v", "--version", "Display version") { puts VERSION; exit }
    parser.on("-s FILE", "--setting FILE", "Specify the setting file, setting.yml on default") { |f| settingFile=f }
  end

  if ARGV.size == 0
    puts "No command specified"
    exit
  end

  { settingFile, ARGV.shift.downcase, ARGV }
end

module Graphite
  settingFile, task, argv = cliParser()
  puts "Using setting file: #{settingFile}"
  puts "Task: #{task}"
  puts "Argv: #{argv}"

  unless (File.file?(settingFile))
    puts "No setting file found"
    exit
  end

  unless commandExists("git")
    puts "git not found"
    exit
  end

  setting = Setting.from_yaml(File.read(settingFile))
  setting.run(task, argv)

end
