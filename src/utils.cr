def createFolder(folders)
  folders.each do |folder|
    Dir.mkdir(folder) if !Dir.exists?(folder)
  end
end

def commandExists(command : String)
  Process.find_executable(command) ? true : false
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
  success = Process.run(
    cmd, argv,
    output: stdout, error: stderr,
    chdir: folder
  )
  { success.normal_exit?, stdout.to_s, stderr.to_s }
end
