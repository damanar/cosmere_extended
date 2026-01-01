--
-- Singer Forms Script
-- Cosmere Extended Extension
--

-- Debug toggle
DEBUG_SINGER_FORMS = false;

-- Form definitions with their unlock requirements and stat modifications
local FORMS = {
	["None"] = {
		unlockTalent = nil,
		statMods = {}
	},
	["Artform"] = {
		unlockTalent = "Forms of Finesse",
		statMods = {
			awareness = 1
		},
		expertises = { "Painting", "Music" }
	},
	["Nimbleform"] = {
		unlockTalent = "Forms of Finesse",
		statMods = {
			speed = 1
		},
		focus = 2
	},
	["Mediationform"] = {
		unlockTalent = "Forms of Wisdom",
		statMods = {
			presence = 1
		}
	},
	["Scholarform"] = {
		unlockTalent = "Forms of Wisdom",
		statMods = {
			intellect = 1
		}
	},
	["Warform"] = {
		unlockTalent = "Forms of Resolve",
		statMods = {
			strength = 1
		},
		deflect = 1
	},
	["Workform"] = {
		unlockTalent = "Forms of Resolve",
		statMods = {
			willpower = 1
		}
	}
};

-- Helper function to check if character is a Singer
local function isSinger(nodeChar)
	local sAncestry = DB.getValue(nodeChar, "ancestry.name", "");
	return sAncestry == "Singer";
end

-- Helper function to check if character has a specific talent
local function hasTalent(nodeChar, sTalentName)
	if not sTalentName or sTalentName == "" then
		return true; -- No requirement
	end
	local bHas, _ = CharManager.locateCharTalent(nodeChar, sTalentName);
	return bHas;
end

-- Get available forms for a character
local function getAvailableForms(nodeChar)
	local tAvailable = {};
	
	if not isSinger(nodeChar) then
		return tAvailable; -- Return empty if not a Singer
	end
	
	-- "None" is always available
	table.insert(tAvailable, "None");
	
	-- Add other forms if unlocked
	for sFormName, tFormData in pairs(FORMS) do
		if sFormName ~= "None" and hasTalent(nodeChar, tFormData.unlockTalent) then
			table.insert(tAvailable, sFormName);
		end
	end
	
	return tAvailable;
end

-- Remove form-granted expertises (only those we created)
local function removeFormExpertises(nodeChar)
	local nodeExpertises = DB.getChild(nodeChar, "expertise");
	if not nodeExpertises then
		return;
	end
	
	local tToRemove = {};
	for _, nodeExpertise in pairs(DB.getChildren(nodeExpertises)) do
		local sSource = DB.getValue(nodeExpertise, "singerform.source", "");
		if sSource == "form" then
			table.insert(tToRemove, nodeExpertise);
		end
	end
	
	for _, nodeExpertise in ipairs(tToRemove) do
		DB.deleteNode(nodeExpertise);
	end
end

-- Add expertises from a form (only mark newly created ones)
local function addFormExpertises(nodeChar, tExpertises)
	if not tExpertises then
		return;
	end
	
	local nodeExpertises = DB.getChild(nodeChar, "expertise");
	if not nodeExpertises then
		nodeExpertises = DB.createChild(nodeChar, "expertise");
	end
	
	for _, sExpertiseName in ipairs(tExpertises) do
		local bFound = false;
		for _, nodeExisting in pairs(DB.getChildren(nodeExpertises)) do
			if DB.getValue(nodeExisting, "name", "") == sExpertiseName then
				bFound = true;
				break;
			end
		end
		
		if not bFound then
			local nodeNew = DB.createChild(nodeExpertises);
			DB.setValue(nodeNew, "name", "string", sExpertiseName);
			DB.setValue(nodeNew, "singerform.source", "string", "form");
		end
	end
end

-- Recalculate deflect to use max of armor and form deflect
local bAdjustingDeflect = false;
local function recalculateDeflect(nodeChar)
	if bAdjustingDeflect or not nodeChar then
		return;
	end
	
	-- Get armor deflect (current deflect value)
	local nArmorDeflect = DB.getValue(nodeChar, "deflect", 0);
	
	-- Get form deflect
	local nFormDeflect = DB.getValue(nodeChar, "singerform.deflect", 0);
	
	-- Use the larger value
	local nFinalDeflect = math.max(nArmorDeflect, nFormDeflect);
	
	-- Update deflect if different
	if nFinalDeflect ~= nArmorDeflect then
		bAdjustingDeflect = true;
		DB.setValue(nodeChar, "deflect", "number", nFinalDeflect);
		bAdjustingDeflect = false;
	end
end

-- Apply form modifiers to character
local function applyFormModifiers(nodeChar, sFormName)
	if not nodeChar then
		return;
	end
	
	-- Get previous form for chat message and effect removal
	local sPrevForm = DB.getValue(nodeChar, "singerform.selected", "None");
	
	-- Get or create modifiers node
	local nodeFormMods = DB.getChild(nodeChar, "singerform.modifiers");
	if not nodeFormMods then
		nodeFormMods = DB.createChild(nodeChar, "singerform.modifiers");
	end
	
	-- Clear all attribute modifiers to 0
	local tAllAttrs = { "strength", "speed", "intellect", "willpower", "awareness", "presence" };
	for _, sAttr in ipairs(tAllAttrs) do
		local nodeAttr = DB.getChild(nodeFormMods, sAttr);
		if not nodeAttr then
			nodeAttr = DB.createChild(nodeFormMods, sAttr, "number");
		end
		DB.setValue(nodeFormMods, sAttr, "number", 0);
	end
	
	-- Remove form-granted expertises
	removeFormExpertises(nodeChar);
	
	-- Clear deflect and focus modifiers
	DB.setValue(nodeChar, "singerform.deflect", "number", 0);
	DB.setValue(nodeChar, "focus.bonus", "number", 0);
	
	-- Apply new form modifiers
	local tFormData = FORMS[sFormName];
	if tFormData and sFormName ~= "None" then
		-- Apply attribute modifiers
		for sAttr, nMod in pairs(tFormData.statMods) do
			DB.setValue(nodeFormMods, sAttr, "number", nMod);
		end
		
		-- Apply expertises
		if tFormData.expertises then
			addFormExpertises(nodeChar, tFormData.expertises);
		end
		
		-- Apply deflect
		if tFormData.deflect then
			DB.setValue(nodeChar, "singerform.deflect", "number", tFormData.deflect);
		end
		
		-- Apply focus
		if tFormData.focus then
			DB.setValue(nodeChar, "focus.bonus", "number", tFormData.focus);
		end
		
		-- Recalculate deflect to include form deflect
		recalculateDeflect(nodeChar);
		
		-- Send chat message
		local sCharName = DB.getValue(nodeChar, "name", "");
		if sCharName and sCharName ~= "" then
			local rActor = ActorManager.resolveActor(nodeChar);
			if rActor then
				local msg = ChatManager.createBaseMessage(rActor);
				msg.text = sCharName .. " has assumed " .. sFormName;
				Comm.deliverChatMessage(msg);
			end
		end
	end
	
	-- Store selected form
	DB.setValue(nodeChar, "singerform.selected", "string", sFormName);
	
	-- Recalculate deflect after clearing (in case form was removed)
	if sFormName == "None" then
		recalculateDeflect(nodeChar);
	end
end

-- Update form selector combobox
local function updateFormSelector(w)
	if not w or not w.singer_form_selector then
		return;
	end
	
	local nodeChar = nil;
	if w.singer_form_selector.getDatabaseNode then
		nodeChar = w.singer_form_selector.getDatabaseNode();
		if nodeChar then
			nodeChar = DB.getParent(nodeChar);
			if nodeChar then
				nodeChar = DB.getParent(nodeChar);
			end
		end
	end
	
	if not nodeChar and w.getDatabaseNode then
		nodeChar = w.getDatabaseNode();
	end
	
	if not nodeChar then
		return;
	end
	
	-- Check if character is a Singer
	if not isSinger(nodeChar) then
		if w.singer_form_header then
			w.singer_form_header.setVisible(false);
		end
		if w.singer_form_selector then
			w.singer_form_selector.setVisible(false);
		end
		applyFormModifiers(nodeChar, "None");
		return;
	end
	
	-- Show the header and selector
	if w.singer_form_header then
		w.singer_form_header.setVisible(true);
	end
	if w.singer_form_selector then
		w.singer_form_selector.setVisible(true);
	end
	
	-- Clear existing options
	w.singer_form_selector.clear();
	
	-- Get available forms
	local tAvailable = getAvailableForms(nodeChar);
	
	-- Add all available forms
	for _, sFormName in ipairs(tAvailable) do
		w.singer_form_selector.addItem({ sValue = sFormName, sText = sFormName });
	end
	
	-- Set current selection
	local sCurrentForm = DB.getValue(nodeChar, "singerform.selected", "None");
	if sCurrentForm == "" then
		sCurrentForm = "None";
	end
	w.singer_form_selector.setValue(sCurrentForm);
end

-- Hook into armor deflect calculation to include form deflect
local originalCalcItemDeflect = nil;
local bCalcItemDeflectHooked = false;

local function initCalcItemDeflectHook()
	if not bCalcItemDeflectHooked and CharArmorManager and CharArmorManager.calcItemDeflect then
		originalCalcItemDeflect = CharArmorManager.calcItemDeflect;
		CharArmorManager.calcItemDeflect = function(nodeChar)
			-- Call original function
			originalCalcItemDeflect(nodeChar);
			-- Adjust deflect to include form deflect (max of armor and form)
			recalculateDeflect(nodeChar);
		end
		bCalcItemDeflectHooked = true;
	end
end

-- Windowclass onInit
function onInit()
	local w = self;
	
	-- Try to initialize calcItemDeflect hook (in case CharArmorManager wasn't loaded when script loaded)
	initCalcItemDeflectHook();
	
	-- Get database node
	local nodeChar = nil;
	if w.singer_form_selector and w.singer_form_selector.getDatabaseNode then
		nodeChar = w.singer_form_selector.getDatabaseNode();
		if nodeChar then
			nodeChar = DB.getParent(nodeChar);
			if nodeChar then
				nodeChar = DB.getParent(nodeChar);
			end
		end
	end
	
	if not nodeChar and w.getDatabaseNode then
		nodeChar = w.getDatabaseNode();
	end
	
	if not nodeChar then
		return;
	end
	
	-- Store handler functions
	local function onAncestryChanged()
		updateFormSelector(w);
	end
	local function onTalentChanged()
		updateFormSelector(w);
	end
	
	w._ancestryHandler = onAncestryChanged;
	w._talentHandler = onTalentChanged;
	w._nodeChar = nodeChar;
	
	-- Update form selector
	updateFormSelector(w);
	
	-- Watch for ancestry changes
	DB.addHandler(DB.getPath(nodeChar, "ancestry.name"), "onUpdate", onAncestryChanged);
	
	-- Watch for talent changes
	local nodeTalents = DB.getChild(nodeChar, "talent");
	if nodeTalents then
		DB.addHandler(nodeTalents, "onChildAdded", onTalentChanged);
		DB.addHandler(nodeTalents, "onChildDeleted", onTalentChanged);
		DB.addHandler(DB.getPath(nodeTalents, "*.name"), "onUpdate", onTalentChanged);
		w._nodeTalents = nodeTalents;
	end
	
	-- Watch for form selection changes
	if w.singer_form_selector then
		local function onFormChanged()
			local sSelectedForm = w.singer_form_selector.getValue();
			if not sSelectedForm or sSelectedForm == "" then
				sSelectedForm = "None";
			end
			applyFormModifiers(nodeChar, sSelectedForm);
		end
		w.singer_form_selector.onValueChanged = onFormChanged;
	end
end

-- Windowclass onClose
function onClose()
	local w = self;
	local nodeChar = w._nodeChar;
	
	if nodeChar and w._ancestryHandler then
		DB.removeHandler(DB.getPath(nodeChar, "ancestry.name"), "onUpdate", w._ancestryHandler);
	end
	
	if w._nodeTalents and w._talentHandler then
		DB.removeHandler(w._nodeTalents, "onChildAdded", w._talentHandler);
		DB.removeHandler(w._nodeTalents, "onChildDeleted", w._talentHandler);
		DB.removeHandler(DB.getPath(w._nodeTalents, "*.name"), "onUpdate", w._talentHandler);
	end
	
	w._nodeChar = nil;
	w._nodeTalents = nil;
	w._ancestryHandler = nil;
	w._talentHandler = nil;
end

-- Initialize the calcItemDeflect hook when script loads
-- CharArmorManager might not be loaded yet, so we'll also try in the windowclass onInit
initCalcItemDeflectHook();

