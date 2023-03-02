--!nocheck
local ClassInstance = require(script.Parent.ClassInstance.ClassInstance);
local RBXScriptSignal = require(script.Parent.RBXScriptSignal.RBXScriptSignal);


local __index;
local Class = {
	__index = function(self, i) -- [self, PUBLIC, __struct]
		local v = __index[i];
		if (v ~= nil) then return v; end
		local v = self.__struct[i];
		if (v ~= nil) then return v; end -- For Struct methods, and library properties

		return self.__struct.__[i]; -- For values like ClassName and raw properties
	end,
	__newindex = function() end,
	__call = ClassInstance.new,
	__eq = ClassInstance.__eq,
	__tostring = function(self)
		 return getmetatable(self).__type .. self.ClassName and "[ "..self.ClassName.." ]" or '';
	end,
	__metatable = table.freeze({__type = "Class"})
};



__index = {
	Search = function(self, obj:Instance) -- Gets the ClassInstance of a Instance, if part of this class
		local instances:{} = self.Instances;
		local find:nil|Instance = instances[obj];
		if (find) then return find; end
		for inst:Instance in self:Iterate() do
			if (typeof(inst:__superroot()) == "Instance" and inst:__superroot() == obj) then return inst; end -- If root is an [Instance], and the root equals the parameter [Instance] given
		end
	end,
	Iterate = function(self)
		return pairs(self.Instances);
	end,
	Destroy = function(self) -- Destroys all of the Instances in a class
		local __private_instances:{},ni = {},1;
		for obj in pairs(self.Instances) do -- Copying Instances
			__private_instances[ni], ni = obj.__private, ni+1;
		end
		for connection in pairs(self.Removing) do
			pcall(connection);
		end
		for _,__private in ipairs(__private_instances) do		-- Disconnecting Connections First (Preventing :Destroy from erroring)
			__private:disconnect();
		end
		task.wait(0.5)
		for _,__private in ipairs(__private_instances) do		-- Destroying Objects Last
			__private:destroy();
		end
		table.clear(self);

		Class.Classes[self] = nil;
	end
};


Class.Classes = {};
Class.Struct = ClassInstance.Struct;
Class.ClassInstance = ClassInstance;

Class.EMPTY = table.freeze({__type = false, __newindex = false});

function Class:Search(obj)
	for class in pairs(self.Classes) do
		local class_obj = class:Search(obj);
		if (class_obj) then return class_obj; end
	end
end
function Class:Find(classname)
	for class in pairs(self.Classes) do
		if (class.__.ClassName == classname) then return class; end
	end
end

function Class.new(table:{})
	local self = setmetatable({
		Instances = {},
		Added = RBXScriptSignal.new(),			-- An instance is added
		Removing = RBXScriptSignal.new(),		-- An instance is being removed
		Destroying = RBXScriptSignal.new(),		-- This Class is being destroyed

		__struct = Class.Struct.new(table)
	}, Class);

	local __static = self.__struct:get__('__static');
	if (__static) then __static(self); self.__struct:set__('__static', nil); end

	Class.Classes[self] = true;

	return self;
end
return Class;
