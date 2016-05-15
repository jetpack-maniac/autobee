--- Configuration
-- The max size of the output inventory
chestSize = 27
-- chest direction relative to apiary
chestDir = "up"
-- how long the computer will wait before checking the apiaries
delay = 2
--- End of Configuration

if require ~= nil then
  component = require("component")
  keyboard = require("keyboard")
  event = require("event")
  version = "OpenComputers"
  print("Hold Ctrl+W to stop.")
else
  version = "ComputerCraft"
  print("Hold Ctrl+T to terminate program.")
end

local apiaries = {}
local monitors = {}

--------------------------------------------------------------------------------
-- Apiary class

function Apiary(apiary)
  local self = {}

  -- Checks to see if the princess/queen slot (1) is empty or full and modifies
  -- queen and princess accordingly
  function self.isPrincessSlotOccupied()
    return apiary.getStackInSlot(1) ~= nil
  end

  -- Checks to see if the drone slot (2) is empty or full and modifies
  -- drone accordingly
  function self.isDroneSlotOccupied()
     return apiary.getStackInSlot(2) ~= nil
  end

  -- Removes a princess from the output to it's proper chest slot
  function self.pushPrincess(slot)
    apiary.pushItemIntoSlot(chestDir,slot,1,chestSize)
  end

  -- Pulls princess or queen from appropriate chest slot
  function self.pullPrincess()
    apiary.pullItemIntoSlot(chestDir,chestSize,1,1)
  end

  -- Removes a drone from the output to it's proper chest slot
  function self.pushDrone(slot)
    apiary.pushItemIntoSlot(chestDir,slot,64,chestSize-1)
  end

  -- Pulls drone from appropriate chest slot
  function self.pullDrone()
    apiary.pullItemIntoSlot(chestDir,chestSize-1,64,2)
  end

  function self.isPrincessOrQueen(slot)
    local name = apiary.getStackInSlot(slot).name
    return name == "beePrincessGE" or name == "beeQueenGE"
  end

  function self.isDrone(slot)
    return apiary.getStackInSlot(slot).name == "beeDroneGE"
  end

  function self.emptyOutput()
    for slot=3,9 do
      if apiary.getStackInSlot(slot) ~= nil then
        if self.isPrincessOrQueen(slot) then
          self.pushPrincess(slot)
        elseif self.isDrone(slot) then
          self.pushDrone(slot)
        else
          apiary.pushItemIntoSlot(chestDir,slot)
        end
      end
    end
  end

  function self.populatePrincessSlot()
    if self.isPrincessSlotOccupied() == false then
      self.pullPrincess()
      -- If we didn't get a princess from our chest check the output
      if self.isPrincessSlotOccupied() == false then
        for slot=3,9 do
          -- We will only get princesses in the output, never a queen
          if apiary.getStackInSlot(slot) ~= nil and self.isPrincessOrQueen(slot) then
            self.pushPrincess(slot)
            self.pullPrincess()
          end
        end
      end
    end
  end

  function self.populateDroneSlot()
    if self.isDroneSlotOccupied() == false then
      self.pullDrone()
      -- If we didn't get a drone from our chest check the output
      if self.isDroneSlotOccupied() == false then
        for slot=3,9 do
          if apiary.getStackInSlot(slot) ~= nil and self.isDrone(slot) then
            self.pushDrone(slot)
            self.pullDrone()
          end
        end
      end
    else -- drone is occupied
      for slot=3,9 do
        if apiary.getStackInSlot(slot) ~= nil and self.isDrone(slot) then
            self.pushDrone(slot)
        end
      end
    end
  end

  return self
end

-- End Apiary class
--------------------------------------------------------------------------------

function removeDevice(device)
  print("Device removed")
  table.remove(device)
end

function addDevice(device)
  print("New device!")
  if version == "ComputerCraft" then
    if string.find(peripheral.getType(device), "apiculture") and peripheral.getType(device):sub(21,21) == "0" then
      table.insert(apiaries, Apiary(peripheral.wrap(device)))
      return true
    end
  elseif version == "OpenComputers" then
    print(component.type(device))
    if string.find(component.type(device), "apiculture") and device:sub(21,21) == "0" then
      table.insert(apiaries, Apiary(component.proxy(device)))
      print(device)
      return true
    end
  end

  return false
end

-- Find apiaries
-- tile_for_apiculture_0_name_0 is an apiary
-- tile_for_apiculture_2_name_0 is a bee house
-- bee houses can be hooked up but cannot be used

if version == "ComputerCraft" then
  local devices = peripheral.getNames()
  for _, device in ipairs(devices) do
    if string.find(peripheral.getType(device), "apiculture") and peripheral.getType(device):sub(21,21) == "0" then
      table.insert(apiaries, Apiary(peripheral.wrap(device)))
    elseif string.find(peripheral.getType(device), "apiculture") and peripheral.getType(device):sub(21,21) == "2" then
      print("Warning: Bee house detected.  It cannot be used with this program.")
    end
  end
elseif version == "OpenComputers" then
  local devices = component.list()
  for address, device in pairs(devices) do
    if string.find(device, "apiculture") and device:sub(21,21) == "0" then
      table.insert(apiaries, Apiary(component.proxy(address)))
    elseif string.find(device, "apiculture") and device:sub(21,21) == "2" then
      print("Warning: Bee house detected.  It cannot be used with this program.")
    end
  end
  event.listen("component_available",addDevice(device))
  event.listen("component_removed",removeDevice(device))
end

print(#apiaries.." apiaries connected.")


----------------------
-- The main loop
----------------------

while true do
  for i, apiary in ipairs(apiaries) do
    apiary.populatePrincessSlot()
    apiary.populateDroneSlot()
    apiary.emptyOutput()
  end

  if version == "OpenComputers" then
    if keyboard.isKeyDown(keyboard.keys.w) and keyboard.isControlDown() then
      event.ignore("component_available",addDevice)
      event.ignore("component_removed",removeDevice)
      os.exit()
    end
  end
  os.sleep(delay)
end
