UpOrDownVoting = {}
UpOrDownVoting.version = "0.1.1-SNAPSHOT"

if SERVER then
  AddCSLuaFile("SRMapVoting/main/upordownvoting/cl_upordownvoting.lua")
  include("SRMapVoting/main/config/sv_minmaxconfig.lua")
  include("SRMapVoting/main/upordownvoting/sv_upordownvoting.lua")
  include("SRMapVoting/main/mapchange/sv_mapchange.lua")
  include("SRMapVoting/test/sv_testinit.lua")
end

if CLIENT then
  include("SRMapVoting/main/upordownvoting/cl_upordownvoting.lua")
end