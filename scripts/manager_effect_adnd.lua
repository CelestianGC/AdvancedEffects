--
-- Effects on Items, apply to character in CT
--
--
-- add the effect if the item is equipped and doesn't exist already
function onInit()
  if User.isHost() then
    -- watch the combatracker/npc inventory list
    DB.addHandler("combattracker.list.*.inventorylist.*.carried", "onUpdate", inventoryUpdateItemEffects);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.effect", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.durdice", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.durmod", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.name", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.durunit", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.visibility", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.actiononly", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.isidentified", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist", "onChildDeleted", updateFromDeletedInventory);

    -- watch the character/pc inventory list
    DB.addHandler("charsheet.*.inventorylist.*.carried", "onUpdate", inventoryUpdateItemEffects);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.effect", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.durdice", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.durmod", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.name", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.durunit", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.visibility", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.actiononly", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.isidentified", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist", "onChildDeleted", updateFromDeletedInventory);
  end
	CombatManager.setCustomAddPC(addPC);
  CombatManager.setCustomAddNPC(addNPC);

  --CoreRPG replacements
  ActionsManager.decodeActors = decodeActors;
  
  -- 5E effects replacements
  EffectManager5E.checkConditionalHelper = checkConditionalHelper;
  EffectManager5E.getEffectsByType = getEffectsByType;
  EffectManager5E.hasEffect = hasEffect;

  -- used for AD&D Core ONLY
  --EffectManager5E.evalAbilityHelper = evalAbilityHelper;
  
  -- used for 5E extension ONLY
  ActionAttack.performRoll = manager_action_attack_performRoll;
  ActionDamage.performRoll = manager_action_damage_performRoll;
  PowerManager.performAction = manager_power_performAction;

    -- option in house rule section, enable/disable allow PCs to edit advanced effects.
	OptionsManager.registerOption2("ADND_AE_EDIT", false, "option_header_houserule", "option_label_ADND_AE_EDIT", "option_entry_cycler", 
			{ labels = "option_label_ADND_AE_enabled" , values = "enabled", baselabel = "option_label_ADND_AE_disabled", baseval = "disabled", default = "disabled" });    
end

-- run from addHandler for updated item effect options
function inventoryUpdateItemEffects(nodeField)
		updateItemEffects(DB.getChild(nodeField, ".."));
end
-- update single item from edit for *.effect handler
function updateItemEffectsForEdit(nodeField)
  checkEffectsAfterEdit(nodeField.getChild(".."));
end
-- find the effect for this source and delete and re-build
function checkEffectsAfterEdit(itemNode)
  local nodeChar = nil
  local bIDUpdated = false;
  if itemNode.getPath():match("%.effectlist%.") then
    nodeChar = DB.getChild(itemNode, ".....");
  else
    nodeChar = DB.getChild(itemNode, "...");
    bIDUpdated = true;
  end
  local nodeCT = getCTNodeByNodeChar(nodeChar);
  if nodeCT then
    for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
      local sLabel = DB.getValue(nodeEffect, "label", "");
      local sEffSource = DB.getValue(nodeEffect, "source_name", "");
      -- see if the node exists and if it's in an inventory node
      local nodeEffectFound = DB.findNode(sEffSource);
      if (nodeEffectFound  and string.match(sEffSource,"inventorylist")) then
        local nodeEffectItem = nodeEffectFound.getChild("...");
        if nodeEffectFound == itemNode then -- effect hide/show edit
          nodeEffect.delete();
          updateItemEffects(DB.getChild(itemNode, "..."));
        elseif nodeEffectItem == itemNode then -- id state was changed
          nodeEffect.delete();
          updateItemEffects(nodeEffectItem);
        end
      end
    end
  end
end
-- this checks to see if an effect is missing a associated item that applied the effect 
-- when items are deleted and then clears that effect if it's missing.
function updateFromDeletedInventory(node)
--Debug.console("manager_effect_adnd.lua","updateFromDeletedInventory","node",node);
    local nodeChar = DB.getChild(node, "..");
    local bisNPC = (not ActorManager.isPC(nodeChar));
    local nodeTarget = nodeChar;
    local nodeCT = getCTNodeByNodeChar(nodeChar);
    -- if we're already in a combattracker situation (npcs)
    if bisNPC and string.match(nodeChar.getPath(),"^combattracker") then
        nodeCT = nodeChar;
    end
    if nodeCT then
        -- check that we still have the combat effect source item
        -- otherwise remove it
        checkEffectsAfterDelete(nodeCT);
    end
	--onEncumbranceChanged();
end

-- this checks to see if an effect is missing a associated item that applied the effect 
-- when items are deleted and then clears that effect if it's missing.
function checkEffectsAfterDelete(nodeChar)
    local sUser = User.getUsername();
    for _,nodeEffect in pairs(DB.getChildren(nodeChar, "effects")) do
        local sLabel = DB.getValue(nodeEffect, "label", "");
        local sEffSource = DB.getValue(nodeEffect, "source_name", "");
        -- see if the node exists and if it's in an inventory node
        local nodeFound = DB.findNode(sEffSource);
        local bDeleted = ((nodeFound == nil) and string.match(sEffSource,"inventorylist"));
        if (bDeleted) then
            local msg = {font = "msgfont", icon = "roll_effect"};
            msg.text = "Effect ['" .. sLabel .. "'] ";
            msg.text = msg.text .. "removed [from " .. DB.getValue(nodeChar, "name", "") .. "]";
            -- HANDLE APPLIED BY SETTING
            if sEffSource and sEffSource ~= "" then
                msg.text = msg.text .. " [by Deletion]";
            end
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
            nodeEffect.delete();
        end
        
    end
end


function updateItemEffects(nodeItem)
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
    -- if not in the combat tracker bail
    if not nodeChar then
        return;
    end

    local nCarried = DB.getValue(nodeItem, "carried", 0);
    local bEquipped = (nCarried == 2);
    local nIdentified = DB.getValue(nodeItem, "isidentified", 1);
    -- local bOptionID = OptionsManager.isOption("MIID", "on");
    -- if not bOptionID then 
        -- nIdentified = 1;
    -- end

    for _,nodeItemEffect in pairs(DB.getChildren(nodeItem, "effectlist")) do
        updateItemEffect(nodeItemEffect, sName, nodeChar, nil, bEquipped, nIdentified);
    end -- for item's effects list
end

-- update single effect for item
function updateItemEffect(nodeItemEffect, sName, nodeChar, sUser, bEquipped, nIdentified)
  local sCharacterName = DB.getValue(nodeChar, "name", "");
  local sItemSource = nodeItemEffect.getPath();
  local sLabel = DB.getValue(nodeItemEffect, "effect", "");
-- Debug.console("manager_effect_adnd.lua","updateItemEffect","bEquipped",bEquipped);    
-- Debug.console("manager_effect_adnd.lua","updateItemEffect","nodeItemEffect",nodeItemEffect);  
  if sLabel and sLabel ~= "" then -- if we have effect string
    local bFound = false;
    for _,nodeEffect in pairs(DB.getChildren(nodeChar, "effects")) do
      local nActive = DB.getValue(nodeEffect, "isactive", 0);
      local nDMOnly = DB.getValue(nodeEffect, "isgmonly", 0);
      if (nActive ~= 0) then
        local sEffSource = DB.getValue(nodeEffect, "source_name", "");
        if (sEffSource == sItemSource) then
          bFound = true;
          if (not bEquipped) then
            sendEffectRemovedMessage(nodeChar, nodeEffect, sLabel, nDMOnly, sUser)
            nodeEffect.delete();
            break;
          end -- not equipped
        end -- effect source == item source
      end -- was active
    end -- nodeEffect for
      
    if (not bFound and bEquipped) then
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
      if sVisibility == "hide" then
        nDMOnly = 1;
      elseif sVisibility == "show"  then
        nDMOnly = 0;
      elseif nIdentified == 0 then
        nDMOnly = 1;
      elseif nIdentified > 0  then
        nDMOnly = 0;
      end
      
      local isNPC = isCTNodeNPC(nodeChar);            
      if isNPC then
        local bTokenVis = (DB.getValue(nodeChar,"tokenvis",1) == 1);
        if not bTokenVis then
          nDMOnly = 1; -- hide if token not visible
        end
      end
      
      rEffect.nDuration = nRollDuration;
      rEffect.sName = sName .. ";" .. sLabel;
      rEffect.sLabel = sLabel; 
      rEffect.sUnits = DB.getValue(nodeItemEffect, "durunit", "");
      rEffect.nInit = 0;
      rEffect.sSource = sItemSource;
      rEffect.nGMOnly = nDMOnly;
      rEffect.sApply = "";
      
      sendEffectAddedMessage(nodeChar, rEffect, sLabel, nDMOnly, sUser)
      EffectManager.addEffect("", "", nodeChar, rEffect, false);
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
  local sUser = User.getUsername();
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
  local bisPC = (ActorManager.getType(nodeEntry) == "pc");
  if (not bisPC) then
    nDMOnly = 1; -- npcs effects always hidden from PCs/chat when we first drag/drop into CT
  end
  
  local rEffect = {};
  rEffect.nDuration = nRollDuration;
  --rEffect.sName = sName .. ";" .. sLabel;
  rEffect.sName = sLabel;
  rEffect.sLabel = sLabel; 
  rEffect.sUnits = DB.getValue(nodeCharEffect, "durunit", "");
  rEffect.nInit = 0;
  --rEffect.sSource = nodeEntry.getPath();
  rEffect.nGMOnly = nDMOnly;
  rEffect.sApply = "";

  sendEffectAddedMessage(nodeEntry, rEffect, sLabel, nDMOnly, sUser);
  EffectManager.addEffect("", "", nodeEntry, rEffect, false);
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

    -- now flip through inventory and pass each to updateEffects()
    -- so that if they have a combat_effect it will be applied.
    for _,nodeItem in pairs(DB.getChildren(nodePC, "inventorylist")) do
        updateItemEffects(nodeItem,true);
    end
    -- end
    -- check to see if npc effects exists and if so apply --celestian
    updateCharEffects(nodePC,nodeEntry);

    -- make sure active users get ownership of their CT nodes
    -- otherwise effects applied by items/etc won't work.
    --AccessManagerADND.manageCTOwners(nodeEntry);
end

-- copied the base addNPC from manager_combat2.lua from 5E ruleset for this and
-- added the bit that checks for PC effects to add -- celestian
function addNPC(sClass, nodeNPC, sName)
	local nodeEntry, nodeLastMatch = CombatManager.addNPCHelper(nodeNPC, sName);
	
	-- Fill in spells
	CampaignDataManager2.updateNPCSpells(nodeEntry);
	CampaignDataManager2.resetNPCSpellcastingSlots(nodeEntry);
		
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
    updateCharEffects(nodeNPC,nodeEntry);

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

-- get the Connected Player's name that has this identity
function getUserFromNode(node)
  local sNodePath = node.getPath();
  local _, sRecord = DB.getValue(node, "link", "", "");    
  local sUser = nil;
  for _,vUser in ipairs(User.getActiveUsers()) do
    for _,vIdentity in ipairs(User.getActiveIdentities(vUser)) do
      if (sRecord == ("charsheet." .. vIdentity)) then
        sUser = vUser;
        break;
      end
    end
  end
  return sUser;
end

-- build message to send that effect removed
function sendEffectRemovedMessage(nodeChar, nodeEffect, sLabel, nDMOnly)
  local sUser = getUserFromNode(nodeChar);
--Debug.console("manager_effect_adnd.lua","sendEffectRemovedMessage","sUser",sUser);  
  local sCharacterName = DB.getValue(nodeChar, "name", "");
  -- Build output message
  local msg = ChatManager.createBaseMessage(ActorManager.getActorFromCT(nodeChar),sUser);
  msg.text = "Advanced Effect ['" .. sLabel .. "'] ";
  msg.text = msg.text .. "removed [from " .. sCharacterName .. "]";
  -- HANDLE APPLIED BY SETTING
  local sEffSource = DB.getValue(nodeEffect, "source_name", "");    
  if sEffSource and sEffSource ~= "" then
      msg.text = msg.text .. " [by " .. DB.getValue(DB.findNode(sEffSource), "name", "") .. "]";
  end
  sendRawMessage(sUser,nDMOnly,msg);
end
-- build message to send that effect added
function sendEffectAddedMessage(nodeCT, rNewEffect, sLabel, nDMOnly)
  local sUser = getUserFromNode(nodeCT);
--Debug.console("manager_effect_adnd.lua","sendEffectAddedMessage","sUser",sUser);  
	-- Build output message
	local msg = ChatManager.createBaseMessage(ActorManager.getActorFromCT(nodeCT),sUser);
	msg.text = "Advanced Effect ['" .. rNewEffect.sName .. "'] ";
	msg.text = msg.text .. "-> [to " .. DB.getValue(nodeCT, "name", "") .. "]";
	if rNewEffect.sSource and rNewEffect.sSource ~= "" then
		msg.text = msg.text .. " [by " .. DB.getValue(DB.findNode(rNewEffect.sSource), "name", "") .. "]";
	end
    sendRawMessage(sUser,nDMOnly,msg);
end

-- send message
function sendRawMessage(sUser, nDMOnly, msg)
  local sIdentity = nil;
  if sUser and sUser ~= "" then 
    sIdentity = User.getCurrentIdentity(sUser) or nil;
  end
  if sIdentity then
    msg.icon = "portrait_" .. User.getCurrentIdentity(sUser) .. "_chat";
  else
    msg.font = "msgfont";
    msg.icon = "roll_effect";
  end
  if nDMOnly == 1 then
    msg.secret = true;
    Comm.addChatMessage(msg);
  elseif nDMOnly ~= 1 then 
    --Comm.addChatMessage(msg);
    Comm.deliverChatMessage(msg);
  end
end


-- pass effect to here to see if the effect is being triggered
-- by an item and if so if it's valid
function isValidCheckEffect(rActor,nodeEffect)
    local bResult = false;
    local nActive = DB.getValue(nodeEffect, "isactive", 0);
    local bItem = false;
    local bActionItemUsed = false;
    local bActionOnly = false;
    local nodeItem = nil;

    local sSource = DB.getValue(nodeEffect,"source_name","");
    -- if source is a valid node and we can find "actiononly"
    -- setting then we set it.
    local node = DB.findNode(sSource);
    if (node and node ~= nil) then
        nodeItem = node.getChild("...");
        if nodeItem and nodeItem ~= nil then
            bActionOnly = (DB.getValue(node,"actiononly",0) ~= 0);
        end
    end

    -- if there is a itemPath do some sanity checking
    if (rActor.itemPath and rActor.itemPath ~= "") then 
        -- here is where we get the node path of the item, not the 
        -- effectslist entry
        if ((DB.findNode(rActor.itemPath) ~= nil)) then
            if (node and node ~= nil and nodeItem and nodeItem ) then
                local sNodePath = nodeItem.getPath();
                if bActionOnly and sNodePath ~= "" and (sNodePath == rActor.itemPath) then
                    bActionItemUsed = true;
                    bItem = true;
                else
                    bActionItemUsed = false;
                    bItem = true; -- is item but doesn't match source path for this effect
                end
            end
        end
    end
    if nActive ~= 0 and bActionOnly and bActionItemUsed then
        bResult = true;
    elseif nActive ~= 0 and not bActionOnly and bActionItemUsed then
        bResult = true;
    elseif nActive ~= 0 and bActionOnly and not bActionItemUsed then
        bResult = false;
    elseif nActive ~= 0 then
        bResult = true;
    end
    return bResult;
end



--
--          REPLACEMENT FUNCTIONS
--



-- replace 5E EffectManager5E manager_effect_5E.lua evalAbilityHelper() with this
-- AD&D CORE ONLY
function evalAbilityHelper(rActor, sEffectAbility)
	-- local sSign, sModifier, sShortAbility = sEffectAbility:match("^%[([%+%-]?)([H2]?)([A-Z][A-Z][A-Z])%]$");
	
	-- local nAbility = nil;
	-- if sShortAbility == "STR" then
		-- nAbility = ActorManager2.getAbilityBonus(rActor, "strength");
	-- elseif sShortAbility == "DEX" then
		-- nAbility = ActorManager2.getAbilityBonus(rActor, "dexterity");
	-- elseif sShortAbility == "CON" then
		-- nAbility = ActorManager2.getAbilityBonus(rActor, "constitution");
	-- elseif sShortAbility == "INT" then
		-- nAbility = ActorManager2.getAbilityBonus(rActor, "intelligence");
	-- elseif sShortAbility == "WIS" then
		-- nAbility = ActorManager2.getAbilityBonus(rActor, "wisdom");
	-- elseif sShortAbility == "CHA" then
		-- nAbility = ActorManager2.getAbilityBonus(rActor, "charisma");
	-- elseif sShortAbility == "LVL" then
		-- nAbility = ActorManager2.getAbilityBonus(rActor, "level");
	-- elseif sShortAbility == "PRF" then
		-- nAbility = ActorManager2.getAbilityBonus(rActor, "prf");
	-- end
	
	-- if nAbility then
		-- if sSign == "-" then
			-- nAbility = 0 - nAbility;
		-- end
		-- if sModifier == "H" then
			-- if nAbility > 0 then
				-- nAbility = math.floor(nAbility / 2);
			-- else
				-- nAbility = math.ceil(nAbility / 2);
			-- end
		-- elseif sModifier == "2" then
			-- nAbility = nAbility * 2;
		-- end
	-- end
	
	-- return nAbility;
    return 0;
end

-- replace CoreRPG ActionsManager manager_actions.lua decodeActors() with this
function decodeActors(draginfo)
	local rSource = nil;
	local aTargets = {};
    
	
	for k,v in ipairs(draginfo.getShortcutList()) do
		if k == 1 then
			rSource = ActorManager.getActor(v.class, v.recordname);
		else
			local rTarget = ActorManager.getActor(v.class, v.recordname);
			if rTarget then
				table.insert(aTargets, rTarget);
			end
		end
	end

    -- itemPath data filled if itemPath if exists
    local sItemPath = draginfo.getMetaData("itemPath");
    if (sItemPath and sItemPath ~= "") then
        rSource.itemPath = sItemPath;
    end
    --
    
	return rSource, aTargets;
end

-- replace 5E EffectManager5E manager_effect_5E.lua getEffectsByType() with this
function getEffectsByType(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly)
	if not rActor then
		return {};
	end
	local results = {};
	
	-- Set up filters
	local aRangeFilter = {};
	local aOtherFilter = {};
	if aFilter then
		for _,v in pairs(aFilter) do
			if type(v) ~= "string" then
				table.insert(aOtherFilter, v);
			elseif StringManager.contains(DataCommon.rangetypes, v) then
				table.insert(aRangeFilter, v);
			else
				table.insert(aOtherFilter, v);
			end
		end
	end
	
	-- Determine effect type targeting
	local bTargetSupport = StringManager.isWord(sEffectType, DataCommon.targetableeffectcomps);
	
	-- Iterate through effects
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		-- Check active
		local nActive = DB.getValue(v, "isactive", 0);
		--if ( nActive ~= 0 and ( not bItemTriggered or (bItemTriggered and bItemSource) ) ) then
        if (EffectManagerADND.isValidCheckEffect(rActor,v)) then
			local sLabel = DB.getValue(v, "label", "");
			local sApply = DB.getValue(v, "apply", "");

			-- IF COMPONENT WE ARE LOOKING FOR SUPPORTS TARGETS, THEN CHECK AGAINST OUR TARGET
			local bTargeted = EffectManager.isTargetedEffect(v);
			if not bTargeted or EffectManager.isEffectTarget(v, rFilterActor) then
				local aEffectComps = EffectManager.parseEffect(sLabel);

				-- Look for type/subtype match
				local nMatch = 0;
				for kEffectComp,sEffectComp in ipairs(aEffectComps) do
					local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);
					-- Handle conditionals
					if rEffectComp.type == "IF" then
						if not EffectManager5E.checkConditional(rActor, v, rEffectComp.remainder) then
							break;
						end
					elseif rEffectComp.type == "IFT" then
						if not rFilterActor then
							break;
						end
						if not EffectManager5E.checkConditional(rFilterActor, v, rEffectComp.remainder, rActor) then
							break;
						end
						bTargeted = true;
					
					-- Compare other attributes
					else
						-- Strip energy/bonus types for subtype comparison
						local aEffectRangeFilter = {};
						local aEffectOtherFilter = {};
						local j = 1;
						while rEffectComp.remainder[j] do
							local s = rEffectComp.remainder[j];
							if #s > 0 and ((s:sub(1,1) == "!") or (s:sub(1,1) == "~")) then
								s = s:sub(2);
							end
							if StringManager.contains(DataCommon.dmgtypes, s) or s == "all" or 
									StringManager.contains(DataCommon.bonustypes, s) or
									StringManager.contains(DataCommon.conditions, s) or
									StringManager.contains(DataCommon.connectors, s) then
								-- SKIP
							elseif StringManager.contains(DataCommon.rangetypes, s) then
								table.insert(aEffectRangeFilter, s);
							else
								table.insert(aEffectOtherFilter, s);
							end
							
							j = j + 1;
						end
					
						-- Check for match
						local comp_match = false;
						if rEffectComp.type == sEffectType then

							-- Check effect targeting
							if bTargetedOnly and not bTargeted then
								comp_match = false;
							else
								comp_match = true;
							end
						
							-- Check filters
							if #aEffectRangeFilter > 0 then
								local bRangeMatch = false;
								for _,v2 in pairs(aRangeFilter) do
									if StringManager.contains(aEffectRangeFilter, v2) then
										bRangeMatch = true;
										break;
									end
								end
								if not bRangeMatch then
									comp_match = false;
								end
							end
							if #aEffectOtherFilter > 0 then
								local bOtherMatch = false;
								for _,v2 in pairs(aOtherFilter) do
									if type(v2) == "table" then
										local bOtherTableMatch = true;
										for k3, v3 in pairs(v2) do
											if not StringManager.contains(aEffectOtherFilter, v3) then
												bOtherTableMatch = false;
												break;
											end
										end
										if bOtherTableMatch then
											bOtherMatch = true;
											break;
										end
									elseif StringManager.contains(aEffectOtherFilter, v2) then
										bOtherMatch = true;
										break;
									end
								end
								if not bOtherMatch then
									comp_match = false;
								end
							end
						end

						-- Match!
						if comp_match then
							nMatch = kEffectComp;
							if nActive == 1 then
								table.insert(results, rEffectComp);
							end
						end
					end
				end -- END EFFECT COMPONENT LOOP

				-- Remove one shot effects
				if nMatch > 0 then
					if nActive == 2 then
						DB.setValue(v, "isactive", "number", 1);
					else
						if sApply == "action" then
							EffectManager.notifyExpire(v, 0);
						elseif sApply == "roll" then
							EffectManager.notifyExpire(v, 0, true);
						elseif sApply == "single" then
							EffectManager.notifyExpire(v, nMatch, true);
						end
					end
				end
			end -- END TARGET CHECK
		end  -- END ACTIVE CHECK
	end  -- END EFFECT LOOP
	
	-- RESULTS
	return results;
end

-- replace 5E EffectManager5E manager_effect_5E.lua hasEffect() with this
function hasEffect(rActor, sEffect, rTarget, bTargetedOnly, bIgnoreEffectTargets)
	if not sEffect or not rActor then
		return false;
	end
	local sLowerEffect = sEffect:lower();
	
	-- Iterate through each effect
	local aMatch = {};
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);
        if (EffectManagerADND.isValidCheckEffect(rActor,v)) then
			-- Parse each effect label
			local sLabel = DB.getValue(v, "label", "");
			local bTargeted = EffectManager.isTargetedEffect(v);
			local aEffectComps = EffectManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			local nMatch = 0;
			for kEffectComp,sEffectComp in ipairs(aEffectComps) do
				local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);
				-- Handle conditionals
				if rEffectComp.type == "IF" then
					if not EffectManager5E.checkConditional(rActor, v, rEffectComp.remainder) then
						break;
					end
				elseif rEffectComp.type == "IFT" then
					if not rTarget then
						break;
					end
					if not EffectManager5E.checkConditional(rTarget, v, rEffectComp.remainder, rActor) then
						break;
					end
				
				-- Check for match
				elseif rEffectComp.original:lower() == sLowerEffect then
					if bTargeted and not bIgnoreEffectTargets then
						if EffectManager.isEffectTarget(v, rTarget) then
							nMatch = kEffectComp;
						end
					elseif not bTargetedOnly then
						nMatch = kEffectComp;
					end
				end
				
			end
			
			-- If matched, then remove one-off effects
			if nMatch > 0 then
				if nActive == 2 then
					DB.setValue(v, "isactive", "number", 1);
				else
					table.insert(aMatch, v);
					local sApply = DB.getValue(v, "apply", "");
					if sApply == "action" then
						EffectManager.notifyExpire(v, 0);
					elseif sApply == "roll" then
						EffectManager.notifyExpire(v, 0, true);
					elseif sApply == "single" then
						EffectManager.notifyExpire(v, nMatch, true);
					end
				end
			end
		end
	end
	
	if #aMatch > 0 then
		return true;
	end
	return false;
end

-- replace 5E EffectManager5E manager_effect_5E.lua checkConditionalHelper() with this
function checkConditionalHelper(rActor, sEffect, rTarget, aIgnore)
	if not rActor then
		return false;
	end
	
	local bReturn = false;
	
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);
    if (EffectManagerADND.isValidCheckEffect(rActor,v) and not StringManager.contains(aIgnore, v.getNodeName())) then
			-- Parse each effect label
			local sLabel = DB.getValue(v, "label", "");
			local bTargeted = EffectManager.isTargetedEffect(v);
			local aEffectComps = EffectManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			local nMatch = 0;
			for kEffectComp, sEffectComp in ipairs(aEffectComps) do
				local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);
				-- CHECK FOR FOLLOWON EFFECT TAGS, AND IGNORE THE REST
				if rEffectComp.type == "AFTER" or rEffectComp.type == "FAIL" then
					break;
				
				-- CHECK CONDITIONALS
				elseif rEffectComp.type == "IF" then
					if not EffectManager5E.checkConditional(rActor, v, rEffectComp.remainder, nil, aIgnore) then
						break;
					end
				elseif rEffectComp.type == "IFT" then
					if not rTarget then
						break;
					end
					if not EffectManager5E.checkConditional(rTarget, v, rEffectComp.remainder, rActor, aIgnore) then
						break;
					end
				
				-- CHECK FOR AN ACTUAL EFFECT MATCH
				elseif rEffectComp.original:lower() == sEffect then
					if bTargeted then
						if EffectManager.isEffectTarget(v, rTarget) then
							bReturn = true;
						end
					else
						bReturn = true;
					end
				end
			end
		end
	end
	
	return bReturn;
end

-- replace 5E ActionDamage manager_action_damage.lua performRoll() with this
-- extension only
function manager_action_damage_performRoll(draginfo, rActor, rAction)
	local rRoll = ActionDamage.getRoll(rActor, rAction);

    if (draginfo and rActor.itemPath and rActor.itemPath ~= "") then
        draginfo.setMetaData("itemPath",rActor.itemPath);
    end
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

-- replace 5E ActionAttack manager_action_attack.lua performRoll() with this
-- extension only
function manager_action_attack_performRoll(draginfo, rActor, rAction)
	local rRoll = ActionAttack.getRoll(rActor, rAction);

    if (draginfo and rActor.itemPath and rActor.itemPath ~= "") then
        draginfo.setMetaData("itemPath",rActor.itemPath);
    end
    
	ActionsManager.performAction(draginfo, rActor, rRoll);
end


-- replace 5E PowerManager manager_power.lua performAction() with this
-- extension only
function manager_power_performAction(draginfo, rActor, rAction, nodePower)
	if not rActor or not rAction then
		return false;
	end
	
    -- add itemPath to rActor so that when effects are checked we can 
    -- make compare against action only effects
    local nodeWeapon = nodePower.getChild("...");
    local _, sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
	rActor.itemPath = sRecord;
    if (draginfo and rActor.itemPath and rActor.itemPath ~= "") then
        draginfo.setMetaData("itemPath",rActor.itemPath);
    end
    --

	PowerManager.evalAction(rActor, nodePower, rAction);

	local rRolls = {};
	if rAction.type == "cast" then
		rAction.subtype = (rAction.subtype or "");
		if rAction.subtype == "" then
			table.insert(rRolls, ActionPower.getPowerCastRoll(rActor, rAction));
		end
		if ((rAction.subtype == "") or (rAction.subtype == "atk")) and rAction.range then
			table.insert(rRolls, ActionAttack.getRoll(rActor, rAction));
		end
		if ((rAction.subtype == "") or (rAction.subtype == "save")) and ((rAction.save or "") ~= "") then
			table.insert(rRolls, ActionPower.getSaveVsRoll(rActor, rAction));
		end
	
	elseif rAction.type == "attack" then
		table.insert(rRolls, ActionAttack.getRoll(rActor, rAction));
		
	elseif rAction.type == "powersave" then
		table.insert(rRolls, ActionPower.getSaveVsRoll(rActor, rAction));

	elseif rAction.type == "damage" then
		table.insert(rRolls, ActionDamage.getRoll(rActor, rAction));
		
	elseif rAction.type == "heal" then
		table.insert(rRolls, ActionHeal.getRoll(rActor, rAction));
		
	elseif rAction.type == "effect" then
		local rRoll = ActionEffect.getRoll(draginfo, rActor, rAction);
		if rRoll then
			table.insert(rRolls, rRoll);
		end
	end
	
	if #rRolls > 0 then
		ActionsManager.performMultiAction(draginfo, rActor, rRolls[1].sType, rRolls);
	end
	return true;
end

-- return boolean, is NPC from CT node test
function isCTNodeNPC(nodeCT)
  local isPC = false;
  local sClassLink, sRecordLink = DB.getValue(nodeCT,"link","","");
  if sClassLink == 'npc' then
    isPC = true;
  end
  return isPC;
end
