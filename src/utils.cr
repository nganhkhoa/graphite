def createFolder(folders)
  folders.each do |folder|
    Dir.mkdir(folder) if !Dir.exists?(folder)
  end
end

def commandExists(command : String)
  s = Process.find_executable(command) ? true : false
  # s, _ = runCommandWithArgs("command", ["-v", command])
  # s = system("command", ["-v", command, ">", "/dev/null"])
  s
end

def commandExists(commands : Array(String))
  not_found_command = [] of String
  commands.each do |command|
    not_found_command << command unless commandExists(command)
  end
  not_found_command
end

def runCommandWithArgs(cmd, argv, folder = Dir.current)
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  s = Process.run(
    cmd, argv,
    output: stdout, error: stderr,
    chdir: folder
  )
  { s.success?, stdout.to_s, stderr.to_s }
end

def defineWorkingSet(apps : Array(App), argv : Array(String))
  # keep only apps that matches name in argv
  if !argv.empty?
    apps.reject! do |app|
      app unless argv.any?(app.name)
    end
  end

  # matches app dependencies with other app
  apps.each do |app|
    puts app.name
    app.dependencies.map! do |n|
      apps.find(n) { |a| a.name == n }
    end
  end

  # resolve dependencies by topological sorting
  apps
end
