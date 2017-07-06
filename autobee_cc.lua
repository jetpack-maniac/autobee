---- AutoBee for ComputerCraft ----

-- debug

local printTimers = true
local outputDebug = false

-- end debug

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

function removeDevices()
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

function createTimer(device)
  if device == nil then return false end
  apiaryTimerIDs[os.startTimer(delay)] = apiaryTimerIDs[device]
  apiaryTimerIDs[device] = nil
end

function handleTimer()
  _, data = os.pullEvent("timer")
  if printTimers == true then 
    print("Timer: "..apiaryTimerIDs[data].getID())
  end
  if outputDebug == true then 
    if pcall(function() apiaryTimerIDs[data].checkOutput() end) then
      createTimer(data)
    else
      print("Pcall failed on "..apiaryTimerIDs[data].getID())
      createTimer(data)
    end
  end
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
    print(size(apiaryTimerIDs).." apiaries connected.")
  elseif data == keys.w then
    print("AutoBee: Interrupt detected. Closing program.")
    for timerID, _ in pairs(apiaryTimerIDs) do
      os.cancelTimer(timerID)
    end
    running = false
  elseif data == keys.t then
    if printTimers == false then
      print("Timers printing.")
      printTimers = true
    else
      print("Stopping timers print.")
      printTimers = false
    end
  elseif data == keys.o then
    if outputDebug == false then
      print("Output on.")
      outputDebug = true
    else
      print("Output off.")
      outputDebug = false
    end
  elseif data == keys.a then
    print("Rebuilding apiary map.")
    removeDevices()
  elseif data == keys.m then
    print("Printing apiary map:")
    for timerID, apiary in pairs(apiaryTimerIDs) do
      print(timerID..": "..apiary.getID())
    end
  end
end

----------------------
-- The main loop
----------------------

if running == true then initDevices() end -- inits devices upon first run

while running do
  parallel.waitForAny(handleTimer, handlePeripheralAttach, handlePeripheralDetach, humanInteraction)
end
