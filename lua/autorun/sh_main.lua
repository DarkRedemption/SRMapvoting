timer.Simple(1, function() print("test") end)

UpOrDownVoting = {}

if SERVER then
  AddCSLuaFile("SRMapVoting/upordownvoting/cl_upordownvoting.lua")
  include("SRMapVoting/upordownvoting/sv_upordownvoting.lua")
  include("SRMapVoting/config/sv_minmaxconfig.lua")
  include("SRMapVoting/mapchange/sv_mapchange.lua")
  include("SRMapVoting/test/sv_testinit.lua")
  end

if CLIENT then 
  include("SRMapVoting/upordownvoting/cl_upordownvoting.lua") 
end 