require "yaml"

class App
  include YAML::Serializable

  property name : String
  property git : String
  property branch : String
  property build : Array(String)

  property buildFolder : String = ""
  property postinstall : Hash(String, Array(String))

  # clone if repo not exist
  # else if branch is the same, pull
  # else checkout and pull
  def update(appFolder)
    clone(appFolder)
  end

  # clone app to folder
  def clone(folder)
    puts "Clonning: #{@git} to #{folder}"
    args = ["clone", @git, "--branch", @branch, "--single-branch", folder]
    Process.run("git", args)
  end

  # build the app
  def build(folder)
    Dir.mkdir(folder) if !Dir.exists?(folder)
    build.each do |command|
      command = command.split(" ")
      argv = command.skip(1).map! do |arg|
        arg.gsub("$pwd", folder)
      end
      cmd = command.first

      puts "#{folder}: #{cmd} #{argv}"

      stdout = IO::Memory.new
      stderr = IO::Memory.new
      success = Process.run(
        cmd, argv,
        output: stdout, error: stderr,
        chdir: folder
      ).success?
      if !success
        puts "Command failed"
        puts "STDERR"
        puts stderr.to_s
        break
      end
      # output stdout to log file
      # ...
    end
  end

  def createSymlink(folder, patternArray, target)
    patternArray.each do |pattern|
      puts "#{folder}/#{pattern}"
      files = Dir.glob("#{folder}" + "/#{pattern}")
      files.each do |file|
        symlink_file = "#{target}/#{File.basename(file)"
        puts "#{file} --> #{symlink_file}}"
        if File.exists?(symlink_file)
          File.delete(symlink_file)
        end
        File.symlink(file, symlink_file)
      end
    end
  end

  # after folder command execution
  # usually create symlink to binary
  # create symlink to library
  def afterInstall(
    folder, binFolder, libFolder, includeFolder
  )
    puts @postinstall
    bin_pattern = @postinstall["bin"]
    lib_pattern = @postinstall["lib"]
    include_pattern = @postinstall["include"]

    createSymlink(folder, bin_pattern, binFolder)
    createSymlink(folder, lib_pattern, binFolder)
    createSymlink(folder, include_pattern, libFolder)
  end

  # Run task on an app
  def run(
    task, appFolder, binFolder, libFolder, includeFolder
  )
    installFolder = appFolder + "/#{@name}"
    buildFolder = installFolder + "/#{@buildFolder}"
    case task
    when "install", "update"
      update(installFolder)
      build(buildFolder)
      afterInstall(
        installFolder,
        binFolder,
        libFolder,
        includeFolder
      )
    end
  end
end

class Setting
  include YAML::Serializable

  property folder : String
  property apps : Array(App)

  @appFolder : String = ""
  @binFolder : String = ""
  @libFolder : String = ""
  @includeFolder : String = ""

  def createFolder()
    @binFolder = @folder + "/bin"
    @libFolder = @folder + "/lib"
    @appFolder = @folder + "/app"
    @includeFolder = @folder + "/include"
    folders = [
      @folder,
      @binFolder,
      @libFolder,
      @appFolder,
      @includeFolder
    ]
    folders.each do |folder|
      Dir.mkdir(folder) if !Dir.exists?(folder)
    end

    folders.each do |folder|
      if !Dir.exists?(folder)
        puts "Cannot create directory"
        exit
      end
    end
  end

  def remove(appName)
  end

  def run(task, argv)
    createFolder()

    if task == "remove"
      remove(argv)
      return
    end

    @apps.each do |app|
      app.run(
        task,
        @appFolder,
        @binFolder,
        @libFolder,
        @includeFolder
      )
    end
  end
end
