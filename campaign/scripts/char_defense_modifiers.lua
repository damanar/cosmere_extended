--
-- Defense Modifiers Window Script
-- Cosmere Extended Extension
--

function onInit()
	-- Store reference to window and cache nodeChar
	local w = self;
	local nodeChar = w.getDatabaseNode();
	
	-- Generic update function factory
	local function createUpdateFunction(derivedControl, modifierControl, totalControl)
		return function()
			if derivedControl and modifierControl and totalControl then
				local nDerived = derivedControl.getValue();
				local nModifier = modifierControl.getValue();
				totalControl.setValue(nDerived + nModifier);
			end
		end
	end
	
	-- Create update functions using the factory
	local updatePhysicalTotal = createUpdateFunction(w.physical_derived, w.physical_modifier, w.physical_total);
	local updateCognitiveTotal = createUpdateFunction(w.cognitive_derived, w.cognitive_modifier, w.cognitive_total);
	local updateSpiritualTotal = createUpdateFunction(w.spiritual_derived, w.spiritual_modifier, w.spiritual_total);
	
	-- Store update functions on window for access from other scripts
	w.updatePhysicalTotal = updatePhysicalTotal;
	w.updateCognitiveTotal = updateCognitiveTotal;
	w.updateSpiritualTotal = updateSpiritualTotal;
	
	-- Initial updates
	updatePhysicalTotal();
	updateCognitiveTotal();
	updateSpiritualTotal();
	
	-- Register handlers for modifier changes
	DB.addHandler(DB.getPath(nodeChar, "defenses.physicaldefense.modifier"), "onUpdate", updatePhysicalTotal);
	DB.addHandler(DB.getPath(nodeChar, "defenses.cognitivedefense.modifier"), "onUpdate", updateCognitiveTotal);
	DB.addHandler(DB.getPath(nodeChar, "defenses.spiritualdefense.modifier"), "onUpdate", updateSpiritualTotal);
end

function onClose()
	local w = self;
	local nodeChar = w.getDatabaseNode();
	
	if w.updatePhysicalTotal then
		DB.removeHandler(DB.getPath(nodeChar, "defenses.physicaldefense.modifier"), "onUpdate", w.updatePhysicalTotal);
	end
	if w.updateCognitiveTotal then
		DB.removeHandler(DB.getPath(nodeChar, "defenses.cognitivedefense.modifier"), "onUpdate", w.updateCognitiveTotal);
	end
	if w.updateSpiritualTotal then
		DB.removeHandler(DB.getPath(nodeChar, "defenses.spiritualdefense.modifier"), "onUpdate", w.updateSpiritualTotal);
	end
end

