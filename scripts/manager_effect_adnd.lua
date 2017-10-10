--
-- Effects on Items, apply to character in CT
--
--
-- add the effect if the item is equipped and doesn't exist already
function onInit()
	CombatManager.setCustomAddPC(addPC);
    CombatManager.setCustomAddNPC(addNPC);
end

function updateItemEffects(nodeItem)
--Debug.console("manager_effect_adnd.lua","updateItemEffects1","nodeItem",nodeItem);
    local nodeChar = DB.getChild(nodeItem, "...");
    if not nodeChar then
        return;
    end
    local sUser = User.getUsername();
    local sName = DB.getValue(nodeItem, "name", "");
    -- we swap the node to the combat tracker node
    -- so the "effect" is written to the right node
    if not string.match(nodeChar.getPath(),"^combattracker") then
        nodeChar = getCTNodeByNodeChar(nodeChar);
    end
--Debug.console("manager_effect_adnd.lua","updateItemEffects","nodeChar3",nodeChar);
    -- if not in the combat tracker bail
    if not nodeChar then
        return;
    end
    
    local nCarried = DB.getValue(nodeItem, "carried", 0);
    local bEquipped = (nCarried == 2);
    local nIdentified = DB.getValue(nodeItem, "isidentified", 0);
    local bOptionID = OptionsManager.isOption("MIID", "on");
    if not bOptionID then 
        nIdentified = 1;
    end

-- Debug.console("manager_effect_adnd.lua","updateItemEffects","sUser",sUser);
-- Debug.console("manager_effect_adnd.lua","updateItemEffects","nodeChar",nodeChar);
-- Debug.console("manager_effect_adnd.lua","updateItemEffects","nodeItem",nodeItem);
-- Debug.console("manager_effect_adnd.lua","updateItemEffects","nCarried",nCarried);
-- Debug.console("manager_effect_adnd.lua","updateItemEffects","bEquipped",bEquipped);
-- Debug.console("manager_effect_adnd.lua","updateItemEffects","nIdentified",nIdentified);

    for _,nodeItemEffect in pairs(DB.getChildren(nodeItem, "effectlist")) do
        updateItemEffect(nodeItemEffect, sName, nodeChar, sUser, bEquipped, nIdentified);
    end -- for item's effects list
end

-- update single effect for item
function updateItemEffect(nodeItemEffect, sName, nodeChar, sUser, bEquipped, nIdentified)
    local sCharacterName = DB.getValue(nodeChar, "name", "");
    local sItemSource = nodeItemEffect.getPath();
    local sLabel = DB.getValue(nodeItemEffect, "effect", "");
-- Debug.console("manager_effect_adnd.lua","updateItemEffect","sName",sName);
-- Debug.console("manager_effect_adnd.lua","updateItemEffect","sLabel",sLabel);
-- Debug.console("manager_effect_adnd.lua","updateItemEffect","sItemSource",sItemSource);
    if sLabel and sLabel ~= "" then -- if we have effect string
        local bFound = false;
        for _,nodeEffect in pairs(DB.getChildren(nodeChar, "effects")) do
            local nActive = DB.getValue(nodeEffect, "isactive", 0);
--Debug.console("manager_effect.lua","updateItemEffect","nActive",nActive);
            if (nActive ~= 0) then
                local sEffSource = DB.getValue(nodeEffect, "source_name", "");
--Debug.console("manager_effect.lua","updateItemEffect","sEffSource",sEffSource);
                if (sEffSource == sItemSource) then
                    bFound = true;
--Debug.console("manager_effect.lua","updateItemEffect","bFound!!!",bFound);
                    if (not bEquipped) then
                        -- BUILD MESSAGE
                        local msg = {font = "msgfont", icon = "roll_effect"};
                        msg.text = "Effect ['" .. sLabel .. "'] ";
                        msg.text = msg.text .. "removed [from " .. sCharacterName .. "]";
                        -- HANDLE APPLIED BY SETTING
                        if sEffSource and sEffSource ~= "" then
                            msg.text = msg.text .. " [by " .. DB.getValue(DB.findNode(sEffSource), "name", "") .. "]";
                        end
                        -- SEND MESSAGE
                        if nIdentified > 0 then
                            if EffectManager.isGMEffect(nodeChar, nodeEffect) then
                                if sUser == "" then
                                    msg.secret = true;
                                    Comm.addChatMessage(msg);
                                elseif sUser ~= "" then
                                    Comm.addChatMessage(msg);
                                    Comm.deliverChatMessage(msg, sUser);
                                end
                            else
                                Comm.deliverChatMessage(msg);
                            end
                        end
                    
--Debug.console("manager_effect_adnd.lua","updateItemEffect","!!!bEquipped",bEquipped);
                        nodeEffect.delete();
                        break;
                    end -- not equipped
                end -- effect source == item source
            end -- was active
        end -- nodeEffect for
        
--Debug.console("manager_effect_adnd.lua","updateItemEffect","pre bEquipped",bEquipped);
        if (not bFound and bEquipped) then
--Debug.console("manager_effect_adnd.lua","updateItemEffect","bFound and bEquipped",bEquipped);
            local rEffect = {};
            local nRollDuration = 0;
            local dDurationDice = DB.getValue(nodeItemEffect, "durdice");
            local nModDice = DB.getValue(nodeItemEffect, "durmod", 0);
            if (dDurationDice and dDurationDice ~= "") then
                nRollDuration = StringManager.evalDice(dDurationDice, nModDice);
            else
                nRollDuration = nModDice;
            end
            local nDMOnly = 0;
            local sVisibility = DB.getValue(nodeItemEffect, "visibility", "");
            if sVisibility == "show" then
                nDMOnly = 0;
            elseif sVisibility == "hide" then
                nDMOnly = 1;
            elseif nIdentified > 0 then
                nDMOnly = 0;
            end
            
            rEffect.nDuration = nRollDuration;
            rEffect.sName = sName .. ";" .. sLabel;
            rEffect.sLabel = sLabel; 
            rEffect.sUnits = DB.getValue(nodeItemEffect, "durunit", "day");
            rEffect.nInit = 0;
            rEffect.sSource = sItemSource;
            rEffect.nGMOnly = nDMOnly;
            rEffect.sApply = "";
--Debug.console("manager_effect_adnd.lua","updateItemEffect","rEffect",rEffect);
            EffectManager.addEffect(sUser, "", nodeChar, rEffect, true);
        end
    end
end


-- return the CTnode by using character sheet node 
function getCTNodeByNodeChar(nodeChar)
    local nodeCT = nil;
	for _,node in pairs(DB.getChildren("combattracker.list")) do
        local _, sRecord = DB.getValue(node, "link", "", "");
        if sRecord ~= "" and sRecord == nodeChar.getPath() then
            nodeCT = node;
            break;
        end
    end
    return nodeCT;
end

-- flip through all npc effects (generally do this in addNPC()/addPC()
-- nodeChar: node of PC/NPC in PC/NPCs record list
-- nodeEntry: node in combat tracker for PC/NPC
function updateCharEffects(nodeChar,nodeEntry)
    for _,nodeCharEffect in pairs(DB.getChildren(nodeChar, "effectlist")) do
        updateCharEffect(nodeCharEffect,nodeEntry);
    end -- for item's effects list 
end
-- this will be used to manage PC/NPC effectslist objects
-- nodeCharEffect: node in effectlist on PC/NPC
-- nodeEntry: node in combat tracker for PC/NPC
function updateCharEffect(nodeCharEffect,nodeEntry)
    local sName = DB.getValue(nodeEntry, "name", "");
    local sLabel = DB.getValue(nodeCharEffect, "effect", "");
    local nRollDuration = 0;
    local dDurationDice = DB.getValue(nodeCharEffect, "durdice");
    local nModDice = DB.getValue(nodeCharEffect, "durmod", 0);
    if (dDurationDice and dDurationDice ~= "") then
        nRollDuration = StringManager.evalDice(dDurationDice, nModDice);
    else
        nRollDuration = nModDice;
    end
    local nDMOnly = 0;
    local sVisibility = DB.getValue(nodeCharEffect, "visibility", "");
    if sVisibility == "show" then
        nDMOnly = 0;
    elseif sVisibility == "hide" then
        nDMOnly = 1;
    end
    local rEffect = {};
    rEffect.nDuration = nRollDuration;
    --rEffect.sName = sName .. ";" .. sLabel;
    rEffect.sName = sLabel;
    rEffect.sLabel = sLabel; 
    rEffect.sUnits = DB.getValue(nodeCharEffect, "durunit", "day");
    rEffect.nInit = 0;
    --rEffect.sSource = nodeEntry.getPath();
    rEffect.nGMOnly = nDMOnly;
    rEffect.sApply = "";
    EffectManager.addEffect("", "", nodeEntry, rEffect, true);
end

-- custom version of the one in CoreRPG to deal with adding new 
-- pcs to the combat tracker to deal with advanced effects. --celestian
function addPC(nodePC)
	-- Parameter validation
	if not nodePC then
		return;
	end

	-- Create a new combat tracker window
	local nodeEntry = DB.createChild("combattracker.list");
	if not nodeEntry then
		return;
	end
	
	-- Set up the CT specific information
	DB.setValue(nodeEntry, "link", "windowreference", "charsheet", nodePC.getNodeName());
	DB.setValue(nodeEntry, "friendfoe", "string", "friend");

	local sToken = DB.getValue(nodePC, "token", nil);
	if not sToken or sToken == "" then
		sToken = "portrait_" .. nodePC.getName() .. "_token"
	end
	DB.setValue(nodeEntry, "token", "token", sToken);

    -- check to see if npc effects exists and if so apply --celestian
    updateCharEffects(nodePC,nodeEntry);
end

-- copied the base addNPC from manager_combat2.lua from 5E ruleset for this and
-- added the bit that checks for PC effects to add -- celestian
function addNPC(sClass, nodeNPC, sName)
	local nodeEntry, nodeLastMatch = CombatManager.addNPCHelper(nodeNPC, sName);
	
	-- Fill in spells
	CampaignDataManager2.updateNPCSpells(nodeEntry);
	
	-- Determine size
	local sSize = StringManager.trim(DB.getValue(nodeEntry, "size", ""):lower());
	if sSize == "large" then
		DB.setValue(nodeEntry, "space", "number", 10);
	elseif sSize == "huge" then
		DB.setValue(nodeEntry, "space", "number", 15);
	elseif sSize == "gargantuan" then
		DB.setValue(nodeEntry, "space", "number", 20);
	end
	
	-- Set current hit points
	local sOptHRNH = OptionsManager.getOption("HRNH");
	local nHP = DB.getValue(nodeNPC, "hp", 0);
	local sHD = StringManager.trim(DB.getValue(nodeNPC, "hd", ""));
	if sOptHRNH == "max" and sHD ~= "" then
		nHP = StringManager.evalDiceString(sHD, true, true);
	elseif sOptHRNH == "random" and sHD ~= "" then
		nHP = math.max(StringManager.evalDiceString(sHD, true), 1);
	end
	DB.setValue(nodeEntry, "hptotal", "number", nHP);
	
	-- Set initiative from Dexterity modifier
	local nDex = DB.getValue(nodeNPC, "abilities.dexterity.score", 10);
	local nDexMod = math.floor((nDex - 10) / 2);
	DB.setValue(nodeEntry, "init", "number", nDexMod);
	
	-- Track additional damage types and intrinsic effects
	local aEffects = {};
	
	-- Vulnerabilities
	local aVulnTypes = CombatManager2.parseResistances(DB.getValue(nodeEntry, "damagevulnerabilities", ""));
	if #aVulnTypes > 0 then
		for _,v in ipairs(aVulnTypes) do
			if v ~= "" then
				table.insert(aEffects, "VULN: " .. v);
			end
		end
	end
			
	-- Damage Resistances
	local aResistTypes = CombatManager2.parseResistances(DB.getValue(nodeEntry, "damageresistances", ""));
	if #aResistTypes > 0 then
		for _,v in ipairs(aResistTypes) do
			if v ~= "" then
				table.insert(aEffects, "RESIST: " .. v);
			end
		end
	end
	
	-- Damage immunities
	local aImmuneTypes = CombatManager2.parseResistances(DB.getValue(nodeEntry, "damageimmunities", ""));
	if #aImmuneTypes > 0 then
		for _,v in ipairs(aImmuneTypes) do
			if v ~= "" then
				table.insert(aEffects, "IMMUNE: " .. v);
			end
		end
	end

	-- Condition immunities
	local aImmuneCondTypes = {};
	local sCondImmune = DB.getValue(nodeEntry, "conditionimmunities", ""):lower();
	for _,v in ipairs(StringManager.split(sCondImmune, ",;\r", true)) do
		if StringManager.isWord(v, DataCommon.conditions) then
			table.insert(aImmuneCondTypes, v);
		end
	end
	if #aImmuneCondTypes > 0 then
		table.insert(aEffects, "IMMUNE: " .. table.concat(aImmuneCondTypes, ", "));
	end
	
	-- Decode traits and actions
	local rActor = ActorManager.getActor("", nodeNPC);
	for _,v in pairs(DB.getChildren(nodeEntry, "actions")) do
		CombatManager2.parseNPCPower(rActor, v, aEffects);
	end
	for _,v in pairs(DB.getChildren(nodeEntry, "legendaryactions")) do
		CombatManager2.parseNPCPower(rActor, v, aEffects);
	end
	for _,v in pairs(DB.getChildren(nodeEntry, "lairactions")) do
		CombatManager2.parseNPCPower(rActor, v, aEffects);
	end
	for _,v in pairs(DB.getChildren(nodeEntry, "reactions")) do
		CombatManager2.parseNPCPower(rActor, v, aEffects);
	end
	for _,v in pairs(DB.getChildren(nodeEntry, "traits")) do
		CombatManager2.parseNPCPower(rActor, v, aEffects);
	end
	for _,v in pairs(DB.getChildren(nodeEntry, "innatespells")) do
		CombatManager2.parseNPCPower(rActor, v, aEffects, true);
	end
	for _,v in pairs(DB.getChildren(nodeEntry, "spells")) do
		CombatManager2.parseNPCPower(rActor, v, aEffects, true);
	end

	-- Add special effects
	if #aEffects > 0 then
		EffectManager.addEffect("", "", nodeEntry, { sName = table.concat(aEffects, "; "), nDuration = 0, nGMOnly = 1 }, false);
	end

    -- check to see if npc effects exists and if so apply --celestian
    EffectManagerADND.updateNPCEffects(nodeNPC,nodeEntry);

	-- Roll initiative and sort
	local sOptINIT = OptionsManager.getOption("INIT");
	if sOptINIT == "group" then
		if nodeLastMatch then
			local nLastInit = DB.getValue(nodeLastMatch, "initresult", 0);
			DB.setValue(nodeEntry, "initresult", "number", nLastInit);
		else
			DB.setValue(nodeEntry, "initresult", "number", math.random(20) + DB.getValue(nodeEntry, "init", 0));
		end
	elseif sOptINIT == "on" then
		DB.setValue(nodeEntry, "initresult", "number", math.random(20) + DB.getValue(nodeEntry, "init", 0));
	end

	return nodeEntry;
end
