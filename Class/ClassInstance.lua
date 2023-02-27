local typeof = function(a)
	local meta = getmetatable(a);
	if type(meta) ~= "table" or meta.__type == nil then return typeof(a); end
	if type(meta.__type) == "function" then return meta.__type(a); end
	return meta.__type;
end

local Struct = require(script.Parent.Parent.Struct);
local RBXMaid = require(script.RBXMaid);
local RBXScriptSignal = require(script.RBXScriptSignal);

local PUBLIC__self = require(script.PUBLIC__self);
local PUBLIC__struct = Struct.new({
	__ = {
		GetPropertyChangedSignal = function(self, i)
			local __self = self.__self;
			local __changed = __self.__changed;

			if (not __self:has__(i)) then
				local __super = __self.__super;
				if (__super == nil) then error(i.." is not a valid property"); end
				return __super:GetPropertyChangedSignal(i);
			end

			local signal = __changed[i]; -- Setting __changed to a table if nil
			if (signal == nil) then
				signal = RBXScriptSignal.new(); -- Getting RBXScriptSignal from Struct
				__changed[i] = signal;
			end

			return signal;

		end,
		IsA = function(self, i) -- Checks if this instance has the same classname or the same class in it"s inherited descendants
			return self.__self:isa(i);
		end,
		Destroy = function(self)
			self.__self:destroy(); -- Destroying the private class
		end
	},
	__index = {
		__class = function(self, i)return self.__self[i]; end,
		__struct = function(self, i)return self.__self[i]; end,

		__super = function(self, i)return self.__self[i]; end,
		__sub = function(self, i)return self.__self[i]; end,
		ClassName = function(self, i) return self.__self.__class.ClassName; end,
	},
});


local ClassInstance = {
	__index = function(self, i)
		local __self = self.__self;
		local f = getmetatable(__self).__index[i];
		if (f) then return function(_, ...) return f(__self, ...); end; end

		return __self:get(i);
	end,
	__newindex = function(self, i, v)
		local __self = self.__self;
		return __self:set(i, v);
	end,
	__eq = function(a, b)
		if (typeof(a) ~= "ClassInstance") then return rawequal(a, b); end
		return (typeof(b) == "Class" and a:IsA(b)) or rawequal(a, b);  -- If the instance is equal to it"s class
	end,
	__tostring = function(self)
		local __self = self.__self;
		local __tostring = __self:get__("__tostring");
		if (__tostring) then return __tostring(self); end
		return self.ClassName or getmetatable(self).__type;
	end,
	__metatable = table.freeze({__type = "ClassInstance"})
};


ClassInstance.RBXMaid = RBXMaid;
ClassInstance.RBXScriptSignal = RBXScriptSignal;
ClassInstance.Struct = Struct;
ClassInstance.PUBLIC__self = PUBLIC__self;
function ClassInstance.new(class, ...)
	local self = setmetatable({   __self = PUBLIC__self.new()   }, ClassInstance);
	local __self = self.__self;
	rawset(__self, "__self", self);
	rawset(__self, "__class", class);
	rawset(__self, "__struct", Struct.new());


	-- Inserting Initial Libraries --
	__self.__struct:Insert(PUBLIC__struct);
	__self.__struct:Insert(class.__struct);

	__self:set__("Destroying", RBXScriptSignal.new());	__self.cxn._Destroying = self.Destroying;
	__self:set__("Changed", RBXScriptSignal.new());		__self.cxn._Changed = self.Changed;

	__self:refresh__virtual();
	local __init = __self:get__("__init");
	if (__init) then __init(self, ...); end

	local __init__newindex_auto = class.__init__newindex_auto;
	if (__init__newindex_auto == nil or __init__newindex_auto == true) then __self:update_all(); end
	__self:set__('__init', nil);
	__self:set__('__init__newindex_auto', nil);

	-- Class Matience --
	class.Instances[self] = true;
	class.Added(self);

	return self;
end
return ClassInstance;
