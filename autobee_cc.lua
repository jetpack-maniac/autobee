---- AutoBee for ComputerCraft ----

local running = true
dofile("autobeeCore.lua")

-- Version check
if os.version ~= nil then -- This is a ComputerCraft OS API method
  if os.version() == "CraftOS 1.8" then -- This is ComputerCraft for 1.9/1.10
    version = "ComputerCraft"
    local apiary = peripheral.find("forestry_apiary")
    if apiary ~= nil then 
      if dependencyCheck(apiary) then
        print("AutoBee running.")
        print("Press W to terminate program. Press L to clear terminal.")
      end
    else
      print("AutoBee Error: No apiaryTimerIDs found.")
      running = false
    end
  end
end

local apiaryTimerIDs = {}

function removeDevice(device)
  for timerID, address in pairs(apiaryTimerIDs) do
    os.cancelTimer(timerID)
  end
  apiaryTimerIDs = {}
  initDevices()
end

function addDevice(address)
  if address == nil then return false end -- address is the 'side' for ComputerCraft
  if string.find(peripheral.getType(address), "forestry_apiary") then
    apiaryTimerIDs[os.startTimer(delay)] = Apiary(peripheral.wrap(address), address)
    print(size(apiaryTimerIDs).." apiaries connected.")
    return true
  end
  return false
end

function initDevices()
  local devices = peripheral.getNames()
  for _, device in ipairs(devices) do
    addDevice(device)
  end
end

-- ComputerCraft Functions

function handleTimer()
  _, data = os.pullEvent("timer")
  apiaryTimerIDs[data].checkOutput()
  apiaryTimerIDs[os.startTimer(delay)] = apiaryTimerIDs[data]
  apiaryTimerIDs[data] = nil
end

function handlePeripheralAttach()
  _, data = os.pullEvent("peripheral")
  addDevice(data) 
end

function handlePeripheralDetach()
  _, data = os.pullEvent("peripheral_detach")
  removeDevice(data) 
end

function humanInteraction()
  _, data = os.pullEvent("key_up")
  if data == keys.l then
    term.clear()
    term.setCursorPos(1,1)
    print("AutoBee running.")
    print("Press W to stop program. Press L to clear terminal.")
    print(size(apiaryTimerIDs).." apiaryTimerIDs connected.")
  elseif data == keys.w then
    print("AutoBee: Interrupt detected. Closing program.")
    for timerID, _ in pairs(apiaryTimerIDs) do
      os.cancelTimer(timerID)
    end
    running = false
  end
end

----------------------
-- The main loop
----------------------

if running == true then initDevices() end -- inits devices upon first run

while running do
  parallel.waitForAny(handleTimer, handlePeripheralAttach, handlePeripheralDetach, humanInteraction)
end
