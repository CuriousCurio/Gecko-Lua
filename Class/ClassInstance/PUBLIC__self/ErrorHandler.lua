-- This module creates a smart index error, when a property is missing it will give detailed information about it
local typeof = function(a)
	local meta = getmetatable(a);
	if type(meta) ~= "table" or meta.__type == nil then return typeof(a); end
	if type(meta.__type) == "function" then return meta.__type(a); end
	return meta.__type;
end


local module = {};
function module:Index(obj, i)
	local __:{};
	local __type = typeof(obj);
	local __tostring = tostring(obj);
	if (__type == "Instance") then __ = {};
	elseif (__type == "ClassInstance") then __ = obj.__self:pull({});
	elseif (__type == "table") then __ = {}; end

	local str = "" do
		--  Capitalization  --
		for k in pairs(__) do
			if (type(k) ~= "string") then continue; end
			if (k:lower() == i:lower()) then
				str = " due to capitals; use \"".. k .."\"";
				break;
			end
		end

		--  Suggestions  --
		local sugg = {};
		local str = i:sub(1,1):upper()..i:sub(2);
		for k in pairs(__) do
			if (type(k) ~= "string") then continue; end

			k:gsub("[A-Z][a-z0-9]*", function(ki) -- Matches words that begin with a capital letter
				if (ki == 1) then return; end
				if (k:lower():match(ki:lower())) then sugg[k] = true; end
				return "";
			end):gsub("[a-zA-Z0-9]", function(strx) -- Matches other words
				if (strx == 1) then return; end
				if (str:lower():match(strx:lower())) then sugg[k] = true; end
			end);
		end

		local ni = 1;
		for i,v in pairs(sugg) do
			sugg[ni],ni = i, ni+1;
			sugg[i] = nil;
		end
		if (#sugg > 0) then str = str .. ", did you mean " .. table.concat(sugg, ", ") .. "?"; end
	end
	return string.format("\"%s\" is not a valid member of %s%s", i, __tostring, str or ''), 2;
end
return module;
