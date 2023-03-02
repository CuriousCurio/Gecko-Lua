local typeof = function(a)
	local meta = getmetatable(a);
	if type(meta) ~= "table" or meta.__type == nil then return typeof(a); end
	if type(meta.__type) == "function" then return meta.__type(a); end
	return meta.__type;
end

local P__private = require(script.Parent.__private.__private);
local Struct = P__private.Struct;

local P__struct = Struct.new(require(script.Parent.__struct));


local ClassInstance = {
	__index = function(self, i)
		local __private = self.__private;
		local f = getmetatable(__private).__index[i];
		if (f) then return function(_, ...) return f(__private, ...); end; end

		return __private:get(i);
	end,
	__newindex = function(self, i, v)
		local __private = self.__private;
		return __private:set(i, v);
	end,
	__eq = function(a, b)
		if (typeof(a) ~= "ClassInstance") then return rawequal(a, b); end
		return (typeof(b) == "Class" and a:IsA(b)) or rawequal(a, b);  -- If the instance is equal to it"s class
	end,
	__tostring = function(self)
		local __private = self.__private;
		local __tostring = __private:get__("__tostring");
		if (__tostring) then return __tostring(self); end
		return self.ClassName or getmetatable(self).__type;
	end,
	__metatable = table.freeze({__type = "ClassInstance"})
};


ClassInstance.Struct = Struct;
function ClassInstance.new(class, ...)
	local self = setmetatable({}, ClassInstance);
	local __private = P__private.new(class, self);
	rawset(self, "__private", __private);

	-- Inserting Initial Libraries --
	__private.__struct:Insert(P__struct);
	__private.__struct:Insert(class.__struct);
	P__struct.__.__init(self);

	__private:refresh__virtual();
	local __init = __private:get__("__init");
	if (__init) then __init(self, ...); end

	local __init__newindex_auto = class.__init__newindex_auto;
	if (__init__newindex_auto == nil or __init__newindex_auto == true) then __private:update_all(); end
	__private:set__('__init', nil);
	__private:set__('__init__newindex_auto', nil);

	-- Class Matience --
	class.Instances[self] = true;
	class.Added(self);

	return self;
end
return ClassInstance;
