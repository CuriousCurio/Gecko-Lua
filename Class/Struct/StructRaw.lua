local function GetExistingPropertyIndicies(self, tb) -- Finds all property indicies in the table given
	local properties = {};
	 -- Getting properties thrown in the root table --
	for i,v:any in pairs(tb) do
		if (rawget(self, i) ~= nil) then continue; end -- Don't iterate through property table

		for tag in pairs(self) do -- Removing profix
			if (i:sub(-#tag) == tag) then i = i:sub(0,-#tag-1); break; end -- Checking if the profix ending was equal to the stored profix ending in "StructRaw_profix"
		end
		properties[i] = true;
	end

	-- Getting properties in property tables --
	for att_i in pairs(self) do
		local att_v:{} = tb[att_i];
		if (att_v) then
			for i in pairs(att_v) do
				properties[i] = true;
			end
		end
	end

	local sorted = {};
	for i in pairs(properties) do
		table.insert(sorted, i);
	end
	return sorted;
end

local PUBLIC = {
	Insert = function(self, StructRaw) -- Inserts all values into this struct
		for att_i,att_v:{} in pairs(StructRaw) do
			local this_att_tb:{} = rawget(self, att_i);
			if (this_att_tb == nil) then continue; end
			for i,v in pairs(att_v) do
				this_att_tb[i] = v;
			end
		end
	end,
	Get = function(self, i, __:{}|nil) -- Gets attributes of a property (And inserts it into the table if given)
		__ = __ or {};
		for att_i,att_v in pairs(self) do
			for k,v in pairs(att_v) do
				if (i == k) then __[att_i] = v; end
			end
		end
		return __;
	end,
	Set = function(self, i, __:{}) -- Sets attributes of a property (from the table given)
		for prp_i,v in pairs(__) do
			self[prp_i][i] = v;
		end
	end,
	
	IterateSort = function(self, tb) -- Returns a sorting iterator to use for sorting attributes into tables
		local properties, ni = GetExistingPropertyIndicies(self, tb), 1;
		local __ = {}; -- attributes for each property found in "tb" and this StructRaw

		return function()
			table.clear(__);
			local i = properties[ni];
			ni = ni + 1;
			if (i == nil) then return; end

			-- # = Priority --

			-- #3 --
			for att_i in pairs(self) do
				__[att_i] = tb[i..att_i:gsub("^__$", "")];
			end

			-- #2 --
			local __attributes:{} = tb[i.."__"];
			if (__attributes) then
				for att_i in pairs(self) do
					if (__[att_i] == nil and __attributes[att_i] ~= nil) then
						__[att_i] = __attributes[att_i];
					end
				end
			end

			-- #1 --
			for att_i in pairs(self) do
				if (__[att_i] == nil and tb[att_i] ~= nil) then
					__[att_i] = tb[att_i][i];
				end
			end

			return i,__;
		end
	end
};

local StructRaw = {
	__index = PUBLIC,
	__metatable = table.freeze({__type = "StructRaw"})
};


function StructRaw.new()
	local self = setmetatable({
		__ = {} -- Default Properties
	}, StructRaw);
	return self;
end
return StructRaw;
