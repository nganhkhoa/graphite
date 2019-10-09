require "option_parser"
require "yaml"
require "./setting"
require "./utils"
require "./worker"

VERSION = "0.1.0"

def cliParser

  settingFile = File.expand_path("~/.config/graphite/setting.yml")

  OptionParser.parse! do |parser|
    parser.banner = "Usage ./graphite [options] [command]"
    parser.on("-s FILE", "--setting=FILE", "Set setting file") { |f| settingFile = File.expand_path(f) }
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
  puts settingFile
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

  rootFolder = File.expand_path("~/.config/graphite")
  binFolder = "./bin"
  libFolder = "./lib"
  appFolder = "./app"
  includeFolder = "./include"

  puts "Moving to working folder: #{rootFolder}"
  Dir.cd(rootFolder)
  createFolder([
    rootFolder,
    appFolder, binFolder, libFolder, includeFolder
  ])

  puts "Load setting file"
  # TODO: Catch error
  setting = Setting.from_yaml(File.read(settingFile))
  apps = setting.apps

  puts "Setup temporary path"
  # setting up path
  # if need to use new binary installed
  # this is temporary, no need to modify path before
  # some path doesn't have
  old_path       = ENV["PATH"].clone()
  old_ld_library = ENV["LD_LIBRARY_PATH"].clone()
  old_library    = ENV["LIBRARY_PATH"].clone()
  ENV["PATH"] += ":" + File.expand_path(binFolder)
  ENV["LD_LIBRARY_PATH"] += ":" + File.expand_path(libFolder)
  ENV["LIBRARY_PATH"] += ":" + File.expand_path(includeFolder)

  # puts ENV["PATH"]
  # puts ENV["LD_LIBRARY_PATH"]
  # puts ENV["LIBRARY_PATH"]

  puts "========================================"
  apps = defineWorkingSet(apps, argv)
  apps.each do |app|
    puts app.name
    puts app.dependencies
    puts "======"
  end
  puts "Routine complete"

  puts "Restore temporary path"
  # restore path
  ENV["PATH"]            = old_path
  ENV["LD_LIBRARY_PATH"] = old_ld_library
  ENV["LIBRARY_PATH"]    = old_library

end
