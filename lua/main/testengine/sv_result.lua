local Colors = GUnit.Colors

local Result = {}

function Result:print()
  if (self.passed) then
    MsgC(Colors.green, "+ " .. self.specName .. ": PASSED\n")
  else
    MsgC(Colors.red, "- " .. self.specName .. ": FAILED, error was: " .. self.errorMessage .. "\n")
  end
end

--[[
Holds the result for a spec.
Parameters:
specName: String - The name of the spec in the Test class that ran.
passed: Boolean - Whether or not the spec passed. If nil, autoconverts to false.
errorMessage: [String, Nil] - A string containing the error if failed. Nil otherwise.
]]
function Result:new(specName, passed, errorMessage)
  local newResult = {}
  setmetatable(newResult, self)
  self.__index = self
  
  newResult.specName = specName
  newResult.passed = passed or false
  newResult.errorMessage = errorMessage

  return newResult
end

GUnit.Result = Result