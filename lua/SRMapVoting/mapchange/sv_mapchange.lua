-- This section is intended to create a table of maps that are on the server, using the sv_minmaxconfig.lua.

-- These are the initial values for this set of variables.

local map = game.GetMap()
local mapMinMaxTable = UpOrDownVoting.mapMinMaxTable
local nextmap = ""
local switchmap = false

local playercount = #player.GetAll()
local currentplayercount = #player.GetAll()

local time_left = math.max(0, (GetConVar("ttt_time_limit_minutes"):GetInt() * 60) - CurTime())
local rounds_left = math.max(0, GetGlobalInt("ttt_rounds_left", 6) - 1)

SetGlobalInt("ttt_rounds_left", rounds_left)

------------------------------------------------------------------------------------

local function checkForLastRound()
  if rounds_left <= 0 then
    LANG.Msg("limit_round", {mapname = nextmap})
    switchmap = true
  elseif time_left <= 0 then
    LANG.Msg("limit_time", {mapname = nextmap})
    switchmap = true
  end
end

local function switchMap()
  if switchmap then
    timer.Stop("end2prep")
    timer.Simple(15, RunConsoleCommand ("changelevel", nextmap))
  else
  LANG.Msg("limit_left", {num = rounds_left,
                          time = math.ceil(time_left / 60),
                          mapname = nextmap})
  end
end

local function recalculate()
  playercount = #player.GetAll()
  UpOrDownVoting.changeNextMapDueToPlayerCount()
end

hook.Add("PlayerInitialSpawn", function()
    recalculate()
end)

hook.Add("PlayerDisconnected", function()
    recalculate()
end)

hook.Add("TTTPrepareRound", function()
  UpOrDownVoting.mapChangeCheckAndSet()
end)

-- A central function that should probably be based on returned true, false, or nil values in the following functions.
function UpOrDownVoting.mapChangeCheckAndSet() 
  currentplayercount = playercount
  UpOrDownVoting.checkForMinMaxTable()
end

function UpOrDownVoting.checkForMinMaxTable()
  if mapMinMaxTable == nil then
    print ("ERROR, server admin should ensure that the addon is installed correctly. sv_minmaxconfig.lua cannot be found in     addons/SRMapVoting/lua/config/.") 
  else
    UpOrDownVoting.createViableMapsTable()
  end
end

function UpOrDownVoting.changeNextMapDueToPlayerCount()
  if playercount ~= currentplayercount and 
  (mapMinMaxTable[nextmap]["minplayers"] <= currentplayercount or mapMinMaxTable[nextmap]["maxplayers"] >= currentplayercount) then
    local maplist = UpOrDownVoting.createViableMapsTable()
    UpOrDownVoting.setRandomNextMapFromList(maplist)
  end
end

function UpOrDownVoting.createViableMapsTable()
  local maplist = {}
  for mapname, minmax in pairs(UpOrDownVoting.mapMinMaxTable) do -- Add to own function?
    if minmax["minplayers"] >= playercount and minmax["maxplayers"] <= playercount then
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
    selectiontable[mapname]["min"] = min
    selectiontable[mapname]["max"] = max
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
    local nextmapnumber = math.random() % previousmax -- Sets probability
    
    for mapname, range in pairs(selectionTable) do
      if nextmapnumber >= range.min and nextmapnumber <= range.max then
        nextmap = mapname
        break
      end
    end
    
    if nextmap == map then
      return UpOrDownVoting.setRandomNextMapFromList() else
      return nextmap
    end
  end
end
--[[Get the viable maps from the array each round 
Change the next map set on the server based on playercount, ranking, and overall probability -> SQL Queries
Reshuffle and announce a new map if the playercount has changed out of minmax -> Chat/TopRightCorner Announcements
Display the next map before each round even if not changed -> Chat/TopRightCorner Announcements
Change the map at the end of the last round
]]--