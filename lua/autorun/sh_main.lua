UpOrDownVoting = {}
UpOrDownVoting.version = "0.1.0"

if SERVER then
  AddCSLuaFile("SRMapVoting/upordownvoting/cl_upordownvoting.lua")
  include("SRMapVoting/config/sv_minmaxconfig.lua")
  include("SRMapVoting/upordownvoting/sv_upordownvoting.lua")
  include("SRMapVoting/mapchange/sv_mapchange.lua")
  include("SRMapVoting/test/sv_testinit.lua")
end

if CLIENT then
  include("SRMapVoting/upordownvoting/cl_upordownvoting.lua")
end