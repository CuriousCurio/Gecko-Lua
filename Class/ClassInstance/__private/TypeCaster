-- Handles type setter and getter data, based on the __type table of __struct

local typeof = function(a)
	local meta = getmetatable(a);
	if type(meta) ~= "table" or meta.__type == nil then return typeof(a); end
	if type(meta.__type) == "function" then return meta.__type(a); end
	return meta.__type;
end

local function GetInfo(__type, from, to) -- Returns typeof(to), typeof(from)
	local to_str, to_type = tostring(to), typeof(to);
	local st = ( to_str == to_type and to_type ) or (to_str.."["..to_type.."]"); -- If tostring is equal to the type, then only use the type
	if (__type == nil or __type == false) then return st, typeof(from); end -- if __type is nil or false then return the actual type
	return st, __type:Concat("/");
end
local function Verify(__type, from, to) -- Checks if the __type along with old and new properties are valid
	if (__type == false) then return true; end -- Property typing disabled
	if (__type == nil) then 					  -- Native property type (checks the previous value)
		if (typeof(from) ~= typeof(to)) then return false end;
		return true;
	end
	return __type:Verify(to); -- Checking property type value
end

local CastHandler = {};
function CastHandler:Cast(__type, from, to, i) -- TODO: Datatype Casters
	if (Verify(__type, from, to) == false) then error(string.format("for \"%s\", unable to cast (%s -> %s)", i, GetInfo(__type, from, to))); end -- Verifying type - if not valid error   "For .. unable to cast (to -> from)"
	return to;
end
return CastHandler;
