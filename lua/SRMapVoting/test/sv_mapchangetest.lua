local mapchangetest = GUnit.Test:new("mapchange")

local function nextmapspec()
  UpOrDownVoting.mapChangeCheckAndSet()
  
  local currentmap = game.GetMap()
  local maplist = UpOrDownVoting.createViableMapsTable()
  local nextmap = UpOrDownVoting.setRandomNextMapFromList(maplist)

  GUnit.assert(nextmap):isNotNil()
  GUnit.assert(currentmap):shouldNotEqual(nextmap)
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

mapchangetest:addSpec("Switched to the next map successfully", nextmapspec)
mapchangetest:addSpec("Should exclude maps with <50 votes", excludemapspec)