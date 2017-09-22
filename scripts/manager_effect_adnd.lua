
--
-- Effects on Items, apply to character in CT
--
--
-- add the effect if the item is equipped and doesn't exist already
function updateItemEffects(nodeItem)
    local nodeChar = DB.getChild(nodeItem, "...");
    if not nodeChar then
        return;
    end
    local sUser = User.getUsername();
    local sName = DB.getValue(nodeItem, "name", "");
    local sLabel = DB.getValue(nodeItem, "effect", "");
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
    local sItemSource = nodeItem.getPath();
    local nIdentified = DB.getValue(nodeItem, "isidentified", 0);
    local sCharacterName = DB.getValue(nodeChar, "name", "");
 -- Debug.console("manager_effect_adnd.lua","updateItemEffects","nodeChar",nodeChar);
 -- Debug.console("manager_effect_adnd.lua","updateItemEffects","nodeItem",nodeItem);
 -- Debug.console("manager_effect_adnd.lua","updateItemEffects","sName",sName);
 -- Debug.console("manager_effect_adnd.lua","updateItemEffects","sLabel",sLabel);
 -- Debug.console("manager_effect_adnd.lua","updateItemEffects","nCarried",nCarried);
 -- Debug.console("manager_effect_adnd.lua","updateItemEffects","bEquipped",bEquipped);
 -- Debug.console("manager_effect_adnd.lua","updateItemEffects","sItemSource",sItemSource);
 -- Debug.console("manager_effect_adnd.lua","updateItemEffects","nIdentified",nIdentified);
    if sLabel and sLabel ~= "" then -- if we have effect string
        local bFound = false;
        for _,nodeEffect in pairs(DB.getChildren(nodeChar, "effects")) do
            local nActive = DB.getValue(nodeEffect, "isactive", 0);
            if (nActive ~= 0) then
                local sEffSource = DB.getValue(nodeEffect, "source_name", "");
                if (sEffSource == sItemSource) then
                    bFound = true;
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
                    
                        nodeEffect.delete();
                        break;
                    end -- not equipped
                end -- effect source == item source
            end -- was active
        end -- nodeEffect for
        
        if (not bFound and bEquipped) then
            local rEffect = {};
            rEffect.sName = sName .. ";" .. sLabel;
            rEffect.sLabel = sLabel; 
            rEffect.nDuration = 0;
            rEffect.sUnits = "day";
            rEffect.nInit = 0;
            rEffect.sSource = sItemSource;
            rEffect.nGMOnly = nIdentified;
            rEffect.sApply = "";        
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
