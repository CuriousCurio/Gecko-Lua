local StructRaw = require(script.Parent.StructRaw);
local TypeMix = require(script.Parent.Parent.TypeMix);
local typeof = function(a)
	local meta = getmetatable(a);
	if type(meta) ~= "table" or meta.__type == nil then return typeof(a); end
	if type(meta.__type) == "function" then return meta.__type(a); end
	return meta.__type;
end



local Struct = {
	__index = {
		sort = function(self, table)  -- Sorts the table into seperate property attribute containers: (__type, __, ...)
			if (table ~= nil and type(table) ~= "table") then error(string.format("invalid argument #%i to \"%s\" (%s expected, got %s)", 1, "Class.new", "table", typeof(table))); end

			for i,__ in self:IterateSort(table) do -- __ = attributes
				for att_i,att_v:{} in pairs(self) do -- Puts library properties into __ if there are voids
					if (__[att_i] ~= nil) then continue; end -- If there's already a value
					__[att_i] = att_v[i];
				end

				self:set__(i, __.__);
				self:set__type(i, __.__type);
				self:set__index(i, __.__index);
				self:set__newindex(i, __.__newindex);
				self:set__virtual(i, __.__virtual);
			end
		end,
		remove = function(self, i) -- Removes a property
			self.__[i] = nil;
			self.__type[i] = nil;
			self.__index[i] = nil;
			self.__newindex[i] = nil;
			self.__virtual[i] = nil;
		end,
		has__ = function(self, i)
			return self.__[i] ~= nil or self.__type[i] ~= nil;
		end,
		set__ = function(self, i, v) self.__[i] = v; end,
		set__type = function(self, i, v)
			if v == nil then
			elseif v == false then
			elseif type(v) == "table" then v = TypeMix.new(v);
			elseif typeof(v) == "TypeMix" then
			else
				error(string.format("For property \"%s\", invalid argument #%i to \"%s\" (%s expected, got %s)", i, 2, "Set__type", "nil/false/TypeMix(or table)", typeof(v)));
			end
			self.__type[i] = v;
		end,
		set__index = function(self, i, v)
			--if (v ~= nil and v ~= false and type(v) ~= "function") then error(string.format("For property \"%s\", invalid argument #%i to \"%s\" (%s expected, got %s)", i, 2, "Set__index", "nil/false/function", typeof(v))); end
			self.__index[i] = v;
		end,
		set__newindex = function(self, i, v)
			--if (v ~= nil and v ~= false and type(v) ~= "function") then error(string.format("For property \"%s\", invalid argument #%i to \"%s\" (%s expected, got %s)", i, 2, "Set__newindex", "nil/false/function", typeof(v))); end
			self.__newindex[i] = v;
		end,
		set__virtual = function(self, i, v)
			--if (v ~= nil and type(v) ~= "function") then error(string.format("For property \"%s\", invalid argument #%i to \"%s\" (%s expected, got %s)", i, 2, "Set__virtual", "nil/function", typeof(v))); end
			self.__virtual[i] = v;
		end,
		get__ = function(self, i)return self.__[i]; end,
		get__type = function(self, i)return self.__type[i]; end,
		get__newindex = function(self, i)return self.__newindex[i]; end,
		get__index = function(self, i)return self.__index[i]; end,
		get__virtual = function(self, i)return self.__virtual[i]; end,
		iterate__ = function(self)return pairs(self.__); end,
		iterate__type = function(self)return pairs(self.__type); end,
		iterate__index = function(self)return pairs(self.__index); end,
		iterate__newindex = function(self)return pairs(self.__newindex); end,
		iterate__virtual = function(self)return pairs(self.__virtual); end
	},
	__metatable = table.freeze({__type = "Struct"})
};
setmetatable(Struct.__index, StructRaw);


Struct.TypeMix = TypeMix;
function Struct.new(table)
	local self = setmetatable({}, Struct);
	self.__ = 			{}; -- Default Properties
	self.__type = 		{}; -- Property types
	self.__index = 		{}; -- Property getters
	self.__newindex = 	{}; -- Property setters;
	self.__virtual = 	{}; -- Virtual Properties


	if (typeof(table) == "Struct") then
		self:Insert(table);
	elseif (typeof(table) == "table") then
		self:sort(table);
	end

	return self;
end
return Struct;
