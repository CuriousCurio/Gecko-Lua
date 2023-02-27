--!nocheck
-- This module connects to instance properties using RBXScriptSignal, each property can be locked

local PUBLIC = {
	Connect = function(self, i, instance:nil)
		local cxn:{} = self.cxn;
		local raw:{} = self.raw;
		if (cxn[i]) then cxn[i]:Disconnect(); end
		cxn[i] = instance:GetPropertyChangedSignal(i):Connect(function()
			if (raw[i]) then return; end --  not referencing the __self or base tables, so they can be deleted quickly
			self:Invoke(i, instance);
		end);
	end,

	Disconnect = function(self, i)
		local cxn:{} = self.cxn;
		local raw:{} = self.raw;
		if (i) then
			local connection = cxn[i];
			if (connection) then
				connection:Disconnect();
				cxn[i] = nil;
			end
			raw[i] = nil;
		else
			for _,connection in pairs(cxn) do
				connection:Disconnect();
			end
			table.clear(cxn);
			table.clear(raw);
		end
	end,
	Update = function(self)
		for i in pairs(self.cxn) do
			self:Connect(i);
		end
	end,
	Lock = function(self, i)
		self.raw[i] = true;
	end,
	Unlock = function(self, i)
		self.raw[i] = nil;
	end
}

local VirtualConnector = {};
VirtualConnector.__index = PUBLIC;

function VirtualConnector.new(invoke:(any))
	return setmetatable({
		cxn = {},
		raw = {},
		Invoke = invoke
	}, VirtualConnector)
end
return VirtualConnector;
