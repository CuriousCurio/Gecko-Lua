local RBXScriptConnection = {
	__newindex = function(self)end,
	__call = function(self, ...)
		return self.Connector(...);
	end,
	__tostring = function(self)
		return getmetatable(self).__type .. (self.Connected and "+" or "-");
	end,
	__metatable = table.freeze({__type = "RBXScriptConnection"})
};



function RBXScriptConnection.new(Connector:(any), Disconnect:(any))
	local self = setmetatable({
		Connected = true,
		Disconnect = function(self)
			self.Connected = false;
			Disconnect(self);
		end,
		Connector = Connector
	}, RBXScriptConnection);
	return self;
end
return RBXScriptConnection;
