--- Configuration

-- These config options tell the apiaries to drop items into the world
-- WARNING: unless you're using some kind of system to pick them up,
-- this will cause lag due to floating items piling up in the world
dropProducts = "false"
dropDrones = "false"

-- The max size of the output inventory
chestSize = 27

-- chest direction relative to apiary
chestDir = "up"

-- how long the computer will wait in seconds before checking the apiaries
delay = 2
--- End of Configuration

--------------------------------------------------------------------------------
-- Misc Functions

-- returns the size of a data structure
function size(input)
  local count = 0
  for _, _ in pairs(input) do
    count = count + 1
  end
  return count
end

-- searches a sample table and returns true if any element matches the criterion
function matchAny(criterion, sample)
  for i=1, #sample do
    if criterion == sample[i] then
      return true
    end
  end
  return false
end

-- Dependency Check for required item APIs
function dependencyCheck(device)
  if device == nil then return nil end
  if device.getTransferLocations ~= nil then
    peripheralVersion = "Plethora"
  elseif device.getStackInSlot ~= nil then
    peripheralVersion = "OpenPeripherals"
  end
  if peripheralVersion == nil then
    error("This game server lacks a required game mod. Use 'autobee -hp' or 'autobee peripheral' for more info.")
  end
  return true
end

-- End of Misc Functions
--------------------------------------------------------------------------------
-- Apiary class

function Apiary(device, address)
  local self = {}

  local queen = {"beeQueenGE", "forestry:beeQueenGE"}
  local princess = {"beePrincessGE", "forestry:beePrincessGE"}
  local drone = {"beeDroneGE", "forestry:beeDroneGE"}

  function self.getID()
    return address
  end

  -- Checks to see if the princess/queen slot (1) is empty or full
  function self.isPrincessSlotOccupied()
    return self.checkSlot(1) ~= nil
  end

  -- Checks to see if the drone slot (2) is empty or full
  function self.isDroneSlotOccupied()
     return self.checkSlot(2) ~= nil
  end

  -- Removes a princess from the output to it's proper chest slot
  function self.pushPrincess(slot)
    self.push(chestDir,slot,1,chestSize)
  end

  -- Pulls princess or queen from appropriate chest slot
  function self.pullPrincess()
    self.pull(chestDir,chestSize,1,1)
  end

  -- Removes a drone from the output to it's proper chest slot
  function self.pushDrone(slot)
    self.push(chestDir,slot,64,chestSize-1)
  end

  -- Pulls drone from appropriate chest slot
  function self.pullDrone()
    self.pull(chestDir,chestSize-1,64,2)
  end

  -- Moves drone from output into input
  function self.moveDrone(slot)
    self.push("self", slot, 64, 2)
  end

  -- Moves princess from output into input
  function self.movePrincess(slot)
    self.push("self", slot, 1, 1)
  end

  function self.isPrincessOrQueen(slot)
    local type = self.itemType(slot)
    if type == "queen" or type == "princess" then
      return true
    else
      return false
    end
  end

  function self.itemType(slot)
    if self.checkSlot(slot) ~= nil then
      local name = self.checkSlot(slot).name
      if matchAny(name, queen) then return "queen" end
      if matchAny(name, princess) then return "princess" end
      if matchAny(name, drone) then return "drone" end
    else
      return false
    end
  end

  function self.isDrone(slot)
    if self.itemType(slot) == "drone" then
      return true
    else
      return false
    end
  end

  -- Interfaces

  function self.checkSlot(slot)
    if peripheralVersion == "Plethora" then
      local itemMeta = nil
      if pcall(function() itemMeta = device.getItemMeta(slot) end) then
        return itemMeta
      else
        print("AutoBee Error: PCall failed on check slot")
      end
    end
  end

  -- Interface for item pushing, follows the OpenPeripherals/Plethora format directly
  function self.push(destinationEntity, fromSlot, amount, destinationSlot)
    if peripheralVersion == "Plethora" then
      if pcall(function() device.pushItems(destinationEntity, fromSlot, amount, destinationSlot) end) then
        return true
      else
        print("AutoBee Error: PCall failed on push")
      end
    end
  end

  -- Interface for item pulling,  follows the OpenPeripherals/Plethora format directly
  function self.pull(sourceEntity, fromSlot, amount, destinationSlot)
    if peripheralVersion == "Plethora" then
      if pcall(function() device.pullItems(sourceEntity, fromSlot, amount, destinationSlot) end) then
        return true
      else
        print("AutoBee Error: PCall failed on pull")
      end
    end 
  end

  -- End of Interfaces

  function self.checkOutput()
    os.sleep(.01)
    for slot=3,9 do
      local type = self.itemType(slot)
      if type == "princess" then
        if self.isPrincessSlotOccupied() == true then
          self.push(chestDir, slot)
        else
          self.movePrincess(slot)
        end
      elseif type == "drone" thenSize
        if self.isDroneSlotOccupied() == true then
          self.push(chestDir, slot)
        else
          self.moveDrone(slot)
        end
      else
        self.push(chestDir, slot)
      end
    end
  end

  return self
end

-- End Apiary class
--------------------------------------------------------------------------------