local function getActiveConnections(obj, ignoreKeys, name)
	local seen = {}
	local results = {}

	local function shouldIgnoreKey(key)
		for _, k in pairs(ignoreKeys) do
			if k == key then
				return true
			end
		end
		return false
	end

	local function collectActiveConnections(child, namespace)
		if seen[child] then
			-- Break out of cyclical tables
			return
		end
		seen[child] = true

		for k, v in pairs(child) do
			if not shouldIgnoreKey(k) then
				local kStr = tostring(k)
				local fullNameKey = namespace == "" and kStr or namespace.. "." ..kStr
				if typeof(v) == "table" then
					collectActiveConnections(v, fullNameKey)
				elseif typeof(v) == "RBXScriptConnection" and v.Connected then
					results[fullNameKey] = v
				end
			end
		end
	end

	collectActiveConnections(obj, name)
	return results
end

return getActiveConnections