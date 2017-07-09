---- AutoBee for ComputerCraft ----

local debug = false

-- Global variables
local running = true
local apiaryTimer = nil
local apiaries = {}
local delay = 5

-- Version check
if os.version ~= nil then -- This is a ComputerCraft OS API method
  -- if string.find(os.version(), "CraftOS") == true then
  if os.version() == "CraftOS 1.8" or os.version() == "CraftOS 1.7" then -- This is ComputerCraft for 1.9/1.10
    version = "ComputerCraft"
  else
    error("This version is for ComputerCraft.  See https://github.com/jetpack-maniac/autobee for more details.")
  end
end

if fs.exists("autobeeCore.lua") == true then
  dofile("autobeeCore.lua")
else
  if fs.exists("autobee/autobeeCore.lua") == true then
    dofile("autobee/autobeeCore.lua")
  else
    print("Core Autobee library not found.  Fetching via Github.")
    local file = nil
    local response = http.get("https://raw.githubusercontent.com/jetpack-maniac/autobee/master/autobeeCore.lua")
    if response == nil then
      error("Could not reach Github.com")
    else
      if pcall(function() file = fs.open("autobee/autobeeCore.lua", "w") file.write(response.readAll()) file.close() end) then
        print("Fetched AutoBee Core.")
      else
        error("Could not create "..filename..", the disk is full or read-only.")
      end
    end
  end
end

-- Peripheral check
function peripheralCheck()
  local apiary = findApiary()
  if apiary ~= nil then
    dependencyCheck(apiary)
  else
    print("AutoBee Warning: No apiaries detected.")
  end
end

-- looks at a device and determines if it's a valid apiary, returns true or false
function isApiary(address)
  if address == nil then return false end
  -- 1.10.2/1.11.2 Apiary
  if string.find(peripheral.getType(address), "forestry_apiary") then
    return true
  -- 1.7.10 Apiary
  elseif string.find(peripheral.getType(address), "apiculture") and peripheral.getType(address):sub(21,21) == "0" == true then
    return true
  else
    return false
  end
end

-- examines peripherals and returns a valid apiary or nil
function findApiary()
  local devices = peripheral.getNames()
  for _, address in pairs(devices) do
    if isApiary(address) == true then
      return peripheral.wrap(address)
    end
  end
  return nil
end

-- Device Management
function removeDevices()
  os.cancelTimer(apiaryTimer)
end

function addDevice(address)
  if isApiary(address) == true then
    table.insert(apiaries, Apiary(peripheral.wrap(address)))
  end
end

function initDevices()
  local devices = peripheral.getNames()
  for _, device in ipairs(devices) do
    addDevice(device)
  end
  os.startTimer(delay)
end

-- ComputerCraft Event-based Functions
function handleTimer()
  local _, data = os.pullEvent("timer")
  for apiary, address in pairs(apiaries) do
    apiaries[apiary].checkApiary()
  end
  apiaryTimer = os.startTimer(delay)
end

function handlePeripheralAttach()
  local _, data = os.pullEvent("peripheral")
  addDevice(data) 
end

function handlePeripheralDetach()
  local _, data = os.pullEvent("peripheral_detach")
  removeDevices()
  initDevices()
end

function humanInteraction()
  local _, data = os.pullEvent("key_up")
  if data == keys.l then
    term.setCursorPos(1,1)
    term.clear()
    printInfo()
  elseif data == keys.w then
    print("AutoBee: Interrupt detected. Closing program.")
    if apiaryTimer ~= nil then 
      os.cancelTimer(apiaryTimer)
    end
    running = false
  end
end

function printInfo()
    print("AutoBee running.")
    print("Press W to stop program. Press L to clear terminal.")
    print(size(apiaries).." apiaries connected.")
end

----------------------
-- The main loop
----------------------

-- this automatically allots 500ms to check each apiary with a minimum of 5 seconds overall
if size(apiaries)/2 > 5 then delay = size(apiaries)/2 end

peripheralCheck()
if running == true then 
  initDevices()
  printInfo()
end

while running do
  parallel.waitForAny(handleTimer, handlePeripheralAttach, handlePeripheralDetach, humanInteraction)
end
