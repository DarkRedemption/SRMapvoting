local map=game.GetMap()

local tablename="SR_MapVotingTable"

local function createMapVotingTable()
  local query="create table " .. tablename .. " (id INTEGER PRIMARY KEY, mapname string not null, steamid string not null, votetype integer not null)"
  sql.Query(query)
end

local function addVote(ply, votetype) 
  local query="insert into " .. tablename .. " (mapname,steamid,votetype) values (\"" .. map .. "\", \"" .. ply:SteamID() .. "\", " .. votetype .. ")"
  sql.Query(query)
end

local function voteCheck(ply)
  local query="select * from " .. tablename .. " where mapname==\"" .. map .. "\" and steamid==\"" .. ply:SteamID() .. "\""
  local result= sql.Query(query)
  if result==nil then return -1
  elseif result==false then
    print (sql.LastError()) return -2
  else return tonumber(result[1]["votetype"]) 
  end
end

local function updateVote(ply, votetype)
  local query ="update " .. tablename .. " set votetype= " .. votetype .. " where mapname==\"" .. map .. "\" and steamid==\"" .. ply:SteamID() .. "\""
  sql.Query(query)
  end

local function voteChange(ply, votetype)
  if voteCheck(ply)==-1 then
    addVote(ply, votetype)
  elseif voteCheck(ply)==-2 then return -- Should this be returning something?
  else updateVote(ply, votetype) 
  end
end

util.AddNetworkString("SR_UpVotes")
util.AddNetworkString("SR_DownVotes")

net.Receive( "SR_UpVotes", function( len, ply )
    voteChange(ply, 1)
end)

net.Receive( "SR_DownVotes", function( len, ply )
    voteChange(ply, 0)
end)

function UpOrDownVoting.gatherMapRankings()
  local mapvotes = {}
  
  local query1="SELECT DISTINCT mapname FROM SR_MapVotingTable"
  local result1 = sql.Query(query1)

  local query2="SELECT mapname, COUNT(*) as upVoteCount FROM ".. tablename .." WHERE votetype == 1 GROUP BY mapname"
  local result2 = sql.Query(query2)

  local query3="SELECT mapname, COUNT(*) as downVoteCount FROM ".. tablename .." WHERE votetype == 0 GROUP BY mapname"
  local result3 = sql.Query(query3)

  if result1 ~= nil then
    for row, columns in pairs(result1) do
      mapvotes[columns["mapname"]] = {
        total = 0,
        upvotes = 0,
        downvotes = 0
      }
  end
end

    if result2 ~= nil then
      for row, columns in pairs(result2) do 
      mapvotes[columns["mapname"]]["upvotes"] = columns["upVoteCount"]
      mapvotes[columns["mapname"]]["total"] = mapvotes[columns["mapname"]]["total"] + columns["upVoteCount"]
    end
  end

    if result3 ~= nil then
      for row, columns in pairs(result3) do 
      mapvotes[columns["mapname"]]["downvotes"] = columns["downVoteCount"]
      mapvotes[columns["mapname"]]["total"] = mapvotes[columns["mapname"]]["total"] - columns["downVoteCount"]
    end
  end

  return mapvotes
end

util.AddNetworkString("SR_MapVotes")
util.AddNetworkString("SR_GetRankings")
util.AddNetworkString("SR_ReceiveRankings")
util.AddNetworkString("SR_ClearVotesCommand")

net.Receive( "SR_MapVotes", function( len, ply ) --Either pass in two parameters, giving it the "upVoteCount"/"downVoteCount" string and the votetype, or one parameter (preferably the votetype) and use an if statement inside the function to deduce what the other values should be.
    local query1="SELECT COUNT (*) AS upVoteCount from " .. tablename .. " where mapname==\"" .. map .. "\" and votetype==1"
    local result1 = sql.Query(query1)
    local query2="SELECT COUNT (*) AS downVoteCount from " .. tablename .. " where mapname==\"" .. map .. "\" and votetype==0"
    local result2 = sql.Query(query2)
    print ("This map has ".. result1[1]["upVoteCount"] .. " upvotes and " .. result2[1]["downVoteCount"] .. " downvotes")
    PrintMessage(HUD_PRINTTALK, "This map has ".. result1[1]["upVoteCount"] .. " upvotes and " .. result2[1]["downVoteCount"] .. " downvotes")
  end)

net.Receive( "SR_GetRankings", function( len, ply )
    local rankings = UpOrDownVoting.gatherMapRankings()
    net.Start ("SR_ReceiveRankings")
    net.WriteTable(rankings)
    net.Send(ply)
end)

createMapVotingTable()