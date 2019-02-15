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

def runCommand(commandString, folder)
  commandString = commandString.split(" ")
  cmd = commandString.first
  argv = commandString.skip(1)
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  success = Process.run(
    cmd, argv,
    output: stdout, error: stderr,
    chdir: folder
  )
  { success, stdout.to_s, stderr.to_s }
end
