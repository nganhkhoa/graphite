require "yaml"
require "./Utils"

class App
  include YAML::Serializable

  property name : String
  property git : String
  property branch : String = "master"
  property build : Array(String) = [] of String

  property buildFolder : String = ""
  property postinstall : Hash(String, Array(String)) = {} of String => Array(String)

  property skip : Bool = false

  # clone if repo not exist
  # else if branch is the same, pull
  # else checkout and pull
  def update(appFolder)
    installFolder = appFolder + "/#{@name}"
    unless Dir.exists?(installFolder)
      puts "Cloning #{@name} to #{installFolder}"
      runCommand("git clone #{@git} --branch #{@branch} --single-branch #{@name}", appFolder)
      return true
    end
    success = runCommand("git remote update", installFolder)
    _, status = runCommand("git status -uno", installFolder)
    if status.match(/behind/)
      puts "#{@name} is behind, git pull"
      _, updatelog = runCommand("git pull", installFolder)
      puts updatelog
      return true
    end
    puts "#{@name} is up to date"
    false
  end

  # build the app
  def build(folder)
    Dir.mkdir(folder) if !Dir.exists?(folder)
    build.each do |command|
      command = command.gsub("$pwd", folder)
      puts "#{folder}: #{command}"

      success, stdout, stderr = runCommand(command, folder)
      case success
      when true
      when false
        puts "Error"
        puts "STDERR"
        puts stderr
      end
    end
  end

  def createSymlink(folder, patternArray, target)
    return if patternArray.nil?
    patternArray.each do |pattern|
      puts "#{folder}/#{pattern}"
      files = Dir.glob("#{folder}" + "/#{pattern}")
      files.each do |file|
        symlink_file = "#{target}/#{File.basename(file)}"
        puts "#{file} --> #{symlink_file}"
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
    bin_pattern = @postinstall["bin"]?
    lib_pattern = @postinstall["lib"]?
    include_pattern = @postinstall["include"]?

    createSymlink(folder, bin_pattern, binFolder)
    createSymlink(folder, lib_pattern, libFolder)
    createSymlink(folder, include_pattern, includeFolder)
  end

  # Run task on an app
  def run(
    task, appFolder, binFolder, libFolder, includeFolder
  )
    if @skip
      puts "#{@name} is skip"
      return
    end

    puts "Running #{@name}"

    installFolder = appFolder + "/#{@name}"
    buildFolder = installFolder + "/#{@buildFolder}"
    case task
    when "install", "update"
      if update(appFolder)
        build(buildFolder)
        afterInstall(
          installFolder,
          binFolder,
          libFolder,
          includeFolder
        )
      end
    when "build"
      build(buildFolder)
    when "symlink"
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
