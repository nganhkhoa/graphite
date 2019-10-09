require "yaml"

class App
  include YAML::Serializable

  property name : String
  property git : String
  property targz : String = ""
  property branch : String = "master"
  property tag : String = ""
  property singleBranch : Bool = false

  property buildFolder : String = ""
  property build : Array(String) = [] of String
  property symlink : Hash(String, Array(String)) = {} of String => Array(String)
  property global : Bool = false

  property dependencies : Array(String | App | Nil) = [] of (String | App | Nil)
  property requireSelf : Hash(String, String) = {} of String => String

  property skip : Bool = false
end

class Setting
  include YAML::Serializable

  property apps : Array(App)
end
