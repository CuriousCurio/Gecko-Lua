local typeof = function(a)
	local meta = getmetatable(a);
	if type(meta) ~= "table" or meta.__type == nil then return typeof(a); end
	if type(meta.__type) == "function" then return meta.__type(a); end
	return meta.__type;
end

local Struct = require(script.Parent.Parent.Struct.Struct);

local PUBLIC__self = require(script.Parent.PUBLIC__self.PUBLIC__self);
local PUBLIC__struct = Struct.new(require(script.Parent.PUBLIC__struct));


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
	PUBLIC__struct.__.__init(self);

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
