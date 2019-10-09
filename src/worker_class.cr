require "./setting"
require "./utils"
require "./network"

class Worker
  def initialize(task : String, app : App)
    @task = task
    @argv = argv
  end
end
