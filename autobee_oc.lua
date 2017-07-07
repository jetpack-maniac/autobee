---- AutoBee for OpenComputers ----

local running = true
dofile("autobeeCore.lua")

-- Peripheral check
function peripheralCheck()
  local apiary = nil
  for address, componentType in pairs(component.list()) do
    -- this is the search for 1.7.10 Forestry apiaries
    if string.find(componentType, "apiculture") and componentType:sub(21,21) == "0" then
      apiary = address
    -- elseif 
    -- this is the search for 1.10.2 Forestry apiaries

    end
  end
  dependencyCheck(component.proxy(apiary))
end

-- Version Check
if pcall(function() component = require("component") end) == true then
  if component.proxy ~= nil then
    version = "OpenComputers"
    keyboard = require("keyboard")
    event = require("event")
    term = require("term")
    peripheralCheck()
    print("AutoBee running.")
    print("Hold Ctrl+W to stop. Hold Ctrl+L to clear terminal.")
  else
    error("This version is for OpenComputers.  See https://github.com/jetpack-maniac/autobee for more details.")
  end
end

local apiaryTimerIDs = {}

--These next two functions are callbacks to enable OC events to work properly
function deviceConnect(event, address)
  addDevice(address)
end

function deviceDisconnect(event, address)
  removeDevice(address)
end

function removeDevice(device)
  for timerID, address in pairs(apiaryTimerIDs) do
    event.canel(address)
  end
  apiaryTimerIDs = {}
  initDevices()
end

function addDevice(address)
  if address == nil then return false end
  local type = component.type(address) -- address is the address for OpenComputers
  if string.find(type, "bee_housing") then -- TODO discriminate apiaries versus bee houses
    local apiary = Apiary(component.proxy(address), address)
    apiaryTimerIDs[address] = event.timer(delay, function() apiary.checkOutput() end, math.huge)
    print(size(apiaryTimerIDs).." apiaries connected.")
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

----------------------
-- The main loop
----------------------

if running == true then initDevices() end -- inits devices upon first run

while running do
  if version == "OpenComputers" then
    if keyboard.isKeyDown(keyboard.keys.w) and keyboard.isControlDown() then
      event.ignore("component_available",deviceConnect)
      event.ignore("component_removed",deviceDisconnect)
      for address, _ in pairs(apiaryTimerIDs) do
        removeDevice(address)
      end
      print("AutoBee: Interrupt detected. Closing program.")
      break
    end
    if keyboard.isKeyDown(keyboard.keys.l) and keyboard.isControlDown() then
      term.clear()
      print("AutoBee running.")
      print("Hold Ctrl+W to stop. Hold Ctrl+L to clear terminal.")
      print(size(apiaryTimerIDs).." apiaries connected.")
    end
    os.sleep(delay)
  end
end