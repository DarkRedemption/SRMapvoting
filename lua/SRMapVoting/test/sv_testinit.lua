if GUnit then
  GUnit.load()
end

hook.Add("GUnitReady", "SRMapVotingLoadTests", function()
  GUnit.load()
end)