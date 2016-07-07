-- This section is intended to create a table of maps that are on the server, using the sv_minmaxconfig.lua.

-- These are the initial values for this set of variables.

UpOrDownVoting.nextmap = ""

local map = game.GetMap()
local mapMinMaxTable = UpOrDownVoting.mapMinMaxTable
local switchmap = false

local playercount = #player.GetAll()
local lastKnownPlayerCount = #player.GetAll()

local time_left = math.max(0, (GetConVar("ttt_time_limit_minutes"):GetInt() * 60) - CurTime())
local rounds_left = math.max(0, GetGlobalInt("ttt_rounds_left", 6) - 1)

SetGlobalInt("ttt_rounds_left", rounds_left)

------------------------------------------------------------------------------------

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
    timer.Stop("end2prep")
    timer.Simple(10, RunConsoleCommand ("changelevel", UpOrDownVoting.nextmap))
  else
    LANG.Msg("limit_left", {num = rounds_left,
                            time = math.ceil(time_left / 60),
                            mapname = UpOrDownVoting.nextmap})
  end
end

function UpOrDownVoting.recalculate()
  playercount = #player.GetAll()
  UpOrDownVoting.changeNextMapDueToPlayerCount()
end

function UpOrDownVoting.changeNextMapDueToPlayerCount()
  if UpOrDownVoting.nextmap == "" or UpOrDownVoting.nextmap == nil or 
  (playercount ~= lastKnownPlayerCount and
  (mapMinMaxTable[UpOrDownVoting.nextmap]["minplayers"] <= playercount or mapMinMaxTable[UpOrDownVoting.nextmap]["maxplayers"] >= playercount)) then
    local maplist = UpOrDownVoting.createViableMapsTable()
    UpOrDownVoting.nextmap = UpOrDownVoting.setRandomNextMapFromList(maplist)
  end
  lastKnownPlayerCount = playercount
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
    if minmax["minplayers"] <= playercount and minmax["maxplayers"] >= playercount then
      table.insert(maplist, mapname)
    end
  end
  return maplist
end

function UpOrDownVoting.excludeMaps(probabilitytable, mapvotesref)
  for mapname, v in pairs(mapvotesref) do
    local netvotes = v.upvotes - v.downvotes -- Gets the net vote count to apply to its probability
    if netvotes <= -50 then
      probabilitytable[mapname] = nil
    else
      probabilitytable[mapname] = netvotes
    end
  end
end

local function buildSelectionTable(selectionTable, probabilityTable)
  local previousmax = 0
  for mapname, modifier in pairs(probabilityTable) do
    local min = previousmax
    local max = min + 100 + modifier
    previousmax = max + 1
    selectionTable[mapname] = {}
    selectionTable[mapname]["min"] = min
    selectionTable[mapname]["max"] = max
  end
  return previousmax
end

function UpOrDownVoting.setRandomNextMapFromList(maplist) -- Sets the next map based on a modified probability
  local nextmap = ""
  if maplist ~= nil then
    local probabilityTable = {}
    local selectionTable = {}
    local mapVotesRef = UpOrDownVoting.gatherMapRankings()
    
    for key, mapname in pairs(maplist) do
      probabilityTable[mapname] = 0
    end
    
    UpOrDownVoting.excludeMaps(probabilityTable, mapVotesRef)
    
    local previousmax = buildSelectionTable(selectionTable, probabilityTable)
    local int32max = 2147483647
    local nextmapnumber = math.random(0, int32max) % previousmax -- Sets probability
    for mapname, range in pairs(selectionTable) do
      if nextmapnumber >= range.min and nextmapnumber <= range.max then
        nextmap = mapname
        break
      end
    end
    
    if nextmap == map and #maplist > 1 then
      return UpOrDownVoting.setRandomNextMapFromList(maplist) else
      return nextmap
    end
  end
end

hook.Add("PlayerInitialSpawn", "SRMapVoting_PlayerSpawnRecalculate", function(ply)
    UpOrDownVoting.recalculate()
end)

hook.Add("PlayerDisconnected", "SRMapVoting_PlayerDisconnectRecalculate", function(ply)
    UpOrDownVoting.recalculate()
end)

hook.Add("Initialize", "SRMapVoting_Initialize", function()
  UpOrDownVoting.checkForMinMaxTable()
end)

hook.Add("TTTEndRound", "SRMapVoting_EndRound", function(result)
  UpOrDownVoting.checkForMinMaxTable()
  UpOrDownVoting.recalculate()
end)

--Override original TTT behavior.
  function CheckForMapSwitch()
    checkForLastRound()
    switchMap()
  end
  
--[[Get the viable maps from the array each round 
Change the next map set on the server based on playercount, ranking, and overall probability -> SQL Queries
Reshuffle and announce a new map if the playercount has changed out of minmax -> Chat/TopRightCorner Announcements
Display the next map before each round even if not changed -> Chat/TopRightCorner Announcements
Change the map at the end of the last round
]]--