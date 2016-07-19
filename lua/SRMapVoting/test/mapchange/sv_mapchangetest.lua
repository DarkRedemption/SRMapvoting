local mapchangetest = GUnit.Test:new("mapchange")
local oldCurrentMap = ""
local oldNextMap = ""
local oldPlayerCount = 0

local function beforeAll()
  oldCurrentMap = UpOrDownVoting.currentMap
  oldNextMap = UpOrDownVoting.nextmap
  oldPlayerCount = UpOrDownVoting.playerCount
end

local function afterAll()
  UpOrDownVoting.nextmap = oldNextMap
  UpOrDownVoting.playerCount = oldPlayerCount
end

local function nextmapspec()
  local currentmap = game.GetMap()
  for i = 1, 100 do
    UpOrDownVoting.playerCount = i % 25
    UpOrDownVoting.changeNextMapDueToPlayerCount()
    
    GUnit.assert(UpOrDownVoting.nextmap):isNotNil()
    GUnit.assert(#UpOrDownVoting.nextmap):shouldNotEqual(0)
    GUnit.assert(currentmap):shouldNotEqual(UpOrDownVoting.nextmap)
  end
end

local function notCurrentMapSpec()
  for i = 1, 1000 do
    UpOrDownVoting.playerCount = i % 25
    UpOrDownVoting.changeNextMapDueToPlayerCount()
    UpOrDownVoting.currentMap = UpOrDownVoting.nextmap -- Change the currentmap to something it can pick.
    UpOrDownVoting.nextmap = ""
    UpOrDownVoting.changeNextMapDueToPlayerCount()
    
    GUnit.assert(UpOrDownVoting.nextmap):shouldNotEqual(UpOrDownVoting.currentMap)
  end
end

local function excludemapspec()
  local map = "gm_testmap"
  local mapVotesTable = {}
  local probabilitytable = {}
  mapVotesTable[map] = {}
  mapVotesTable[map].upvotes = 1
  mapVotesTable[map].downvotes = 100
  probabilitytable[map] = 0
  UpOrDownVoting.excludeMaps(probabilitytable, mapVotesTable)
  GUnit.assert(probabilitytable[map]):isNil()
end

mapchangetest:beforeAll(beforeAll)
mapchangetest:afterAll(afterAll)
mapchangetest:addSpec("switch to the next map successfully", nextmapspec)
mapchangetest:addSpec("avoid switching to a map of the same name", nextmapspec)
mapchangetest:addSpec("exclude maps with <50 votes", excludemapspec)