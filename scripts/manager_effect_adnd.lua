--
-- Effects on Items, apply to character in CT
--
--
-- add the effect if the item is equipped and doesn't exist already
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


-- flip through all npc effects (generally do this in addNPC()
-- nodeNPC: node of NPC in NPCs record list
-- nodeEntry: node in combat tracker for NPC
function updateNPCEffects(nodeNPC,nodeEntry)
    for _,nodeNPCEffect in pairs(DB.getChildren(nodeNPC, "effectlist")) do
        updateNPCEffect(nodeNPCEffect,nodeEntry);
    end -- for item's effects list 
end
-- this will be used to manage NPC effectslist objects
-- nodeNPCEffect: node in effectlist on NPC
-- nodeEntry: node in combat tracker for NPC
function updateNPCEffect(nodeNPCEffect,nodeEntry)
    local sName = DB.getValue(nodeEntry, "name", "");
    local sLabel = DB.getValue(nodeNPCEffect, "effect", "");
    local nRollDuration = 0;
    local dDurationDice = DB.getValue(nodeNPCEffect, "durdice");
    local nModDice = DB.getValue(nodeNPCEffect, "durmod", 0);
    if (dDurationDice and dDurationDice ~= "") then
        nRollDuration = StringManager.evalDice(dDurationDice, nModDice);
    else
        nRollDuration = nModDice;
    end
    local nDMOnly = 0;
    local sVisibility = DB.getValue(nodeNPCEffect, "visibility", "");
    if sVisibility == "show" then
        nDMOnly = 0;
    elseif sVisibility == "hide" then
        nDMOnly = 1;
    end
    local rEffect = {};
    rEffect.nDuration = nRollDuration;
    --rEffect.sName = sName .. ";" .. sLabel;
    rEffect.sName = sLabel;
    rEffect.sUnits = DB.getValue(nodeNPCEffect, "durunit", "day");
    rEffect.nInit = 0;
    --rEffect.sSource = nodeEntry.getPath();
    rEffect.nGMOnly = nDMOnly;
    rEffect.sApply = "";
    EffectManager.addEffect("", "", nodeEntry, rEffect, true);
end
