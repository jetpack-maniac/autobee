---- AutoBee for ComputerCraft ----

-- Global variables
local running = true
local apiaryTimer = nil

-- Version check
if os.version ~= nil then -- This is a ComputerCraft OS API method
  -- if string.find(os.version(), "CraftOS") == true then
  if os.version() == "CraftOS 1.8" or os.version() == "CraftOS 1.7" then -- This is ComputerCraft for 1.9/1.10
    version = "ComputerCraft"
  else
    error("This version is for ComputerCraft.  See https://github.com/jetpack-maniac/autobee for more details.")
  end
end

-- Loads the core library, fetches if missing
if pcall(function() dofile("autobeeCore.lua") end) == false then
  if pcall(function() dofile("autobee/autobeeCore.lua") end) == false then
    print("Core Autobee library not found.  Fetching via Github.")
    local file = nil
    local response = http.get("https://raw.githubusercontent.com/jetpack-maniac/autobee/master/autobeeCore.lua")
    if response == nil then
      error("Could not reach Github.com")
    else
      if pcall(function() file = fs.open("autobeeCore.lua", "w") file.write(response.readAll()) file.close() end) then
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
    print("AutoBee Warning: No compatible apiaries detected.")
  end
end

-- looks at a device and determines if it's a valid apiary, returns type or false
function getApiaryType(address)
  if address == nil then return false end

  -- CURRENT EDITIONS
  -- 1.12.2 Apiary
  local device = peripheral.getType(address)
  if string.find(device, "forestry:apiary") then
    return "apiary"
  -- 1.12.2 Gendustry Industrial Apiary
  elseif string.find(device, "gendustry:industrial_apiary") then
    return "gendustry"
  -- 1.12.2 Alveary
  elseif string.find(device, "forestry:alveary_plain") then
    return "alveary"

  -- LEGACY EDITIONS
  -- 1.10.2/1.11.2 Apiary
  elseif string.find(device, "forestry_apiary") then
    return "apiary"
  -- 1.7.10 Apiary
  elseif string.find(device, "apiculture") and peripheral.getType(address):sub(21,21) == "0" == true then
    return "apiary"
  else
    return false
  end
end

-- examines peripherals and returns a valid apiary or nil
function findApiary()
  local devices = peripheral.getNames()
  for _, address in pairs(devices) do
    local apiaryType = getApiaryType(address)
    if apiaryType == "apiary" or apiaryType == "gendustry" then
      return peripheral.wrap(address)
    end
  end
  return nil
end

function initDevices()
  apiaryTimer = nil
  local devices = peripheral.getNames()  
  local apiaryCount = 0
  local gendustryCount = 0
  local alvearyCount = 0
  for _, device in ipairs(devices) do
    local apiaryType = getApiaryType(device)
    local apiary = Apiary(peripheral.wrap(device), nil, apiaryType)
    if apiaryType == "apiary" then
      apiary.checkApiary(3, 9)
      apiaryCount = apiaryCount +1
    elseif apiaryType == "gendustry" then
      apiary.checkApiary(7, 15)
      gendustryCount = gendustryCount + 1
    elseif apiaryType == "alveary" then
      apiary.checkApiary(3, 9)
      alvearyCount = alvearyCount + 1
    end
  end
  printInfo(apiaryCount, alvearyCount, gendustryCount)
  apiaryTimer = os.startTimer(delay)
end

function printInfo(apiaryCount, alvearyCount, gendustryCount)
  term.setCursorPos(1,1)
  term.clear()
  print("AutoBee running.")
  print("Press W to stop program. Press L to clear terminal.")
  print(alvearyCount.." alvearies connected.")
  print(apiaryCount.." apiaries connected.")
  print(gendustryCount.." industrial apiaries connected.")
end

function handleTimer()
  local _, data = os.pullEvent("timer")
  initDevices()
end

function humanInteraction()
  local _, data = os.pullEvent("key_up")
  if data == keys.l then
    term.setCursorPos(1,1)
    term.clear()
    print("AutoBee running.")
    print("Press W to stop program. Press L to clear terminal.")
    print("Apiary count will update on next check.")
    if apiaryTimer == nil then
      apiaryTimer = os.startTimer(delay)
    end
  elseif data == keys.w then
    print("AutoBee: Interrupt detected. Closing program.")
    if apiaryTimer ~= nil then
      os.cancelTimer(apiaryTimer)
    end
    running = false
  end
end

----------------------
-- The main loop
----------------------

peripheralCheck()
if running == true then 
  initDevices()
end

while running do
  parallel.waitForAny(handleTimer, humanInteraction)
end