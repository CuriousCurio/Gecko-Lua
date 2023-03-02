-- This module returns a __private library for the ClassInstance type
local ErrorHandler = require(script.Parent.ErrorHandler);
local TypeCaster = require(script.Parent.TypeCaster);
local VirtualConnector = require(script.Parent.VirtualConnector);
local RBXMaid = require(script.Parent.Parent.Parent.RBXMaid);
local Struct = require(script.Parent.Parent.Parent.Struct.Struct);

local typeof = function(a)
	local meta = getmetatable(a);
	if type(meta) ~= "table" or meta.__type == nil then return typeof(a); end
	if type(meta.__type) == "function" then return meta.__type(a); end
	return meta.__type;
end
local pcall = function(a, ...)
	local s,e = pcall(a, ...);
	if (s == true) then return s,e; end
	return s,e:match(".+\.[a-zA-Z]+:[0-9]*:(.+)") or e; -- Removes existing script reference  "Class.ClassInstance.__private:171:"
end


local __private = {};
function __private.new(__class, __public)
	local self;
	self = setmetatable({
		__class = __class,
		__public = __public,
		__struct = Struct.new(),
		
		__virtual = nil, -- Virtual connector (Connects all virtual properties)
		__changed = RBXMaid.new(),  -- Specific property changed connectors (_RBXScriptSignal)
		__bin = RBXMaid.new(),			-- Instances
		__cxn = RBXMaid.new(),			-- RBXScriptConnection & _RBXScriptSignal
	}, __private);
	return self;
end
__private.Struct = Struct;

__private.__index = {
	__superroot = function(self) -- Gets the deepsest __subroot value (can be Instance/ClassInstance)
		local __super__private = self:__super__private();
		if (__super__private) then return __super__private:__superroot(); end
		return rawget(self, "__super");
	end,
	__super__private = function(self)
		local __super = rawget(self, "__super");
		if (type(__super) == "table") then return __super.__private; end
	end,
	__superroot__private = function(self)
		local __superroot = self:__superroot();
		if (__superroot) then return __superroot.__private; end
	end,
	__subroot = function(self) -- Gets the deepsest __sub value
		local __sub = rawget(self, "__sub");
		if (__sub == nil) then return; end
		return __sub.__private:__subroot() or __sub
	end,
	__sub__private = function(self)
		local __sub = rawget(self, "__sub");
		if (__sub) then return __sub.__private; end
	end,
	__subroot__private = function(self)
		local __subroot__private = self:__subroot();
		if (__subroot__private) then return __subroot__private.__public; end
	end,
	
	push_class = function(self, class, ...)
		self.__struct:Insert(class.__struct);
		local __init = class.__struct:get__("__init");
		if (__init) then __init(self.__public, ...) end; -- Firing __init__ (constructor) found in class
	end,

	push = function(self, table) -- :set() on all given properties
		if (table == nil) then return; end
		if (type(table) ~= "table") then error(string.format("invalid argument #%i to \"%s\" (%s expected, got %s)", 1, "apply", "table/nil", typeof(table))) end
		
		for i,v in pairs(table) do
			if (i == "Parent") then continue; end
			self:set(i, v);
		end
		
		local parent = table.Parent;
		if (parent) then -- Setting Parent last
			if (typeof(parent) == "ClassInstance") then parent = parent:__superroot(); end
			self:set("Parent", parent);
		end
	end,
	rawpush = function(self, table) -- :rawset() on this instance
		if (table == nil) then return; end
		if (type(table) ~= "table") then error(string.format("invalid argument #%i to \"%s\" (%s expected, got %s)", 1, "rawapply", "table/nil", typeof(table))) end
		for i,v in pairs(table) do
			if (i == "Parent") then continue; end
			self:rawset(i, v);
		end
		
		local parent = table.Parent;
		if (parent) then -- Setting Parent last
			if (typeof(parent) == "ClassInstance") then parent = parent:__superroot(); end
			self:rawset("Parent", parent);
		end
	end,
	pull = function(self, table) -- unpacks all properties and subclass properties into a table that can be applied to the same class
		table = table or {};
		for i,v in self:iterate__() do
			if (table[i] == nil) then table[i] = v; end
		end
		if (self:__super__private()) then self:__super__private():pull(table); end
		return table;
	end,
	update_all = function(self)
		local class = self.__class;
		local __init__newindex_order = class.__init__newindex_order;
		local __init__newindex_ignore = class.__init__newindex_ignore;
		
		--  Updating Queue, and Class Properties  --
		if (__init__newindex_order) then
			for _,i in ipairs(__init__newindex_order) do
				self:update(i);
			end
		end
		
		--  Updating __newindex  --
		for i,v in self:iterate__newindex() do
			if (__init__newindex_ignore and table.find(__init__newindex_ignore, i)) then continue; end
			if (__init__newindex_order and table.find(__init__newindex_order, i)) then continue; end
			if (v) then self:update(i); end
		end
		
		--  Updating __virtual  --
		for i,v in self:iterate__virtual() do
			if (__init__newindex_ignore and table.find(__init__newindex_ignore, i)) then continue; end
			if (__init__newindex_order and table.find(__init__newindex_order, i)) then continue; end
			self:update(i);
		end
	end,
	update = function(self, i, fire:nil|true|false) -- Updates a setter
		local __newindex = self:get__newindex(i);
		if (__newindex == false) then error(string.format("\"%s\" has a locked __newindex.", i)); end
		if (__newindex == nil) then -- If not found then update an existing __virtual
			local __virtual = self:get__virtual(i);
			if (__virtual) then __virtual(self.__public, i, self:get(i)); end
			return;
		end
		
		local v = self:get(i);
		__newindex(self.__public, i, v);
		if (not self:has__(i)) then return; end -- If this property has been removed during __newindex, return
		if (fire == true or (fire == nil and v ~= self:get__(i))) then self:fire(i); end -- true (fire)		false (don"t fire)			nil (fire if changed)
	end,
	fire = function(self, i) -- Fires all changed events of an index
		local v = self:get(i);
		for cx in pairs(self:rawget("Changed")) do
			task.spawn(function()	cx(i, v);	end);
		end
		local __changed = self.__changed[i];
		if (__changed) then
			for cx in pairs(__changed) do	
				task.spawn(function()	cx(v);	end);
			end
		end
	end,
	
	
	
	set = function(self, i, v,    _ref_:nil) -- Sets a value from this specific Instance using a setter
		local __newindex_meta = self:find__newindex_meta(i); -- Basic __newindex Setter
		if (__newindex_meta) then return __newindex_meta(self.__public, i, v); end
		-----------------------------
		if (not self:has__(i)) then
			if (not self.__super) then error(ErrorHandler:Index((_ref_ or self).__private, i)); end -- Error if unavailable
			if (_ref_ == nil) then assert(pcall(self["set__super"], self, i, v, _ref_ or self)); return; end -- Keep error on top stack if top call
			return self:set__super(i, v, _ref_ or self);
		end
		-----------------------------
		local from = self:get__(i);
		v = TypeCaster:Cast(self:get__type(i), from, v,  i);
		if (from == v) then return; end -- If not a new value, then return
		
		local __newindex = self:get__newindex(i);
		if (__newindex == false) then error(string.format("\"%s\" has a locked __newindex.", i)); end
		if (__newindex == nil) then self:rawset(i, v); self:fire(i); return; end
		__newindex(self.__public, i, v);
		if (self.__public == nil) then return; end -- Returning if the instance has been destroyed
		if (from ~= self:get__(i)) then self:fire(i); end -- Firing if changed
	end,
	get = function(self, i,    _ref_:nil) -- Gets a value from this specific Instance using a getter
		local __index_meta = self:find__index_meta(i); -- Basic __index Getter
		if (__index_meta) then return __index_meta(self.__public, i); end
		-----------------------------
		if (not self:has__(i)) then
			if (not self.__super) then error(ErrorHandler:Index((_ref_ or self).__private, i)); end -- Error if unavailable
			if (_ref_ == nil) then local _,ret = assert(pcall(self["get__super"], self, i, _ref_ or self)); return ret; end -- Keep error on top stack if top call
			return self:get__super(i, _ref_ or self);
		end
		-----------------------------
		local __index = self:get__index(i);
		if (__index == false) then error(string.format("The property \"%s\" is not retreivable.", i)); end
		if (__index == nil) then return self:rawget(i); end -- If no getter, get using default method
		return __index(self.__public, i);
	end,
	rawset = function(self, i, v,    _ref_:nil) -- Sets a property, without calling __newindex or __virtual
		local __newindex_meta = self:find__newindex_meta(i);
		if (__newindex_meta) then __newindex_meta(self.__public, i, v); return; end
		-----------------------------
		if (not self:has__(i)) then
			if (not self.__super) then error(ErrorHandler:Index((_ref_ or self).__private, i));end -- Error if unavailable
			if (_ref_ == nil) then assert(pcall(self["rawset__super"], self, i, v, _ref_ or self)); return; end -- Keep error on top stack if top call
			return self:rawset__super(i, v, _ref_ or self);
		end
		-----------------------------
		v = TypeCaster:Cast(self:get__type(i), self:get__(i), v,    i);
		self:set__(i, v);
	end,
	rawget = function(self, i,    _ref_:nil)  -- Gets a property, without calling __index
		local __index_meta = self:find__index_meta(i);
		if (__index_meta) then return __index_meta(self.__public, i); end
		-----------------------------
		if (not self:has__(i)) then
			if (not self.__super) then local _,ret = error(ErrorHandler:Index((_ref_ or self).__private, i)); return ret; end -- Error if unavailable
			if (_ref_ == nil) then assert(pcall(self["rawget__super"], self, i, _ref_ or self)); end -- Keep error on top stack if top call
			return self:rawget__super(i, _ref_ or self);
		end
		-----------------------------
		return self:get__(i);
	end,
	set__super = function(self, i, v,    _ref_:nil) -- Sets a subclass property
		if (not self:has__super__(i) and self.__super == self:__superroot()) then error(ErrorHandler:Index((_ref_ or self).__private, i)); end
		if (self:__super__private()) then  -- ClassInstance
			if (_ref_ == nil) then assert(pcall(self:__super__private()["set"], self, i, v, _ref_ or self)); end -- Keep error on top stack if top call
			self:__super__private():set(i, v, _ref_ or self);
			return;
		end
		if (self.__super) then self.__super[i] = v; return; end -- Instance
	end,
	get__super = function(self, i,    _ref_:nil) -- Gets a subclass property
		if (not self:has__super__(i) and self.__super == self:__superroot()) then error(ErrorHandler:Index((_ref_ or self).__private, i)); end
		local __call = self:find__super__call(i);
		if (__call) then return function(_, ...)return __call(self.__super, ...); end end
		if (self:__super__private()) then   -- ClassInstance
			if (_ref_ == nil) then local _,ret = assert(pcall(self:__super__private()["get"], self, i, _ref_ or self)); return ret; end -- Keep error on top stack if top call
			return self:__super__private():get(i, _ref_ or self);
		end
		if (self.__super) then return self.__super[i]; end  -- Instance
	end,
	rawset__super = function(self, i, v,    _ref_:nil) -- Sets a subclass property without calling a virtual
		if (not self:has__super__(i) and self.__super == self:__superroot()) then error(ErrorHandler:Index((_ref_ or self).__private, i)); end
		if (self:__super__private()) then  -- ClassInstance
			if (_ref_ == nil) then assert(pcall(self:__super__private()["rawset"], self, i, v, _ref_ or self)); end -- Keep error on top stack if top call
			self:__super__private():rawset(i, v, _ref_ or self);
			return;
		end
		if (self.__super) then -- Instance
			for __sub__private in self:iterate__sub__private() do
				local __virtual__cxn = __sub__private.__virtual__cxn;
				if (__virtual__cxn == nil) then continue; end
				__virtual__cxn:Lock(i);
			end
			self.__super[i] = v;
			task.delay(0.01, function()
				for __sub__private in self:iterate__sub__private() do
					local __virtual__cxn = __sub__private.__virtual__cxn;
					if (__virtual__cxn == nil) then continue; end
					__virtual__cxn:Unlock(i);
				end
			end);
		end
	end,
	rawget__super = function(self, i,    _ref_:nil) -- Gets a subclass property, if a method, then create a returnable method function
		if (not self:has__super__(i) and self.__super == self:__superroot()) then error(ErrorHandler:Index((_ref_ or self).__private, i)); end
		local __call = self:find__super__call(i);
		if (__call) then return function(_, ...) return __call(self.__super, ...); end end
		if (self:__super__private()) then -- ClassInstance
			if (_ref_ == nil) then local _,ret = assert(pcall(self:__super__private()["rawget"], self, i, _ref_ or self)); return ret; end -- Keep error on top stack if top call
			return self:__super__private():rawget(i, _ref_ or self);
		end
		if (self.__super) then return self.__super[i]; end -- Instance
	end,
	
	isa = function(self, i)
		if (self.__class == i) then return true; end
		if (self.__class.ClassName == i) then return true; end
		if (self:__super__private()) then return self:__super__private():isa(i); end
		if (self.__super) then return self.__super.ClassName == i; end
		return false;
	end,
	
	disconnect = function(self) -- Disconnects this __private class
		self.cxn:Disconnect(); -- Disconnects all RBXScriptSignals RBXScriptConnections in this ClassInstance
		self.__changed:Disconnect();
		if (self.__virtual__cxn) then self.__virtual__cxn:Disconnect(); end
	end,
	destroy = function(self) -- Destroys this __private class
		if (self.destroying) then return; end
		self.destroying = true;
		
		local __instance = self.__public;
		local __destroying:nil|(any) = self.__class.__destroying; -- Calls the OnDestroy tag with the Instance as the first variable before anything else
		if (__destroying) then __destroying(__instance); end
		
		for cx in pairs(self:get__("Destroying")) do -- Calling attached destroying connectors
			local s,e = pcall(cx);
			if (s == false) then warn(e .. "\n" .. debug.traceback()); end
		end
		
		self:disconnect();
		self.__class.Instances[__instance] = nil;
		
		local __super:nil|Instance = self.__super;
		if (__super) then  pcall(function()__super:Destroy();end);  end
		
		self.__bin:Destroy();	-- Destroying protected bin and inheritance
		table.clear(self);
		rawset(__instance, '__private', nil);
	end,
	mount__super = function(self, __super) -- Sets the superclass of an Instance
		local is_Instance = typeof(__super) == "Instance";
		local is_ClassInstance = not is_Instance and typeof(__super) == "ClassInstance";
		if (__super ~= nil and not is_Instance and not is_ClassInstance) then error(string.format("invalid argument #%i to \"%s\" (%s expected, got %s)", 1, "mount__super", "_Instance/Instance", typeof(__super))); end
		
		-- Removing old subclass from superclass --
		if (self:__super__private()) then self:__super__private().__sub = nil; end
		
		-- Getting new __super__private --
		local __super__private = (is_ClassInstance and __super.__private) or nil;
		if (__super__private) then __super__private.__sub = self.__public; end -- Setting [__sub and __sub__private] inside __super__private
		self.__super = __super;
		
		-- Destroying
		local __destroy__ = self.cxn.__destroy__;
		if (__destroy__) then __destroy__:Disconnect(); self.cxn.__destroy__ = nil; end -- Disconnecting base_destroy connection if possible
		if (__super) then self.cxn.__destroy__ = __super.Destroying:Connect(function() self:destroy(); end); end -- When subclass is destroying, destroy this Instance
		
		-- Refreshing Virtual Subclass Connectors --
		self:update__virtual();
		for __sub__private in self:iterate__sub__private() do
			__sub__private.__private:update__virtual();
		end
	end,
	
	iterate__sub = function(self)
		local __sub;
		return function() __sub = (__sub or self).__sub; return __sub; end;
	end,
	iterate__sub__private = function(self)
		local __sub__private;
		return function() __sub__private = (__sub__private or self):__sub__private(); return __sub__private; end;
	end,
	iterate__super = function(self)
		local __super;
		return function() __super = (__super or self).__super; return __super; end;
	end,
	iterate__super__private = function(self)
		local __super__private;
		return function() __super__private = (__super__private or self):__super__private(); return __super__private; end;
	end,
	
	
	
	sort = function(self, ...)return self.__struct:sort(...); end,
	remove = function(self, i) -- Removes a property that was created
		self.__struct:remove(i);
		local __changed = self.__changed[i];
		if (__changed) then __changed:Disconnect() self.__changed[i] = nil; end
		self.__virtual__cxn:Disconnect(i);
	end,
	has = function(self, i) -- Checks if a property exists in every superclass
		if (self:has__(i)) then return true; end
		if (self:__super__private()) then return self:__super__private():has(i); end
		if (self.__super and self:has__super__(i)) then return true; end
		return false;
	end,
	has__ = function(self, ...)return self.__struct:has__(...); end,
	has__super__ = function(self, i) -- Checks if a property exists in this ClassInstance's superclass
		if (self:__super__private()) then return self:__super__private():has__(i); end
		if (self.__super) then return pcall(function() return self.__super[i]; end), nil; end 
		return false;
	end,
	set__ = function(self, i, v) self.__struct.__[i] = v; end,
	set__type = function(self, i, v) self.__struct:set__type(i, v); end,
	set__index = function(self, i, v) self.__struct:set__index(i, v); end,
	set__newindex = function(self, i, v) self.__struct:set__newindex(i, v); end,
	
	refresh__virtual = function(self)
		local empty = next(self.__struct.__virtual) == nil;
		if (empty and self.__virtual__cxn) then -- No virtual values
			self.__virtual__cxn = nil;
		elseif (not empty and self.__virtual__cxn == nil) then
			self.__virtual__cxn = VirtualConnector.new(function(_, i, instance) -- All __virtual attributes connect to __super using a property connector
				if (self:get__("__init")) then return; end
				local __virtual = self:get__virtual(i);
				if (__virtual) then __virtual(self.__public, i, instance[i]); end
			end);
		end
	end,
	-- TODO Connect Virtual Functions Seperatly
	update__virtual = function(self)
		local __virtual__cxn = self.__virtual__cxn;
		if (__virtual__cxn) then
			for i,v in self:iterate__virtual() do
				if (__virtual__cxn.cxn[i] == nil) then
					local __super = self:find__virtual__super(i);
					if (__super == nil) then error("Virtual property '".. i .."' not found in any superclass"); end
					__virtual__cxn:Connect(i, self:find__virtual__super(i));
				end
			end
		end
	end,
	set__virtual = function(self, i, v)
		self.__struct:set__virtual(i, v);
		if (self.__virtual__cxn) then
			if (v) then
				self.__virtual__cxn:Connect(i);
			else
				self.__virtual__cxn:Disconnect(i);
			end
		end
	end,
	get__ = function(self, i)return self.__struct.__[i]; end,
	get__type = function(self, i)return self.__struct.__type[i]; end,
	get__index = function(self, i)return self.__struct.__index[i]; end,
	get__newindex = function(self, i)return self.__struct.__newindex[i]; end,
	get__virtual = function(self, i)return self.__struct.__virtual[i]; end,
	iterate__ = function(self)return pairs(self.__struct.__); end,
	iterate__type = function(self)return pairs(self.__struct.__type); end,
	iterate__index = function(self)return pairs(self.__struct.__index); end,
	iterate__newindex = function(self)return pairs(self.__struct.__newindex); end,
	iterate__virtual = function(self)return pairs(self.__struct.__virtual); end,
	get__indicies = function(self)
		local tb = {};
		for i,v in self:iterate__() do
			table.insert(table, i);
		end
		return tb;
	end,
	
	find__virtual__super = function(self, i)
		local __super
		local __super__private = self;
		while (true) do
			__super = __super__private.__super;
			__super__private = __super__private:__super__private();
			if (__super == nil) then break; end
			if (__super__private) then    if (__super__private:has__(i)) then return __super; end continue;    end
			if (__super) then    return pcall(function() return __super[i]; end) and __super or nil;    end
		end
	end,
	
	find__super__call = function(self, i)
		if (self:__super__private()) then return self:__super__private():find__call(i); end
		if (self.__super) then
			local v = self.__super[i];
			return type(v) == "function" and v or nil;
		end
	end,
	
	find__call = function(self, i) -- [__:(any),  __type:nil,   __index:nil,  __newindex:nil]
		local __struct = self.__struct;
		if (__struct.__type[i] ~= nil) then return; end
		if (__struct.__index[i] ~= nil) then return; end
		if (__struct.__newindex[i] ~= nil) then return; end
		if (type(__struct.__[i]) == "function") then return __struct.__[i]; end
	end,
	find__index_meta = function(self, i) -- [__:nil,  __type:nil,   __index:(any)]
		local __struct = self.__struct;
		if (__struct.__[i] ~= nil) then return; end
		if (__struct.__type[i] ~= nil) then return; end
		local __index = __struct.__index[i];
		if (__index == false or __index == nil) then return; end
		return __index;
	end,
	find__newindex_meta = function(self, i) -- [__:nil,  __type:nil,   __newindex:(any)]
		local __struct = self.__struct;
		if (__struct.__[i] ~= nil) then return; end
		if (__struct.__type[i] ~= nil) then return; end
		local __newindex = __struct.__newindex[i];
		if (__newindex == false or __newindex == nil) then return; end
		return __newindex;
	end
};

return __private;
