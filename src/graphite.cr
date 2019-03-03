require "option_parser"
require "yaml"
require "./setting"
require "./utils"
require "./worker"

VERSION = "0.1.0"

def cliParser

  settingFile = "setting.yml"

  OptionParser.parse! do |parser|
    parser.banner = "Usage ./graphite [options] [command]"
    parser.on("-h", "--help", "Display help") { puts parser; exit }
    parser.on("-v", "--version", "Display version") { puts VERSION; exit }
  end

  if ARGV.size == 0
    puts "No command specified"
    exit
  end

  ARGV.map! { |arg| arg.downcase }

  { settingFile, ARGV.shift.downcase, ARGV }
end

module Graphite
  settingFile, task, argv = cliParser()
  unless (File.file?(settingFile))
    puts "No setting file found"
    exit
  end

  unless commandExists("git")
    puts "git not found"
    exit
  end

  puts "Setting file found: #{settingFile}"
  puts "Task: #{task}"
  puts "Argv: #{argv}"
  binFolder = "./bin"
  libFolder = "./lib"
  appFolder = "./app"
  includeFolder = "./include"
  createFolder([
    appFolder, binFolder, libFolder, includeFolder
  ])

  setting = Setting.from_yaml(File.read(settingFile))
  apps = setting.apps

  # setting up path
  # if need to use new binary installed
  # this is temporary, no need to modify path before
  old_path       = ENV["PATH"].clone()
  old_ld_library = ENV["LD_LIBRARY_PATH"].clone()
  old_library    = ENV["LIBRARY_PATH"].clone()
  ENV["PATH"] += ":" + File.expand_path(binFolder)
  ENV["LD_LIBRARY_PATH"] += ":" + File.expand_path(libFolder)
  ENV["LIBRARY_PATH"] += ":" + File.expand_path(includeFolder)

  # puts ENV["PATH"]
  # puts ENV["LD_LIBRARY_PATH"]
  # puts ENV["LIBRARY_PATH"]

  worker = createWorker(task, argv)
  apps.each do |app|
    worker.call(app)
  end

  # restore path
  ENV["PATH"]            = old_path
  ENV["LD_LIBRARY_PATH"] = old_ld_library
  ENV["LIBRARY_PATH"]    = old_library

end
