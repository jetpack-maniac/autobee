---- AutoBee for OpenComputers ----

-- Globarl variables
local running = true
local apiaryTimerIDs = {}

-- Version Check
if pcall(function() component = require("component") end) == true then
  if component.proxy ~= nil then
    version = "OpenComputers"
    keyboard = require("keyboard")
    event = require("event")
    filesystem = require("filesystem")
    internet = require("internet")
    print("Starting AutoBee..")
  else
    error("This version is for OpenComputers.  See https://github.com/jetpack-maniac/autobee for more details.")
  end
end

-- Loads the core library, fetches if missing
function loadCore()
  local searchPath = "/home/autobee/"
  local library = "autobeeCore.lua"
  local coreURL = "https://github.com/jetpack-maniac/autobee/blob/master/autobeeCore.lua"
  if filesystem.exists(searchPath) == false then
    filesystem.makeDirectory(searchPath)
  end
  if filesystem.exists(searchPath..library) then
    dofile("autobeeCore.lua")
    print("Loaded AutoBee Core...")
  else
    print("Missing AutoBee Core, fetching from Github...")
    local file = io.open(searchPath..library, "w")
    for chunk in internet.request(coreURL) do
      file:write(chunk)
      file:flush()
    end
    file:close()
  end
end

-- Peripheral check
function peripheralCheck()
  loadCore()
  local apiary = nil
  for address, componentType in pairs(component.list()) do
    -- this is the search for 1.7.10 Forestry apiaries
    if string.find(componentType, "apiculture") and componentType:sub(21,21) == "0" then
      apiary = address
    -- this is the search for 1.10.2 Forestry apiaries and bee houses
    elseif componentType == "bee_housing" then
      apiary = address
      print("WARNING: OpenComputers on 1.10.2 does not support necessary APIs. See https://github.com/jetpack-maniac/autobee for more information.")
      os.exit()
    end
  end
  if apiary == nil then
    print("No apiaries found.  Closing program.")
    os.exit()    
  else
    dependencyCheck(component.proxy(apiary))
  end
end

-- looks at a device and determines if it's a valid apiary, returns true or false
function isApiary(address)
  if address == nil then return false end
  device = component.type(address)
  -- 1.10.2/1.11.2 Apiaries
  if string.find(device, "bee_housing") then -- TODO discriminate apiaries versus bee houses
    return true
  -- 1.7.10 Apiaries
  elseif string.find(device, "apiculture") and device:sub(21,21) == "0" then
    return true
  else
  return false
  end
end

-- examines peripherals and returns a valid apiary or nil
function findApiary()
  local devices = component.list()
  for address, device in pairs(devices) do
    if isApiary(address) then
      return component.proxy(address)
    else
      return false
    end
  end
end

-- Device Management
-- These next two functions are callbacks to enable OC events to work properly
function deviceConnect(event, address)
  addDevice(address)
end

function deviceDisconnect(event, address)
  removeDevices()
  initDevices()
end

function removeDevices()
  for timerID, address in pairs(apiaryTimerIDs) do
    event.cancel(address)
  end
  apiaryTimerIDs = {}
end

function addDevice(address)
  if address == nil then return false end
  if isApiary(address) == true then
    local apiary = Apiary(component.proxy(address), address)
    apiaryTimerIDs[address] = event.timer(delay, function() apiary.checkApiary() end, math.huge)
    return true
  end
  return false
end

function initDevices()
  --Aux ignore in case the program crashed and listeners are still active
  event.ignore("component_available",deviceConnect)
  event.ignore("component_removed",deviceDisconnect)
  local devices = component.list()
  for address, device in pairs(devices) do
    addDevice(address)
  end
  event.listen("component_added",deviceConnect)
  event.listen("component_removed",deviceDisconnect)
end

function printInfo()
  print("AutoBee running.")
  print("Hold Ctrl+W to stop. Hold Ctrl+L to clear terminal.")
  print(size(apiaryTimerIDs).." apiaries connected.")
end

----------------------
-- The main loop
----------------------

peripheralCheck()
if running == true then 
  initDevices()
  printInfo()
end

while running do
  if version == "OpenComputers" then
    if keyboard.isKeyDown(keyboard.keys.w) and keyboard.isControlDown() then
      event.ignore("component_available",deviceConnect)
      event.ignore("component_removed",deviceDisconnect)
      removeDevices()
      print("AutoBee: Interrupt detected. Closing program.")
      break
    end
    if keyboard.isKeyDown(keyboard.keys.l) and keyboard.isControlDown() then
      term.clear()
      printInfo()
    end
    os.sleep(delay)
  end
end