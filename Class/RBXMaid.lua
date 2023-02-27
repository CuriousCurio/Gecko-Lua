local typeof = function(a)
	local meta = getmetatable(a);
	if type(meta) ~= "table" or meta.__type == nil then return typeof(a); end
	if type(meta.__type) == "function" then return meta.__type(a); end
	return meta.__type;
end

local function RecurseDescendants(table:{}, Fx:(any))
	if (type(table) ~= "table") then return; end
	for i,v in pairs(table) do
		if (Fx(v)) then
			RecurseDescendants(v, Fx);
		end
	end
end
local function DestroyNext(a)
	local type_a = typeof(a);
	if (type_a == 'RBXMaid' or type_a == "ClassInstance" or type_a == "Instance") then a:Destroy(); return false; end
	return true;
end
local function DisconnectNext(a)
	local type_a = typeof(a);
	if (type_a == 'RBXMaid' or (type_a == "RBXScriptSignal" and type(a) == "table") or type_a == "RBXScriptConnection") then a:Disconnect(); return false; end
	return true;
end



local Maid = {};
Maid.__index = Maid;

Maid.Destroy = function(self)
	RecurseDescendants(self, function(a:any)return DestroyNext(a); end);
end
Maid.Disconnect = function(self)
	RecurseDescendants(self, function(a:any)return DisconnectNext(a); end);
end

function Maid.new(table:{})
	local self = setmetatable(table or {}, Maid);
	return self;
end

return Maid;
