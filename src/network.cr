require "http/client"

def followRedirect(url)
  while true
    response = HTTP::Client.get url
    return response if response.status_code != 302
    url = response.headers["Location"]
    puts "Redirect to #{url}"
  end
end

def downloadFollowRedirect(url, filename)
  response = followRedirect(url)
  response_io = IO::Memory.new response.body
  File.touch(filename)
  File.write(filename, response_io)
end
