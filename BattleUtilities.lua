local util = {} -- TODO: .jsonEncode; use HttpService or RbxUtil?

local undefined, null = {isUndefined = true}, {isNull = true}
setmetatable(undefined, {__eq = function(a, b) return rawget(a, 'isUndefined') and rawget(b, 'isUndefined') end, __index = function(_, key) error('attempt to index field '..tostring(key)..' of <undefined>', 2) end, __newindex = function(_, key, value) error('attempt to assign '..tostring(value)..' to field '..tostring(key)..' of <undefined>', 2) end, __metatable = true})
setmetatable(null,      {__eq = function(a, b) return rawget(a, 'isNull')      and rawget(b, 'isNull')      end, __index = function(_, key) error('attempt to index field '..tostring(key)..' of <null>',      2) end, __newindex = function(_, key, value) error('attempt to assign '..tostring(value)..' to field '..tostring(key)..' of <null>',      2) end, __metatable = true})
util.undefined = undefined
util.null = null


local Utilities
local serverStorage = game:GetService('ServerStorage')
if script:IsDescendantOf(serverStorage) then
	Utilities = require(serverStorage.Utilities)
else
	Utilities = require(game:GetService('Players').LocalPlayer.Utilities)
end
util.class = Utilities.class
util.subclass = Utilities.subclass
util.toId = Utilities.toId
util.split = Utilities.split
util.deepcopy = Utilities.deepcopy
util.shallowcopy = Utilities.shallowcopy
util.trim = Utilities.trim
util.rc4 = Utilities.rc4
util.map = Utilities.map
util.sync = Utilities.Sync
util.comma_value = Utilities.comma_value


util.jsonEncode = function(...) return game:GetService('HttpService'):JSONEncode(...) end


function util.Not(v)
	return v == null or v == undefined or v == '' or v == 0 or not v
end


function util.shallowcopy(t)
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = v
	end
	return copy
end


function util.filter(tab, fn)
	local newTab = {}
	for k, v in pairs(tab) do
		if fn(v, k, tab) then
			newTab[k] = v
		end
	end
	return newTab
end


function util.indexOf(searchObject, searchValue)
	if type(searchObject) == 'table' then
		for index, value in pairs(searchObject) do
			if value == searchValue then
				return index
			end
		end
	elseif type(searchObject) == 'string' then
		local objLen = #searchObject
		local valLen = #searchValue
		if valLen > objLen then return end
		for i = 1, objLen-valLen+1 do
			if string.sub(searchObject, i, i+valLen-1) == searchValue then
				return i
			end
		end
	end
end


function util.isArray(obj, ...)
	if type(obj) ~= 'table' then return false end
	local exceptions = {}
	for _, e in pairs({...}) do
		exceptions[e] = true
	end
	for i in pairs(obj) do
		if type(i) ~= 'number' and not exceptions[i] then
--			print('not array because of index', i, '(=', obj[i], ')')
			return false
		end
	end
	return true
end



return util
