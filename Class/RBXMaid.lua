local function Destroy(a) a:Destroy(); end
local function Disconnect(a) a:Disconnect(); end

local function DestroyNext(a)
	if (type(a) == "table" or typeof(a) == "Instance") then return pcall(Destroy, a), nil; end
	return false;
end
local function DisconnectNext(a)
	if (type(a) == "table" or typeof(a) == "RBXScriptConnection") then return pcall(Disconnect, a), nil; end
	return false;
end
local function RecurseDescendants(table:{}, Fx:(any))
	if (type(table) ~= "table") then return; end
	for i,v in pairs(table) do
		if (Fx(v)) then
			RecurseDescendants(v, Fx);
		end
	end
end

local function DestroyAll(table)
	RecurseDescendants(table, DestroyNext);
end
local function DisconnectAll(table)
	RecurseDescendants(table, DisconnectNext);
end



local Maid = {};
Maid.__index = {
	Destroy = DestroyAll,
	Disconnect = DisconnectAll
}

function Maid.new()
	local self = setmetatable({}, Maid);
	return self;
end
Maid.__index.new = Maid.new;

return Maid;
