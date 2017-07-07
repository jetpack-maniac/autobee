if os.version ~= nil then -- This is a ComputerCraft OS API method
  if os.version() == "CraftOS 1.8" then -- This is ComputerCraft for 1.9/1.10
    version = "ComputerCraft"
    term.clear()
    print("Welcome to the AutoBee Installer!")
    print("CraftOS 1.8 found.  Fetching AutoBee files...")
  end
elseif computer.energy() ~= then -- This is an OpenComputers Computer API method
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

end

if version == "OpenComputers" then

end