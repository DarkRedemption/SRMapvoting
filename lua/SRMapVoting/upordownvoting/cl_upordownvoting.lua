local tablename="SR_MapVotingTable"

local red = Color(255, 0, 0, 255)
local yellow = Color(255, 255, 0, 255)
local green = Color(0, 255, 0, 255)

local function checkForTag(ply)
  if ply:IsUserGroup("user") then
    chat.AddText(red, "You must be a member of this community before you can vote on maps.")
    return false
  end
  return true
end

function UpOrDownVoting.checkForVoteCommand(ply, text) -- Checks chat for relevant upvote/downvote commands when a player chats
  if text:len()<7 or text:len()>9 then return false end
  if text=="!upvote" and checkForTag(ply) then
    if (LocalPlayer() == ply) then
      net.Start("SR_UpVotes")
      net.SendToServer()
      chat.AddText(green, "Your vote for this map has been set as an upvote.")
    end
    return true
  elseif text=="!downvote" and checkForTag(ply) then
    if (LocalPlayer() == ply) then
      net.Start("SR_DownVotes")
      net.SendToServer()
      chat.AddText(red, "Your vote for this map has been set as a downvote.")
    end
    return true
  end
  return false
end

function UpOrDownVoting.checkForVoteTotalCommand(ply, text) -- Checks chat for list command when a player chats
  if text:len()==9 and text=="!mapvotes" then
    if (LocalPlayer() == ply) then
      net.Start("SR_MapVotes")
      net.SendToServer()
    end
    return true
  end
  return false
end

hook.Add("OnPlayerChat", "mapvotingcommandcheck", function(ply, text, team, isDead)
    if UpOrDownVoting.checkForVoteCommand(ply, text) or UpOrDownVoting.checkForVoteTotalCommand(ply, text) then 
      return true 
    end
  end)
  
local function getRankingsFromServer() -- Gets all map ranking information and creates a GUI containing this information
  net.Start("SR_GetRankings")
  net.SendToServer()

  net.Receive("SR_ReceiveRankings", function(len)
      
    local mapvotes = net.ReadTable()
    
    local Frame = vgui.Create( "DFrame" ) -- VGUI NEEDS CLEANING
    Frame:SetPos( 200, 400 ) -- Get the frame to appear at the center of the screen
    Frame:SetSize( 1000, 500) -- Make sure frame size is appropriate, or make SetSizable function properly.
    --Frame:SetSizable( 1 )
    Frame:SetTitle( "Map Rankings" )
    Frame:SetVisible( true )
    Frame:SetDraggable( true )
    Frame:ShowCloseButton( true )
    Frame:MakePopup()

  local DPanel = vgui.Create( "DPanel", Frame ) -- Improve GUI appearance
    DPanel:SetPos( 10, 50 )
    DPanel:SetSize( 950, 450 )
    
  local AppList = vgui.Create( "DListView", DPanel ) -- Get the values in the table to center for easier readability
    AppList:SetPos( 1, 1 )
    AppList:SetSize( 900, 400)
    --AppList:SortByColumn( 2, false )
    AppList:SetSortable( true )
    AppList:SetMultiSelect( false )
    AppList:AddColumn( "Map Name" )
    AppList:AddColumn( "Total" )
    AppList:AddColumn( "Upvotes" )
    AppList:AddColumn( "Downvotes" )
    
    for mapname, columns in pairs(mapvotes) do
      AppList:AddLine(mapname, tonumber(mapvotes[mapname]["total"]), tonumber(mapvotes[mapname]["upvotes"]), tonumber(mapvotes[mapname]["downvotes"]))
    end
  end)
end

if CLIENT then
  timer.Simple(600, function()
    chat.AddText(red, "This server is running SR_MapVoting " .. UpOrDownVoting.version .. ".")
    chat.AddText(red, "Type ", yellow, "!upvote", red, " to see this map more often, or ", yellow, "!downvote", red, " if you want to see it less.")
    chat.AddText(red, "Type ", yellow, "!mapvotes", red, " to see this map's votes.")
  end)
end

concommand.Add( "SR_ShowMapRankings", getRankingsFromServer )