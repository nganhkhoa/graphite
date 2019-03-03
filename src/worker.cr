require "./setting"
require "./utils"
require "./network"

def createWorker(task, argv)
  empty = ->(app : App, s : String) { }
  installProc = ->install(App, String)
  buildProc = ->build(App, String)
  symlinkProc = ->symlink(App, String)
  worker = ->(
    install : Proc(App, String, Bool) | Proc(App, String, Nil),
    build : Proc(App, String, Nil),
    symlink : Proc(App, String, Nil)
  ) {
    # argv is closure from scope
    ->(app : App) {
      unless enterRoutine app, task, argv
        exitRoutine
        return
      end
      installFolder = "./app/#{app.name}"
      buildFolder = "#{installFolder}/#{app.buildFolder}"
      hasUpdate = install.call(app, installFolder)
      if !hasUpdate.nil? && !hasUpdate
        exitRoutine
        return
      end
      build.call(app, buildFolder)
      symlink.call(app, installFolder)
      exitRoutine
    }
  }
  case task
  when "install", "reinstall", "update"
    worker.call(installProc, buildProc, symlinkProc)
  when "build"
    worker.call(empty, buildProc, empty)
  when "symlink"
    worker.call(empty, empty, symlinkProc)
  else
    worker.call(empty, empty, empty)
  end
end

def enterRoutine(app, task, argv)
  puts "Processing #{task} #{app.name}"
  if app.skip
    puts "skip by setting"
    return false
  end
  if argv.size > 0
    obj = argv.find { |x| x == app.name }
    if obj.nil?
      puts "skip by args"
      return false
    end
  end
  case task
  when "install", "reinstall", "update"
    true
  else
    false if !File.exists?("./app/#{app.name}")
    true
  end
end

def exitRoutine
  puts "========================================"
end

def clone(gitUrl, branch, folder, singleBranch = false)
  argv = ["clone", gitUrl, "--branch", branch]
  argv << "--single-branch" if singleBranch
  argv << folder
  puts "git #{argv}"
  success, log, err = runCommandWithArgs("git", argv)
  success
end

def tryPull(folder)
  argv = ["-C", folder, "remote", "update"]
  runCommandWithArgs("git", argv)
  argv = ["-C", folder, "status", "-sb"]
  _, status, err = runCommandWithArgs("git", argv)
  return false if status.match(/not a git repository/)
  return false unless status.match(/behind/)
  puts "Detect behind, doing a git merge"
  argv = ["-C", folder, "merge"]
  success, log, err = runCommandWithArgs("git", argv)
  success
end

def install(app : App, installFolder)
  return update(app, installFolder) if Dir.exists?(installFolder)

  if app.git.blank? && !app.targz.blank?
    extractedDirectory = getTargzAndExtract(app.targz)
    File.rename(extractedDirectory, installFolder)
    return false
  end

  branch = app.branch
  unless app.tag.blank?
    if app.tag == "latest"
      # fetch Github API / Gitlab API for latest tag?
      # or clone and checkout the latest tag?
      branch = "latest"
    elsif app.tag =~ /^v\d+.\d+.\d+/
      branch = app.tag
    end
  end

  puts "Cloning #{app.name} to #{installFolder}"
  return clone(app.git, branch, installFolder, app.singleBranch)
end

def update(app : App, installFolder)
  tryPull installFolder
end

def hasCommandsOrExefile(cmd, folder)
  exeFound = Process.find_executable(cmd)
  fileFound = File.exists?("#{folder}/#{cmd}")
  true if exeFound || fileFound
  false
end

def getTargzAndExtract(url)
  tempname = File.tempname()
  tempfile = tempname + ".tar.gz"
  unarchivePath = tempname

  puts "Get targz #{tempfile}"
  downloadFollowRedirect(url, tempfile)

  puts "Untar #{tempfile} at #{unarchivePath}"
  runCommandWithArgs("rm", ["-rf", "#{unarchivePath}"], Dir.tempdir) if Dir.exists?(unarchivePath)
  Dir.mkdir(unarchivePath)
  runCommandWithArgs("tar", ["-C", "#{unarchivePath}", "-xzvf", "#{tempfile}"], Dir.tempdir)

  if Dir.children(unarchivePath).size == 1
    # untar gets a folder
    extractedDirectory = unarchivePath + "/" + Dir.children(unarchivePath)[0]
  else
    # untar gets a list of files/folders
    extractedDirectory = unarchivePath
  end
  # File.delete(tempfile)
  extractedDirectory
end

def resolveSelfRequire(url, fallbackCommands)
  puts "Resolving self required commands"
  extractedDirectory = getTargzAndExtract(url)
  # add fallback command folder to path
  fallbackCommandPathList = [] of String
  fallbackCommands.each do |cmd, untarpath|
    fallbackCommandPath = extractedDirectory + "/" + untarpath
    next if fallbackCommandPathList.find { |x| x == fallbackCommandPath }
    fallbackCommandPathList << fallbackCommandPath

    unless File.exists?(fallbackCommandPath)
      puts "Command path returns null after extract"
      return false
    end
    unless File.directory?(fallbackCommandPath)
      fallbackCommandPath = File.dirname(fallbackCommandPath)
    end
    ENV["PATH"] += ":" + fallbackCommandPath
  end
  true
end

def build(app : App, buildFolder)
  oldpath = ENV["PATH"].clone()
  requireSelf = app.requireSelf
  targz = app.targz

  requireSelf.each do |cmd, path|
    status = hasCommandsOrExefile(cmd, buildFolder)
    unless status
      # no command is found either in PATH or file
      resolveSelfRequire(targz, requireSelf)
    end
  end

  Dir.mkdir(buildFolder) if !Dir.exists?(buildFolder)
  app.build.each do |command|
    command = command.gsub("$pwd", buildFolder)
    commandString = command.split(" ")
    cmd = commandString.first
    argv = commandString.skip(1)

    puts "#{buildFolder}: #{cmd} #{argv}"
    success, stdout, stderr = runCommandWithArgs(cmd, argv, buildFolder)
    case success
    when true
      puts "Success"
      # write to log file
    when false
      puts "Error"
      puts "STDERR"
      puts stderr
    end
  end
  ENV["PATH"] = oldpath
  puts "Build Complete"
end

def createSymlink(folder, patternArray, target)
  return if patternArray.nil?
  patternArray.each do |pattern|
    puts "#{folder}/#{pattern}"
    files = Dir.glob("#{folder}" + "/#{pattern}")
    files.each do |file|
      symlink_file = "#{target}/#{File.basename(file)}"
      puts "#{file} --> #{symlink_file}"
      isSymlink? = File.symlink?(symlink_file)
      isExists? = File.exists?(symlink_file)
      if isSymlink? || isExists?
        File.delete(symlink_file)
      end
      File.symlink(File.expand_path(file), symlink_file)
    end
  end
end

def symlink(app : App, installFolder)
  symlink = app.symlink
  bin_pattern = symlink["bin"]?
  lib_pattern = symlink["lib"]?
  include_pattern = symlink["include"]?

  puts "Create symlink"
  createSymlink(installFolder, bin_pattern, "./bin")
  createSymlink(installFolder, lib_pattern, "./lib")
  createSymlink(installFolder, include_pattern, "./include")
end
