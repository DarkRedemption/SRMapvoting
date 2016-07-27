-- This section is intended to create a table of maps that are on the server, using the sv_minmaxconfig.lua.

local log = UpOrDownVoting.Logging

local mapMinMaxTable = UpOrDownVoting.mapMinMaxTable
local switchmap = false

-- These are the initial values for this set of variables.
local time_left = math.max(0, (GetConVar("ttt_time_limit_minutes"):GetInt() * 60))
local rounds_left = math.max(0, GetGlobalInt("ttt_rounds_left", 6))

-- Putting these values here allow for changes for testing reasons.
UpOrDownVoting.currentMap = game.GetMap()
UpOrDownVoting.nextmap = ""
UpOrDownVoting.playerCount = 0
UpOrDownVoting.lastKnownPlayerCount = 0
UpOrDownVoting.currentMapSettings = UpOrDownVoting.mapMinMaxTable[UpOrDownVoting.currentMap]

------------------------------------------------------------------------------------

--Safely updates the player count, since there seems to be an issue with player.GetAll() sometimes returning nil.
local function updatePlayerCount()
  local pc = #player.GetAll()
  if (pc != nil) then
    UpOrDownVoting.playerCount = pc
  end
end

local function checkForLastRound()
  if rounds_left <= 0 then
    LANG.Msg("limit_round", {mapname = UpOrDownVoting.nextmap})
    switchmap = true
  elseif time_left <= 0 then
    LANG.Msg("limit_time", {mapname = UpOrDownVoting.nextmap})
    switchmap = true
  end
end

local function switchMap()
  if switchmap then
    log.logDebug("Time to switch maps. Switching to: " .. UpOrDownVoting.nextmap)
    timer.Stop("end2prep")
    timer.Simple(15, function() RunConsoleCommand ("changelevel", UpOrDownVoting.nextmap) end)
  else
    log.logDebug("There is still rounds/time remaining on this map...")
    LANG.Msg("limit_left", {num = rounds_left,
                            time = math.ceil(time_left / 60),
                            mapname = UpOrDownVoting.nextmap})
  end
end

local function nextMapDoesNotExist()
  return UpOrDownVoting.nextmap == "" or UpOrDownVoting.nextmap == nil
end

local function playerCountChanged()
  return UpOrDownVoting.playerCount ~= UpOrDownVoting.lastKnownPlayerCount
end

--Checks to see if the player count is out of range for this map to switch maps faster.
--PARAM rangeModifier:Integer - How much it should be out of range before decrementing the rounds faster.
local function currentPlayerCountOutOfRange(rangeModifier)
  rangeModifier = rangeModifier or 0
  
  return UpOrDownVoting.playerCount <= (UpOrDownVoting.currentMapSettings["minplayers"] - rangeModifier) or 
         UpOrDownVoting.playerCount >= (UpOrDownVoting.currentMapSettings["maxplayers"] + rangeModifier)
end

--Checks to see if the player count is out of range for the next map.
local function playerCountOutOfRange()
  return UpOrDownVoting.playerCount <= mapMinMaxTable[UpOrDownVoting.nextmap]["minplayers"] or 
         UpOrDownVoting.playerCount >= mapMinMaxTable[UpOrDownVoting.nextmap]["maxplayers"]
end

function UpOrDownVoting.recalculate()
  UpOrDownVoting.changeNextMapDueToPlayerCount()
end

function UpOrDownVoting.changeNextMapDueToPlayerCount()
  --This version of the if statement is commented out for now because
  --I think checking only when it is out of range makes it difficult for some maps to show up.

  --if nextMapDoesNotExist() or (playerCountChanged() and playerCountOutOfRange()) then
  if nextMapDoesNotExist() or playerCountChanged() then
    local maplist = UpOrDownVoting.createViableMapsTable()
    UpOrDownVoting.nextmap = UpOrDownVoting.randomizeMap(maplist)
  end
  UpOrDownVoting.lastKnownPlayerCount = UpOrDownVoting.playercount
end

function UpOrDownVoting.checkForMinMaxTable()
  if mapMinMaxTable == nil then
    print ("ERROR, server admin should ensure that the addon is installed correctly.") 
  else
    UpOrDownVoting.createViableMapsTable()
  end
end

function UpOrDownVoting.createViableMapsTable()
  local maplist = {}
  for mapname, minmax in pairs(UpOrDownVoting.mapMinMaxTable) do
    if minmax["minplayers"] <= UpOrDownVoting.playerCount and minmax["maxplayers"] >= UpOrDownVoting.playerCount then
      table.insert(maplist, mapname)
    end
  end
  return maplist
end

local function buildSelectionTable(probabilityTable)
  local previousmax = 0
  local selectionTable = {}
  for mapname, modifier in pairs(probabilityTable) do
    local min = previousmax
    local max = min + 100 + modifier
    previousmax = max + 1
    selectionTable[mapname] = {}
    selectionTable[mapname]["min"] = min
    selectionTable[mapname]["max"] = max
  end
  return selectionTable, previousmax
end

function UpOrDownVoting.randomizeMap(maplist) -- Sets the next map based on a modified probability
  local nextmap = ""
  if maplist ~= nil then
    
    local int32max = 2147483647
    local mapVotesRef = UpOrDownVoting.gatherMapRankings()    
    local probabilityTable = UpOrDownVoting.buildProbabilityTable(maplist, mapVotesRef)
    local selectionTable, selectionTableMax = buildSelectionTable(probabilityTable)
    
    local nextmapnumber = math.random(0, int32max) % selectionTableMax -- Sets probability
    
    for mapname, range in pairs(selectionTable) do
      if nextmapnumber >= range.min and nextmapnumber <= range.max then
        nextmap = mapname
        break
      end
    end
    
    if nextmap == UpOrDownVoting.currentMap and #maplist > 1 then
      return UpOrDownVoting.randomizeMap(maplist) 
    else 
      return nextmap
    end
  end
end

function UpOrDownVoting.buildProbabilityTable(maplist, mapVotesRef)
  local probabilityTable = {}
  
  for key, mapname in pairs(maplist) do
    probabilityTable[mapname] = 0
  end
  
  UpOrDownVoting.excludeMaps(probabilityTable, mapVotesRef)
  return probabilityTable
end

function UpOrDownVoting.excludeMaps(probabilitytable, mapVotesRef)
  for mapname, v in pairs(mapVotesRef) do
    if (probabilitytable[mapname] != nil) then
      local netvotes = v.upvotes - v.downvotes -- Gets the net vote count to apply to its probability
      if netvotes <= -50 then
        probabilitytable[mapname] = nil
      else
        probabilitytable[mapname] = netvotes
      end
    end
  end
end

local function decrementRound()
  if UpOrDownVoting.currentMapSettings != nil and currentPlayerCountOutOfRange(2) then
    PrintMessage(HUD_PRINTTALK, "SRMapVoting: Current Map is out of range of its intended population.\nDecrementing rounds by 2.")
    rounds_left = math.max(0, GetGlobalInt("ttt_rounds_left", 6) - 2)
  else
    rounds_left = math.max(0, GetGlobalInt("ttt_rounds_left", 6) - 1)
  end
end

local function checkForMapSwitch()
  updatePlayerCount()
    
  decrementRound()
  SetGlobalInt("ttt_rounds_left", rounds_left)
  time_left = math.max(0, (GetConVar("ttt_time_limit_minutes"):GetInt() * 60) - CurTime())
    
  UpOrDownVoting.recalculate()
  log.logDebug("Checking for last round...")
  checkForLastRound()
  log.logDebug("Checking if we should switch maps...")
  switchMap()
end

hook.Add("Initialize", "SRMapVoting_Initialize", function()
  --Override original TTT behavior.
  CheckForMapSwitch = checkForMapSwitch
  log.logDebug("\n\nOverrode CheckForMapSwitch\n\n")
end)

hook.Add("TTTEndRound", "SRMapVoting_EnsureOverride", function()
  if (CheckForMapSwitch != checkForMapSwitch) then
    log.logDebug("\n\nRe-Overrode CheckForMapSwitch\n\n")
    CheckForMapSwitch = checkForMapSwitch
  end
end)

  
--[[Get the viable maps from the array each round 
Change the next map set on the server based on playercount, ranking, and overall probability -> SQL Queries
Reshuffle and announce a new map if the playercount has changed out of minmax -> Chat/TopRightCorner Announcements
Display the next map before each round even if not changed -> Chat/TopRightCorner Announcements
Change the map at the end of the last round
]]--