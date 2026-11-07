-- Bee Gone: every B typed into the chat box becomes a C (b -> c, B -> C).
-- Lines that start with "/" are left alone so slash commands and
-- whisper names still work.

local hooked = {}

local function OnTextChanged(editBox, userInput)
	if not userInput or not BeeGoneDB.enabled then
		return
	end
	local text = editBox:GetText()
	if text:sub(1, 1) == "/" or not text:find("[Bb]") then
		return
	end
	local cursor = editBox:GetCursorPosition()
	local newText = text:gsub("B", "C"):gsub("b", "c")
	editBox:SetText(newText)
	editBox:SetCursorPosition(cursor) -- same length, so the cursor stays put
end

local function Hook(editBox)
	if editBox and not hooked[editBox] then
		editBox:HookScript("OnTextChanged", OnTextChanged)
		hooked[editBox] = true
	end
end

local function HookAll()
	for i = 1, (NUM_CHAT_WINDOWS or 10) do
		Hook(_G["ChatFrame" .. i .. "EditBox"])
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	BeeGoneDB = BeeGoneDB or {}
	if BeeGoneDB.enabled == nil then
		BeeGoneDB.enabled = true
	end
	HookAll()
	-- Whisper pop-out windows create new edit boxes later.
	if FCF_OpenTemporaryWindow then
		hooksecurefunc("FCF_OpenTemporaryWindow", HookAll)
	end
end)

SLASH_BEEGONE1 = "/beegone"
SlashCmdList.BEEGONE = function()
	BeeGoneDB.enabled = not BeeGoneDB.enabled
	print("|cff33ff99Bee Gone|r " .. (BeeGoneDB.enabled and "on" or "off"))
end
