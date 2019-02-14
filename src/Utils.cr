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
