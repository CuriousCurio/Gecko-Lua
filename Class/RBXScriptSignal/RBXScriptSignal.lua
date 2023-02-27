local RBXScriptConnection = require(script.Parent.RBXScriptConnection);

local PUBLIC = {
	Disconnect = function(self)
		for connection in pairs(self) do
			connection:Disconnect();
		end
		table.clear(self);
	end,
	Connect = function(self, Connector) -- Connects using a connector function
		local connection;
		local Disconnect = function()rawset(self, connection, nil);end
		connection = RBXScriptConnection.new(Connector, Disconnect);
		rawset(self, connection, true);
		return connection;
	end,
	Wait = function(self) -- Waits until the signal has fired
		local time = 0;
		local wait = true;
		local cxn = self:Connect(function()wait = nil;end);
		while (wait) do
			time += task.wait();
		end
		cxn:Disconnect();
		return time;
	end,
	Once = function(self, Connector)
		local cxn; cxn = self:Connect(function(...)Connector(...); cxn:Disconnect();end);
		return cxn;
	end
};

local RBXScriptSignal = {
	__index = PUBLIC,
	__newindex = function()end,
	__call = function(self, ...) -- For iteration
		local arg = {...};

		for connection in pairs(self) do
			local s,e = pcall(function() connection(table.unpack(arg)); end);
			if (s == false) then spawn(function() error(e); end) end
		end
	end,
	__tostring = function(self)
		return getmetatable(self).__type;
	end,
	__metatable = table.freeze({__type = "RBXScriptSignal"})
};


function RBXScriptSignal.new() -- If a table is used, it will be
	local self = setmetatable({}, RBXScriptSignal);
	return self;
end
return RBXScriptSignal;
