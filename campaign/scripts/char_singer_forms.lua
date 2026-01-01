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
	},
	["Decayform"] = {
		unlockTalent = "Forms of Mystery",
		statMods = {
			willpower = 2
		}
	},
	["Direform"] = {
		unlockTalent = "Forms of Destruction",
		statMods = {
			strength = 2
		},
		deflect = 2
	},
	["Envoyform"] = {
		unlockTalent = "Forms of Expansion",
		statMods = {
			intellect = 1,
			presence = 1
		}
	},
	["Nightform"] = {
		unlockTalent = "Forms of Mystery",
		statMods = {
			awareness = 1,
			intellect = 1
		},
		focus = 2
	},
	["Relayform"] = {
		unlockTalent = "Forms of Expansion",
		statMods = {
			speed = 2
		}
	},
	["Stormform"] = {
		unlockTalent = "Forms of Destruction",
		statMods = {
			strength = 1,
			speed = 1
		},
		attack = {
			name = "Unleash Lightning",
			skill = "Discipline",
			type = "energy",
			value = "2d8"
		},
		deflect = 1
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

-- Remove form-granted attacks (only those we created)
local function removeFormAttacks(nodeChar)
	local nodeWeapons = DB.getChild(nodeChar, "weaponlist");
	if not nodeWeapons then
		return;
	end
	
	local tToRemove = {};
	for _, nodeWeapon in pairs(DB.getChildren(nodeWeapons)) do
		local sSource = DB.getValue(nodeWeapon, "singerform.source", "");
		if sSource == "form" then
			table.insert(tToRemove, nodeWeapon);
		end
	end
	
	for _, nodeWeapon in ipairs(tToRemove) do
		DB.deleteNode(nodeWeapon);
	end
end

-- Add attack from a form
local function addFormAttack(nodeChar, tAttack)
	if not tAttack or not nodeChar then
		return;
	end
	
	local nodeWeapons = DB.getChild(nodeChar, "weaponlist");
	if not nodeWeapons then
		nodeWeapons = DB.createChild(nodeChar, "weaponlist");
	end
	
	-- Check if attack already exists
	for _, nodeExisting in pairs(DB.getChildren(nodeWeapons)) do
		if DB.getValue(nodeExisting, "singerform.source", "") == "form" then
			-- Update existing form attack
			DB.setValue(nodeExisting, "name", "string", tAttack.name);
			DB.setValue(nodeExisting, "weaponskill", "string", tAttack.skill);
			DB.setValue(nodeExisting, "defense", "string", "spiritual"); -- Energy attacks typically target spiritual defense
			
			-- Parse damage and update damage list
			local aDice, nMod = StringManager.convertStringToDice(tAttack.value);
			local nodeDmgList = DB.getChild(nodeExisting, "damagelist");
			if nodeDmgList then
				DB.deleteChildren(nodeDmgList);
			else
				nodeDmgList = DB.createChild(nodeExisting, "damagelist");
			end
			
			local nodeDmg = DB.createChild(nodeDmgList);
			if nodeDmg then
				DB.setValue(nodeDmg, "dice", "dice", aDice);
				DB.setValue(nodeDmg, "stat", "string", tAttack.skill);
				DB.setValue(nodeDmg, "bonus", "number", nMod);
				DB.setValue(nodeDmg, "type", "string", tAttack.type);
			end
			
			return; -- Attack updated, exit
		end
	end
	
	-- Create new attack
	local nodeWeapon = DB.createChild(nodeWeapons, "formattack");
	if nodeWeapon then
		DB.setValue(nodeWeapon, "name", "string", tAttack.name);
		DB.setValue(nodeWeapon, "weaponskill", "string", tAttack.skill);
		DB.setValue(nodeWeapon, "type", "number", 1); -- Ranged (energy attack)
		DB.setValue(nodeWeapon, "defense", "string", "spiritual"); -- Energy attacks typically target spiritual defense
		DB.setValue(nodeWeapon, "carried", "number", 2); -- Equipped
		DB.setValue(nodeWeapon, "singerform.source", "string", "form");
		
		-- Parse damage dice
		local aDice, nMod = StringManager.convertStringToDice(tAttack.value);
		
		-- Create damage list
		local nodeDmgList = DB.createChild(nodeWeapon, "damagelist");
		if nodeDmgList then
			local nodeDmg = DB.createChild(nodeDmgList);
			if nodeDmg then
				DB.setValue(nodeDmg, "dice", "dice", aDice);
				DB.setValue(nodeDmg, "stat", "string", tAttack.skill);
				DB.setValue(nodeDmg, "bonus", "number", nMod);
				DB.setValue(nodeDmg, "type", "string", tAttack.type);
			end
		end
	end
end

-- Recalculate deflect to use max of armor and form deflect
local bAdjustingDeflect = false;
local function recalculateDeflect(nodeChar)
	if bAdjustingDeflect or not nodeChar then
		return;
	end
	
	-- Calculate base armor deflect from equipped armor
	local nArmorDeflect = 0;
	for _, vNode in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
		if DB.getValue(vNode, "carried", 0) == 2 then
			if ItemManager and ItemManager.isArmor and ItemManager.isArmor(vNode) then
				nArmorDeflect = DB.getValue(vNode, "deflect", 0);
				break; -- Only use the first equipped armor
			end
		end
	end
	
	-- Get form deflect
	local nFormDeflect = DB.getValue(nodeChar, "singerform.deflect", 0);
	
	-- Use the larger value
	local nFinalDeflect = math.max(nArmorDeflect, nFormDeflect);
	
	-- Update deflect
	bAdjustingDeflect = true;
	DB.setValue(nodeChar, "deflect", "number", nFinalDeflect);
	bAdjustingDeflect = false;
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
	
	-- Remove form-granted attacks
	removeFormAttacks(nodeChar);
	
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
		
		-- Apply attack
		if tFormData.attack then
			addFormAttack(nodeChar, tFormData.attack);
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

