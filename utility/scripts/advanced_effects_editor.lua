--
--
--
--

function onInit()
    local node = getDatabaseNode();
    DB.getValue(node,"save_type","modifier");
    DB.addHandler(DB.getPath(node, ".type"),"onUpdate", update);
    DB.addHandler(DB.getPath(node, ".save_type"), "onUpdate", updateSaveEffects);
    DB.addHandler(DB.getPath(node, ".save"), "onUpdate", updateSaveEffects);
    DB.addHandler(DB.getPath(node, ".save_modifier"), "onUpdate", updateSaveEffects);

    DB.addHandler(DB.getPath(node, ".ability_type"), "onUpdate", updateAbilityEffects);
    DB.addHandler(DB.getPath(node, ".ability"), "onUpdate", updateAbilityEffects);
    DB.addHandler(DB.getPath(node, ".ability_modifier"), "onUpdate", updateAbilityEffects);

    DB.addHandler(DB.getPath(node, ".susceptiblity_type"), "onUpdate", updateSusceptibleEffects);
    DB.addHandler(DB.getPath(node, ".susceptiblity"), "onUpdate", updateSusceptibleEffects);
    DB.addHandler(DB.getPath(node, ".susceptiblity_modifier"), "onUpdate", updateSusceptibleEffects);

    DB.addHandler(DB.getPath(node, ".misc_type"), "onUpdate", updateMiscEffects);
    DB.addHandler(DB.getPath(node, ".misc_modifier"), "onUpdate", updateMiscEffects);
    update();
end

function onClose()
    local node = getDatabaseNode();
    DB.removeHandler(DB.getPath(node, ".type"),"onUpdate", update);
    DB.removeHandler(DB.getPath(node, ".save_type"), "onUpdate", updateSaveEffects);
    DB.removeHandler(DB.getPath(node, ".save"), "onUpdate", updateSaveEffects);
    DB.removeHandler(DB.getPath(node, ".save_modifier"), "onUpdate", updateSaveEffects);

    DB.removeHandler(DB.getPath(node, ".ability_type"), "onUpdate", updateAbilityEffects);
    DB.removeHandler(DB.getPath(node, ".ability"), "onUpdate", updateAbilityEffects);
    DB.removeHandler(DB.getPath(node, ".ability_modifier"), "onUpdate", updateAbilityEffects);
    
    DB.removeHandler(DB.getPath(node, ".susceptiblity_type"), "onUpdate", updateSusceptibleEffects);
    DB.removeHandler(DB.getPath(node, ".susceptiblity"), "onUpdate", updateSusceptibleEffects);
    DB.removeHandler(DB.getPath(node, ".susceptiblity_modifier"), "onUpdate", updateSusceptibleEffects);

    DB.removeHandler(DB.getPath(node, ".misc_type"), "onUpdate", updateMiscEffects);
    DB.removeHandler(DB.getPath(node, ".misc_modifier"), "onUpdate", updateMiscEffects);
end

function update()
    local node = getDatabaseNode();
    local sType = DB.getValue(node,"type","");
--  <values>save|ability|resist|immune|vulnerable</values>
    local bCustom = (sType == "");
    local bSave = (sType == "save");
    local bAbility = (sType == "ability");
    local bSusceptiblity = (sType == "susceptiblity");
    local bMisc = (sType == "misc");
    
    local w = Interface.findWindow("advanced_effect_editor", "");
--Debug.console("advanced_effects_editor.lua","update","save",save);
    
    if (bSave) then
        -- save
        save_type.setVisible(true);
        save.setComboBoxVisible(true);
        --save.setVisible(true);
        save_modifier.setVisible(true);
        updateSaveEffects();
    else
        save_type.setVisible(false);
        save.setComboBoxVisible(false);
        --save.setVisible(false);
        save_modifier.setVisible(false);
    end
    
    if (bAbility) then
        -- ability
        ability_type.setVisible(true);
        ability.setVisible(true);
        ability_modifier.setVisible(true);
        updateAbilityEffects();
    else
        ability_type.setVisible(false);
        ability.setVisible(false);
        ability_modifier.setVisible(false);
    end
    
    if (bSusceptiblity) then
        -- bSusceptiblity
        susceptiblity_type.setVisible(true);
        susceptiblity.setComboBoxVisible(true);
        --susceptiblity.setVisible(true);
        -- we dont use modifier yet? hiding
        susceptiblity_modifier.setVisible(false);
        updateSusceptibleEffects();
    else
        susceptiblity_type.setVisible(false);
        susceptiblity.setComboBoxVisible(false);
        --susceptiblity.setVisible(false);
        susceptiblity_modifier.setVisible(false);
    end
    
    if (bMisc) then
        -- bMisc
        misc_type.setVisible(true);
        misc_modifier.setVisible(true);
        updateMiscEffects();
    else
        misc_type.setVisible(false);
        misc_modifier.setVisible(false);
    end

    -- custom 
    if (bCustom) then
        -- custom 
        effect.setVisible(true);
    else
        effect.setVisible(false);
    end
    
end


function updateAbilityEffects()
    if not User.isHost() then
        return;
    end
    
    local nodeRecord = getDatabaseNode();
    local sEffectString = "";
    local sType = DB.getValue(nodeRecord,"ability_type","");
    local sAbility = DB.getValue(nodeRecord,"ability","str");
    local nModifier = DB.getValue(nodeRecord,"ability_modifier",0);
    local sTypeChar = "";
    
    if (sType == "modifier") or (sType == "") then
        sTypeChar = "";
    elseif (sType == "percent_modifier") then
        sTypeChar = "P";
    elseif (sType == "base") then 
        sTypeChar = "B";
    elseif (sType == "base_percent") then
        sTypeChar = "BP";
    end

    if (sAbility == "") then 
        sAbility = "str";
    end
-- Debug.console("advanced_effects_editor.lua","updateAbilityEffects","sType",sType);
-- Debug.console("advanced_effects_editor.lua","updateAbilityEffects","sAbility",sAbility);
-- Debug.console("advanced_effects_editor.lua","updateAbilityEffects","nModifier",nModifier);
    
    if (sAbility ~= "") then
        sEffectString = sEffectString .. sTypeChar .. sAbility:upper() .. ": " .. nModifier .. ";";
    end
    DB.setValue(nodeRecord,"effect","string",sEffectString);
end

function updateSaveEffects()
    if not User.isHost() then
        return;
    end
    local nodeRecord = getDatabaseNode();
--Debug.console("advanced_effects_editor.lua","updatesaveEffects","nodeRecord",nodeRecord);
    local sEffectString = "";
    local sType = DB.getValue(nodeRecord,"save_type","");
    local sSave = DB.getValue(nodeRecord,"save","");
    local nModifier = DB.getValue(nodeRecord,"save_modifier",0);
    local sTypeChar = "";
    
    if (sType == "modifier") or (sType == "") then
        sTypeChar = "";
    elseif (sType == "base") then 
        sTypeChar = "B";
    end
    
-- Debug.console("advanced_effects_editor.lua","updatesaveEffects","sType",sType);
-- Debug.console("advanced_effects_editor.lua","updatesaveEffects","sSave",sSave);
-- Debug.console("advanced_effects_editor.lua","updatesaveEffects","nModifier",nModifier);
    if (sSave ~= "") then
        sEffectString = sEffectString .. sTypeChar .. sSave:upper() .. ": " .. nModifier .. ";";
    end
    DB.setValue(nodeRecord,"effect","string",sEffectString);
end

function updateSusceptibleEffects()
    if not User.isHost() then
        return;
    end
    local nodeRecord = getDatabaseNode();
--Debug.console("advanced_effects_editor.lua","updateSusceptibleEffects","nodeRecord",nodeRecord);
    local sEffectString = "";
    local sType = DB.getValue(nodeRecord,"susceptiblity_type","");
    local sSuscept = DB.getValue(nodeRecord,"susceptiblity","");
    local nModifier = DB.getValue(nodeRecord,"susceptiblity_modifier",0);
    local sTypeChar = "";
    
    if (sType == "") then
        sType = "immune";
    end
    if (sSuscept == "") then
        sSuscept = "acid";
    end
    
--Debug.console("advanced_effects_editor.lua","updateSusceptibleEffects","sType",sType);
--Debug.console("advanced_effects_editor.lua","updateSusceptibleEffects","sSuscept",sSuscept);
--Debug.console("advanced_effects_editor.lua","updateSusceptibleEffects","nModifier",nModifier);
    if (sSuscept ~= "") then
        sEffectString = sEffectString .. sType:upper() .. ": " .. sSuscept .. ";";
    end
    DB.setValue(nodeRecord,"effect","string",sEffectString);
end

function updateMiscEffects()
    if not User.isHost() then
        return;
    end
    local nodeRecord = getDatabaseNode();
--Debug.console("advanced_effects_editor.lua","updateMiscEffects","nodeRecord",nodeRecord);
    local sEffectString = "";
    local sType = DB.getValue(nodeRecord,"misc_type","");
    --local sSuscept = DB.getValue(nodeRecord,"susceptiblity","");
    local nModifier = DB.getValue(nodeRecord,"misc_modifier",0);
    local sTypeChar = "";
    
    if (sType == "") then
        sType = "ac";
    end
    
--Debug.console("advanced_effects_editor.lua","updateMiscEffects","sType",sType);
--Debug.console("advanced_effects_editor.lua","updateMiscEffects","sSuscept",sSuscept);
--Debug.console("advanced_effects_editor.lua","updateMiscEffects","nModifier",nModifier);
    if (nModifier ~= 0) then
        sEffectString = sEffectString .. sType:upper() .. ": " .. nModifier .. ";";
    end
    DB.setValue(nodeRecord,"effect","string",sEffectString);
end
