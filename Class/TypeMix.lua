--!nocheck
local typeof = function(a)
	local meta = getmetatable(a);
	if type(meta) ~= "table" or meta.__type == nil then return typeof(a); end
	if type(meta.__type) == "function" then return meta.__type(a); end
	return meta.__type;
end

local DECODE = {
	[Axes] = "Axes", [BrickColor] = "BrickColor", [CatalogSearchParams] = "CatalogSearchParams",
	[CFrame] = "CFrame", [Color3] = "Color3", [ColorSequence] = "ColorSequence",
	[ColorSequenceKeypoint] = "ColorSequenceKeypoint", [DateTime] = "DateTime",
	[DockWidgetPluginGuiInfo] = "DockWidgetPluginGuiInfo", [Enum] = "Enum", [Faces] = "Faces",
	[NumberRange] = "NumberRange", [NumberSequence] = "NumberSequence", [NumberSequenceKeypoint] = "NumberSequenceKeypoint",
	[PathWaypoint] = "PathWaypoint", [PhysicalProperties] = "PhysicalProperties", [Random] = "Random",
	[Ray] = "Ray", [Instance] = "Instance", [RaycastParams] = "RaycastParams", [Rect] = "Rect",
	[Region3] = "Region3", [Region3int16] = "Region3int16", [string] = "string", [table] = "table",
	[TweenInfo] = "TweenInfo", [UDim] = "UDim", [UDim2] = "UDim2", [Vector2] = "Vector2",
	[Vector2int16] = "Vector2int16", [Vector3] = "Vector3", [Vector3int16] = "Vector3int16"
}
local CONVERT = {
	["nil"] = function()return "nil"; end,
	["number"] = function()return "number"; end,
	["userdata"] = function(v) return typeof(v) end,
	["table"] = function(v) if (DECODE[v]) then return DECODE[v]; end end
}
local function EncodeType(v) -- Encodes the type into a  table, function, or string
	local fx = CONVERT[type(v)];
	if (fx) then return fx(v) or v; end
	return v;
end

local Enum__eq = function(a, b) -- Checks two values if enum are equal
	if (rawequal(a, b)) then return true; end
	local typea = typeof(a);
	local typeb = typeof(b);

	if (typea == "Enum" and typeb == "EnumItem") then
		return b.EnumType == a;
	end
	if (typea == "EnumItem" and typeb == "Enum") then
		return a.EnumType == b;
	end
end

local PUBLIC = {
	Include = function(self, v)
		rawset(self, EncodeType(v), true);
	end,
	IncludeTuple = function(self, table:{})
		local ni = 1;
		while (true) do
			local v = table[ni];
			if (v == nil and ni > 1 and table[ni-1] == nil) then break; end -- If nil for 2 indicies, then break the loop
			self:Include(v);
			ni += 1;
		end
	end,
	Exclude = function(self, __type)
		rawset(self, __type, nil);
	end,
	Iterate = function(self)
		return pairs(self);
	end,
	Clear = function(self)
		table.clear(self);
	end,
	VerifyType = function(self, v)
		if (rawget(self, typeof(v))) then return true; end
		for __type in pairs(self) do
			if (v == __type) then return true; end			 -- If object is equal
			if (__type == v) then return true; end			 -- if object is equal    (Using both for __eq(a,b) metamathod)
			if (Enum__eq(__type, v)) then return true; end
		end
		return false;
	end,
	Verify = function(self, v:any) -- Verifies the inserted value         
		if (not self:VerifyType(v)) then return false; end
		local has_func = false;
		for __type in pairs(self) do
			if (type(__type) == "function") then
				has_func = true;
				if (__type(v)) then return true; end
			end
		end
		if (not has_func) then return true; end
		return false;
	end,
	Copy = function(self) -- Formats the property type, with each property/class seperated by a "/"
		local table:{}, ni = {}, 1;
		for v in pairs(self) do
			table[ni],ni = tostring(v), ni+1;
		end
		return table;
	end,
	Concat = function(self, sep:'', none:''|nil) -- Converts all contents into a readable string, each type is sepereated by 'sep'
		local tb = self:Copy();
		if (#tb == 0) then	return none or sep; end
		return table.concat(tb, sep);
	end
};


local TypeMix = {
	__index = PUBLIC,
	__newindex = function()end,
	__eq = function(a, b)
		if (rawequal(a, b)) then return true; end
		for __type in pairs(a) do
			if (b:Has(__type) == false) then return false; end
		end
		for __type in pairs(b) do
			if (a:Has(__type) == false) then return false; end
		end
		return true;
	end,
	__tostring = function(self)        return getmetatable(self).__type .. "{" .. self:Concat("/") .."}";        end,
	__metatable = table.freeze({__type = "TypeMix"})
};

function TypeMix.new(table:{})
	local self = setmetatable({}, TypeMix);
	if (table) then self:IncludeTuple(table); end
	return self;
end
return TypeMix;
