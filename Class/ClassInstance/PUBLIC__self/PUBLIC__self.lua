-- This module returns a PUBLIC__self library for the ClassInstance type
local ErrorHandler = require(script.Parent.ErrorHandler);
local CastHandler = require(script.Parent.CastHandler);
local VirtualConnector = require(script.Parent.VirtualConnector);
local RBXMaid = require(script.Parent.Parent.Parent.RBXMaid);

local typeof = function(a)
	local meta = getmetatable(a);
	if type(meta) ~= "table" or meta.__type == nil then return typeof(a); end
	if type(meta.__type) == "function" then return meta.__type(a); end
	return meta.__type;
end
local pcall = function(a, ...)
	local s,e = pcall(a, ...);
	if (s == true) then return s,e; end
	return s,e:match(".+\.[a-zA-Z]+:[0-9]*:(.+)") or e; -- Removes existing script reference  "Class.ClassInstance.PUBLIC__self:171:"
end

local PUBLIC = {
	__superroot = function(__self) -- Gets the deepsest __subroot value (can be Instance/ClassInstance)
		local __super__self = __self:__super__self();
		if (__super__self) then return __super__self:__superroot(); end
		return rawget(__self, "__super");
	end,
	__super__self = function(__self)
		local __super = rawget(__self, "__super");
		if (type(__super) == "table") then return __super.__self; end
	end,
	__superroot__self = function(__self)
		local __superroot = __self:__superroot();
		if (__superroot) then return __superroot.__self; end
	end,
	__subroot = function(__self) -- Gets the deepsest __sub value
		local __sub = rawget(__self, "__sub");
		if (__sub == nil) then return; end
		return __sub.__self:__subroot() or __sub
	end,
	__sub__self = function(__self)
		local __sub = rawget(__self, "__sub");
		if (__sub) then return __sub.__self; end
	end,
	__subroot__self = function(__self)
		local __subroot__self = __self:__subroot();
		if (__subroot__self) then return __subroot__self.__self; end
	end,
	
	push_class = function(__self, class, ...)
		__self.__struct:Insert(class.__struct);
		local __init = class.__struct:get__("__init");
		if (__init) then __init(__self.__self, ...) end; -- Firing __init__ (constructor) found in class
	end,

	push = function(__self, table) -- :set() on all given properties
		if (table == nil) then return; end
		if (type(table) ~= "table") then error(string.format("invalid argument #%i to \"%s\" (%s expected, got %s)", 1, "apply", "table/nil", typeof(table))) end
		
		for i,v in pairs(table) do
			if (i == "Parent") then continue; end
			__self:set(i, v);
		end
		
		local parent = table.Parent;
		if (parent) then -- Setting Parent last
			if (typeof(parent) == "ClassInstance") then parent = parent:__superroot(); end
			__self:set("Parent", parent);
		end
	end,
	rawpush = function(__self, table) -- :rawset() on this instance
		if (table == nil) then return; end
		if (type(table) ~= "table") then error(string.format("invalid argument #%i to \"%s\" (%s expected, got %s)", 1, "rawapply", "table/nil", typeof(table))) end
		for i,v in pairs(table) do
			if (i == "Parent") then continue; end
			__self:rawset(i, v);
		end
		
		local parent = table.Parent;
		if (parent) then -- Setting Parent last
			if (typeof(parent) == "ClassInstance") then parent = parent:__superroot(); end
			__self:rawset("Parent", parent);
		end
	end,
	pull = function(__self, table) -- unpacks all properties and subclass properties into a table that can be applied to the same class
		table = table or {};
		for i,v in __self:iterate__() do
			if (table[i] == nil) then table[i] = v; end
		end
		if (__self:__super__self()) then __self:__super__self():pull(table); end
		return table;
	end,
	update_all = function(__self)
		local class = __self.__class;
		local __init__newindex_order = class.__init__newindex_order;
		local __init__newindex_ignore = class.__init__newindex_ignore;
		
		--  Updating Queue, and Class Properties  --
		if (__init__newindex_order) then
			for _,i in ipairs(__init__newindex_order) do
				__self:update(i);
			end
		end
		
		--  Updating __newindex  --
		for i,v in __self:iterate__newindex() do
			if (__init__newindex_ignore and table.find(__init__newindex_ignore, i)) then continue; end
			if (__init__newindex_order and table.find(__init__newindex_order, i)) then continue; end
			if (v) then __self:update(i); end
		end
		
		--  Updating __virtual  --
		for i,v in __self:iterate__virtual() do
			if (__init__newindex_ignore and table.find(__init__newindex_ignore, i)) then continue; end
			if (__init__newindex_order and table.find(__init__newindex_order, i)) then continue; end
			__self:update(i);
		end
	end,
	update = function(__self, i, fire:nil|true|false) -- Updates a setter
		local __newindex = __self:get__newindex(i);
		if (__newindex == false) then error(string.format("\"%s\" has a locked __newindex.", i)); end
		if (__newindex == nil) then -- If not found then update an existing __virtual
			local __virtual = __self:get__virtual(i);
			if (__virtual) then __virtual(__self.__self, i, __self:get(i)); end
			return;
		end
		
		local v = __self:get(i);
		__newindex(__self.__self, i, v);
		if (not __self:has__(i)) then return; end -- If this property has been removed during __newindex, return
		if (fire == true or (fire == nil and v ~= __self:get__(i))) then __self:fire(i); end -- true (fire)		false (don"t fire)			nil (fire if changed)
	end,
	fire = function(__self, i) -- Fires all changed events of an index
		local v = __self:get(i);
		for cx in pairs(__self:rawget("Changed")) do
			task.spawn(function()	cx(i, v);	end);
		end
		local __changed = __self.__changed[i];
		if (__changed) then
			for cx in pairs(__changed) do	
				task.spawn(function()	cx(v);	end);
			end
		end
	end,
	
	
	
	set = function(__self, i, v,    _ref_:nil) -- Sets a value from this specific Instance using a setter
		local __newindex_meta = __self:find__newindex_meta(i); -- Basic __newindex Setter
		if (__newindex_meta) then return __newindex_meta(__self.__self, i, v); end
		-----------------------------
		if (not __self:has__(i)) then
			if (not __self.__super) then error(ErrorHandler:Index((_ref_ or __self).__self, i)); end -- Error if unavailable
			if (_ref_ == nil) then assert(pcall(__self["set__super"], __self, i, v, _ref_ or __self)); return; end -- Keep error on top stack if top call
			return __self:set__super(i, v, _ref_ or __self);
		end
		-----------------------------
		local from = __self:get__(i);
		v = CastHandler:Cast(__self:get__type(i), i, from, v);
		if (from == v) then return; end -- If not a new value, then return
		
		local __newindex = __self:get__newindex(i);
		if (__newindex == false) then error(string.format("\"%s\" has a locked __newindex.", i)); end
		if (__newindex == nil) then __self:rawset(i, v); __self:fire(i); return; end
		__newindex(__self.__self, i, v);
		if (__self.__self == nil) then return; end -- Returning if the instance has been destroyed
		if (from ~= __self:get__(i)) then __self:fire(i); end -- Firing if changed
	end,
	get = function(__self, i,    _ref_:nil) -- Gets a value from this specific Instance using a getter
		local __index_meta = __self:find__index_meta(i); -- Basic __index Getter
		if (__index_meta) then return __index_meta(__self.__self, i); end
		-----------------------------
		if (not __self:has__(i)) then
			if (not __self.__super) then error(ErrorHandler:Index((_ref_ or __self).__self, i)); end -- Error if unavailable
			if (_ref_ == nil) then local _,ret = assert(pcall(__self["get__super"], __self, i, _ref_ or __self)); return ret; end -- Keep error on top stack if top call
			return __self:get__super(i, _ref_ or __self);
		end
		-----------------------------
		local __index = __self:get__index(i);
		if (__index == false) then error(string.format("The property \"%s\" is not retreivable.", i)); end
		if (__index == nil) then return __self:rawget(i); end -- If no getter, get using default method
		return __index(__self.__self, i);
	end,
	rawset = function(__self, i, v,    _ref_:nil) -- Sets a property, without calling __newindex or __virtual
		local __newindex_meta = __self:find__newindex_meta(i);
		if (__newindex_meta) then __newindex_meta(__self.__self, i, v); return; end
		-----------------------------
		if (not __self:has__(i)) then
			if (not __self.__super) then error(ErrorHandler:Index((_ref_ or __self).__self, i));end -- Error if unavailable
			if (_ref_ == nil) then assert(pcall(__self["rawset__super"], __self, i, v, _ref_ or __self)); return; end -- Keep error on top stack if top call
			return __self:rawset__super(i, v, _ref_ or __self);
		end
		-----------------------------
		v = CastHandler:Cast(__self:get__type(i), i, __self:get__(i), v);
		__self:set__(i, v);
	end,
	rawget = function(__self, i,    _ref_:nil)  -- Gets a property, without calling __index
		local __index_meta = __self:find__index_meta(i);
		if (__index_meta) then return __index_meta(__self.__self, i); end
		-----------------------------
		if (not __self:has__(i)) then
			if (not __self.__super) then local _,ret = error(ErrorHandler:Index((_ref_ or __self).__self, i)); return ret; end -- Error if unavailable
			if (_ref_ == nil) then assert(pcall(__self["rawget__super"], __self, i, _ref_ or __self)); end -- Keep error on top stack if top call
			return __self:rawget__super(i, _ref_ or __self);
		end
		-----------------------------
		return __self:get__(i);
	end,
	set__super = function(__self, i, v,    _ref_:nil) -- Sets a subclass property
		if (not __self:has__super__(i) and __self.__super == __self:__superroot()) then error(ErrorHandler:Index((_ref_ or __self).__self, i)); end
		if (__self:__super__self()) then  -- ClassInstance
			if (_ref_ == nil) then assert(pcall(__self:__super__self()["set"], __self, i, v, _ref_ or __self)); end -- Keep error on top stack if top call
			__self:__super__self():set(i, v, _ref_ or __self);
			return;
		end
		if (__self.__super) then __self.__super[i] = v; return; end -- Instance
	end,
	get__super = function(__self, i,    _ref_:nil) -- Gets a subclass property
		if (not __self:has__super__(i) and __self.__super == __self:__superroot()) then error(ErrorHandler:Index((_ref_ or __self).__self, i)); end
		local __call = __self:find__super__call(i);
		if (__call) then return function(_, ...)return __call(__self.__super, ...); end end
		if (__self:__super__self()) then   -- ClassInstance
			if (_ref_ == nil) then local _,ret = assert(pcall(__self:__super__self()["get"], __self, i, _ref_ or __self)); return ret; end -- Keep error on top stack if top call
			return __self:__super__self():get(i, _ref_ or __self);
		end
		if (__self.__super) then return __self.__super[i]; end  -- Instance
	end,
	rawset__super = function(__self, i, v,    _ref_:nil) -- Sets a subclass property without calling a virtual
		if (not __self:has__super__(i) and __self.__super == __self:__superroot()) then error(ErrorHandler:Index((_ref_ or __self).__self, i)); end
		if (__self:__super__self()) then  -- ClassInstance
			if (_ref_ == nil) then assert(pcall(__self:__super__self()["rawset"], __self, i, v, _ref_ or __self)); end -- Keep error on top stack if top call
			__self:__super__self():rawset(i, v, _ref_ or __self);
			return;
		end
		if (__self.__super) then -- Instance
			for __sub__self in __self:iterate__sub__self() do
				local __virtual__cxn = __sub__self.__virtual__cxn;
				if (__virtual__cxn == nil) then continue; end
				__virtual__cxn:Lock(i);
			end
			__self.__super[i] = v;
			task.delay(0.01, function()
				for __sub__self in __self:iterate__sub__self() do
					local __virtual__cxn = __sub__self.__virtual__cxn;
					if (__virtual__cxn == nil) then continue; end
					__virtual__cxn:Unlock(i);
				end
			end);
		end
	end,
	rawget__super = function(__self, i,    _ref_:nil) -- Gets a subclass property, if a method, then create a returnable method function
		if (not __self:has__super__(i) and __self.__super == __self:__superroot()) then error(ErrorHandler:Index((_ref_ or __self).__self, i)); end
		local __call = __self:find__super__call(i);
		if (__call) then return function(_, ...) return __call(__self.__super, ...); end end
		if (__self:__super__self()) then -- ClassInstance
			if (_ref_ == nil) then local _,ret = assert(pcall(__self:__super__self()["rawget"], __self, i, _ref_ or __self)); return ret; end -- Keep error on top stack if top call
			return __self:__super__self():rawget(i, _ref_ or __self);
		end
		if (__self.__super) then return __self.__super[i]; end -- Instance
	end,
	
	isa = function(__self, i)
		if (__self.__class == i) then return true; end
		if (__self.__class.ClassName == i) then return true; end
		if (__self:__super__self()) then return __self:__super__self():isa(i); end
		if (__self.__super) then return __self.__super.ClassName == i; end
		return false;
	end,
	
	disconnect = function(__self) -- Disconnects this PUBLIC__self class
		__self.cxn:Disconnect(); -- Disconnects all RBXScriptSignals RBXScriptConnections in this ClassInstance
		__self.__changed:Disconnect();
		if (__self.__virtual__cxn) then __self.__virtual__cxn:Disconnect(); end
	end,
	destroy = function(__self) -- Destroys this PUBLIC__self class
		if (__self.destroying) then return; end
		__self.destroying = true;
		
		local __instance = __self.__self;
		local __destroying:nil|(any) = __self.__class.__destroying; -- Calls the OnDestroy tag with the Instance as the first variable before anything else
		if (__destroying) then __destroying(__instance); end
		
		for cx in pairs(__self:get__("Destroying")) do -- Calling attached destroying connectors
			local s,e = pcall(cx);
			if (s == false) then warn(e .. "\n" .. debug.traceback()); end
		end
		
		__self:disconnect();
		__self.__class.Instances[__instance] = nil;
		
		local __super:nil|Instance = __self.__super;
		if (__super) then  pcall(function()__super:Destroy();end);  end
		
		__self.__bin:Destroy();	-- Destroying protected bin and inheritance
		table.clear(__self);
		rawset(__instance, '__self', nil);
	end,
	mount__super = function(__self, __super) -- Sets the superclass of an Instance
		local is_Instance = typeof(__super) == "Instance";
		local is_ClassInstance = not is_Instance and typeof(__super) == "ClassInstance";
		if (__super ~= nil and not is_Instance and not is_ClassInstance) then error(string.format("invalid argument #%i to \"%s\" (%s expected, got %s)", 1, "mount__super", "_Instance/Instance", typeof(__super))); end
		
		-- Removing old subclass from superclass --
		if (__self:__super__self()) then __self:__super__self().__sub = nil; end
		
		-- Getting new __super__self --
		local __super__self = (is_ClassInstance and __super.__self) or nil;
		if (__super__self) then __super__self.__sub = __self.__self; end -- Setting [__sub and __sub__self] inside __super__self
		__self.__super = __super;
		
		-- Destroying
		local __destroy__ = __self.cxn.__destroy__;
		if (__destroy__) then __destroy__:Disconnect(); __self.cxn.__destroy__ = nil; end -- Disconnecting base_destroy connection if possible
		if (__super) then __self.cxn.__destroy__ = __super.Destroying:Connect(function() __self:destroy(); end); end -- When subclass is destroying, destroy this Instance
		
		-- Refreshing Virtual Subclass Connectors --
		__self:update__virtual();
		for __sub__self in __self:iterate__sub__self() do
			__sub__self.__self:update__virtual();
		end
	end,
	
	iterate__sub = function(__self)
		local __sub;
		return function() __sub = (__sub or __self).__sub; return __sub; end;
	end,
	iterate__sub__self = function(__self)
		local __sub__self;
		return function() __sub__self = (__sub__self or __self):__sub__self(); return __sub__self; end;
	end,
	iterate__super = function(__self)
		local __super;
		return function() __super = (__super or __self).__super; return __super; end;
	end,
	iterate__super__self = function(__self)
		local __super__self;
		return function() __super__self = (__super__self or __self):__super__self(); return __super__self; end;
	end,
	
	
	
	sort = function(__self, ...)return __self.__struct:sort(...); end,
	remove = function(__self, i) -- Removes a property that was created
		__self.__struct:remove(i);
		local __changed = __self.__changed[i];
		if (__changed) then __changed:Disconnect() __self.__changed[i] = nil; end
		__self.__virtual__cxn:Disconnect(i);
	end,
	has = function(__self, i) -- Checks if a property exists in every superclass
		if (__self:has__(i)) then return true; end
		if (__self:__super__self()) then return __self:__super__self():has(i); end
		if (__self.__super and __self:has__super__(i)) then return true; end
		return false;
	end,
	has__ = function(__self, ...)return __self.__struct:has__(...); end,
	has__super__ = function(__self, i) -- Checks if a property exists in this ClassInstance's superclass
		if (__self:__super__self()) then return __self:__super__self():has__(i); end
		if (__self.__super) then return pcall(function() return __self.__super[i]; end), nil; end 
		return false;
	end,
	set__ = function(__self, i, v) __self.__struct.__[i] = v; end,
	set__type = function(__self, i, v) __self.__struct:set__type(i, v); end,
	set__index = function(__self, i, v) __self.__struct:set__index(i, v); end,
	set__newindex = function(__self, i, v) __self.__struct:set__newindex(i, v); end,
	
	refresh__virtual = function(__self)
		local empty = next(__self.__struct.__virtual) == nil;
		if (empty and __self.__virtual__cxn) then -- No virtual values
			__self.__virtual__cxn = nil;
		elseif (not empty and __self.__virtual__cxn == nil) then
			__self.__virtual__cxn = VirtualConnector.new(function(_, i, instance) -- All __virtual attributes connect to __super using a property connector
				if (__self:get__("__init")) then return; end
				local __virtual = __self:get__virtual(i);
				if (__virtual) then __virtual(__self.__self, i, instance[i]); end
			end);
		end
	end,
	-- TODO Connect Virtual Functions Seperatly
	update__virtual = function(__self)
		local __virtual__cxn = __self.__virtual__cxn;
		if (__virtual__cxn) then
			for i,v in __self:iterate__virtual() do
				if (__virtual__cxn.cxn[i] == nil) then
					local __super = __self:find__virtual__super(i);
					if (__super == nil) then error("Virtual property '".. i .."' not found in any superclass"); end
					__virtual__cxn:Connect(i, __self:find__virtual__super(i));
				end
			end
		end
	end,
	set__virtual = function(__self, i, v)
		__self.__struct:set__virtual(i, v);
		if (__self.__virtual__cxn) then
			if (v) then
				__self.__virtual__cxn:Connect(i);
			else
				__self.__virtual__cxn:Disconnect(i);
			end
		end
	end,
	get__ = function(__self, i)return __self.__struct.__[i]; end,
	get__type = function(__self, i)return __self.__struct.__type[i]; end,
	get__index = function(__self, i)return __self.__struct.__index[i]; end,
	get__newindex = function(__self, i)return __self.__struct.__newindex[i]; end,
	get__virtual = function(__self, i)return __self.__struct.__virtual[i]; end,
	iterate__ = function(__self)return pairs(__self.__struct.__); end,
	iterate__type = function(__self)return pairs(__self.__struct.__type); end,
	iterate__index = function(__self)return pairs(__self.__struct.__index); end,
	iterate__newindex = function(__self)return pairs(__self.__struct.__newindex); end,
	iterate__virtual = function(__self)return pairs(__self.__struct.__virtual); end,
	get__indicies = function(__self)
		local tb = {};
		for i,v in __self:iterate__() do
			table.insert(table, i);
		end
		return tb;
	end,
	
	find__virtual__super = function(__self, i)
		local __super
		local __super__self = __self;
		while (true) do
			__super = __super__self.__super;
			__super__self = __super__self:__super__self();
			if (__super == nil) then break; end
			if (__super__self) then    if (__super__self:has__(i)) then return __super; end continue;    end
			if (__super) then    return pcall(function() return __super[i]; end) and __super or nil;    end
		end
	end,
	
	find__super__call = function(__self, i)
		if (__self:__super__self()) then return __self:__super__self():find__call(i); end
		if (__self.__super) then
			local v = __self.__super[i];
			return type(v) == "function" and v or nil;
		end
	end,
	
	find__call = function(__self, i) -- [__:(any),  __type:nil,   __index:nil,  __newindex:nil]
		local __struct = __self.__struct;
		if (__struct.__type[i] ~= nil) then return; end
		if (__struct.__index[i] ~= nil) then return; end
		if (__struct.__newindex[i] ~= nil) then return; end
		if (type(__struct.__[i]) == "function") then return __struct.__[i]; end
	end,
	find__index_meta = function(__self, i) -- [__:nil,  __type:nil,   __index:(any)]
		local __struct = __self.__struct;
		if (__struct.__[i] ~= nil) then return; end
		if (__struct.__type[i] ~= nil) then return; end
		local __index = __struct.__index[i];
		if (__index == false or __index == nil) then return; end
		return __index;
	end,
	find__newindex_meta = function(__self, i) -- [__:nil,  __type:nil,   __newindex:(any)]
		local __struct = __self.__struct;
		if (__struct.__[i] ~= nil) then return; end
		if (__struct.__type[i] ~= nil) then return; end
		local __newindex = __struct.__newindex[i];
		if (__newindex == false or __newindex == nil) then return; end
		return __newindex;
	end
};

local PUBLIC__self = {};
PUBLIC__self.__index = PUBLIC;

function PUBLIC__self.new()
	local __self;
	__self = setmetatable({
		__self = nil,
		__class = nil,
		__struct = nil,
		
		__virtual = nil, -- Virtual connector (Connects all virtual properties)
		__changed = RBXMaid.new{},  -- Specific property changed connectors (_RBXScriptSignal)
		__bin = RBXMaid.new{},			-- Instances
		cxn = RBXMaid.new{},			-- RBXScriptConnection & _RBXScriptSignal
	}, PUBLIC__self);
	return __self;
end

return PUBLIC__self;
