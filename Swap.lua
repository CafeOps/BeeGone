-- Bee Gone swap logic: b -> c and B -> C, but only in text you typed.
-- Item/spell/quest/player links, color codes, icons and escaped pipes are copied
-- untouched. Changing a letter inside a link (or its hex color) breaks the link.
-- Every replacement is one character for one character, so the length never changes.

local _, ns = ...

local PROTECT = {
	"^||", -- escaped pipe
	"^|c%x%x%x%x%x%x%x%x", -- color start, e.g. |cffa335ee
	"^|cn.-:", -- named color start, e.g. |cnIQ4:
	"^|r", -- color end
	"^|H.-|h.-|h", -- hyperlink: |Hitem:...|h[Name]|h
	"^|T.-|t", -- texture icon
	"^|A.-|a", -- atlas icon
	"^|K.-|k", -- protected Battle.net name
}

local function SwapPlain(s)
	return (s:gsub("B", "C"):gsub("b", "c"))
end

function ns.Swap(text)
	local out, i, n = {}, 1, #text
	while i <= n do
		local bar = text:find("|", i, true)
		if not bar then
			out[#out + 1] = SwapPlain(text:sub(i))
			break
		end
		if bar > i then
			out[#out + 1] = SwapPlain(text:sub(i, bar - 1))
		end
		local s, e
		for _, pattern in ipairs(PROTECT) do
			s, e = text:find(pattern, bar)
			if s then
				break
			end
		end
		if s then
			out[#out + 1] = text:sub(s, e)
			i = e + 1
		else
			out[#out + 1] = "|"
			i = bar + 1
		end
	end
	return table.concat(out)
end
