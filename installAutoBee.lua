-- URLs
local OC = "https://raw.githubusercontent.com/jetpack-maniac/autobee/master/autobee_oc.lua"

computerCraftURLs ={
  autobee = "https://raw.githubusercontent.com/jetpack-maniac/autobee/master/autobee_cc.lua",
  autobeeCore = "https://raw.githubusercontent.com/jetpack-maniac/autobee/master/autobeeCore.lua"
}

local issue = false

if os.version ~= nil then -- This is a ComputerCraft OS API method
  if os.version() == "CraftOS 1.8" then -- This is ComputerCraft for 1.9/1.10
    version = "ComputerCraft"
    term.clear()
    print("Welcome to the AutoBee Installer!")
    print("CraftOS 1.8 found.  Fetching AutoBee files...")
  end
elseif pcall(function() computer.energy() end) == true then -- This is an OpenComputers Computer API method
  component = require("component")
  keyboard = require("keyboard")
  event = require("event")
  term = require("term")
  serialization = require("serialization")
  version = "OpenComputers"
  print("Autobee Warning: OpenComputers does not yet support ComputerCraft APIs.  This program will not work on OpenComputers until it does.")
  print("Continue installation anyway? (Y/n)")
  os.exit()
  -- End of temporary section
end

if version == "ComputerCraft" then
  shell.run("cd /")
  shell.run("mkdir autobee/")
  for filename, url in pairs(computerCraftURLs) do
    filename = filename..".lua"
    local file = nil
    local response = http.get(url)
    if response == nil then
      print("Installer Error: could not reach Github.com")
      issue = true
    else
      if pcall(function() file = fs.open(filename, "w") file.write(response.readAll()) file.close() end) then
        print("Created "..filename)
        shell.run("mv "..filename.." autobee")
      else
        print("Installer Error: could not create "..filename..", the disk is full or read-only.")
        issue = true
      end
    end
  end
  if issue == false then
    print("Install success! To start AutoBee, run 'autobee/autobee.lua'.")
  end
end

if version == "OpenComputers" then
  -- WIP
end