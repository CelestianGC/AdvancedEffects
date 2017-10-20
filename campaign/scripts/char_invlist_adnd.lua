-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sortLocked = false;

function setSortLock(isLocked)
	sortLocked = isLocked;
end

function onInit()
	OptionsManager.registerCallback("MIID", StateChanged);

	onEncumbranceChanged();

	registerMenuItem(Interface.getString("list_menu_createitem"), "insert", 5);

	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "*.isidentified"), "onUpdate", onIDChanged);
	DB.addHandler(DB.getPath(node, "*.bonus"), "onUpdate", onBonusChanged);
	DB.addHandler(DB.getPath(node, "*.ac"), "onUpdate", onArmorChanged);
	DB.addHandler(DB.getPath(node, "*.dexbonus"), "onUpdate", onArmorChanged);
	DB.addHandler(DB.getPath(node, "*.stealth"), "onUpdate", onArmorChanged);
	DB.addHandler(DB.getPath(node, "*.strength"), "onUpdate", onArmorChanged);
	DB.addHandler(DB.getPath(node, "*.carried"), "onUpdate", onCarriedChanged);
	DB.addHandler(DB.getPath(node, "*.weight"), "onUpdate", onEncumbranceChanged);
	DB.addHandler(DB.getPath(node, "*.count"), "onUpdate", onEncumbranceChanged);
	DB.addHandler(DB.getPath(node, "*.effectlist.*.effect"), "onUpdate", updateItemEffectsForEdit);
	DB.addHandler(DB.getPath(node, "*.effectlist.*.durdice"), "onUpdate", updateItemEffectsForEdit);
	DB.addHandler(DB.getPath(node, "*.effectlist.*.durmod"), "onUpdate", updateItemEffectsForEdit);
	DB.addHandler(DB.getPath(node, "*.effectlist.*.name"), "onUpdate", updateItemEffectsForEdit);
	DB.addHandler(DB.getPath(node, "*.effectlist.*.durunit"), "onUpdate", updateItemEffectsForEdit);
	DB.addHandler(DB.getPath(node, "*.effectlist.*.visibility"), "onUpdate", updateItemEffectsForEdit);
	DB.addHandler(DB.getPath(node, "*.effectlist.*.actiononly"), "onUpdate", updateItemEffectsForEdit);
	DB.addHandler(DB.getPath(node), "onChildDeleted", updateFromDeletedInventory);
end

function onClose()
	OptionsManager.unregisterCallback("MIID", StateChanged);

	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "*.isidentified"), "onUpdate", onIDChanged);
	DB.removeHandler(DB.getPath(node, "*.bonus"), "onUpdate", onBonusChanged);
	DB.removeHandler(DB.getPath(node, "*.ac"), "onUpdate", onArmorChanged);
	DB.removeHandler(DB.getPath(node, "*.dexbonus"), "onUpdate", onArmorChanged);
	DB.removeHandler(DB.getPath(node, "*.stealth"), "onUpdate", onArmorChanged);
	DB.removeHandler(DB.getPath(node, "*.strength"), "onUpdate", onArmorChanged);
	DB.removeHandler(DB.getPath(node, "*.carried"), "onUpdate", onCarriedChanged);
	DB.removeHandler(DB.getPath(node, "*.weight"), "onUpdate", onEncumbranceChanged);
	DB.removeHandler(DB.getPath(node, "*.count"), "onUpdate", onEncumbranceChanged);
	DB.removeHandler(DB.getPath(node, "*.effectlist.*.effect"), "onUpdate", updateItemEffectsForEdit);
	DB.removeHandler(DB.getPath(node, "*.effectlist.*.durdice"), "onUpdate", updateItemEffectsForEdit);
	DB.removeHandler(DB.getPath(node, "*.effectlist.*.durmod"), "onUpdate", updateItemEffectsForEdit);
	DB.removeHandler(DB.getPath(node, "*.effectlist.*.name"), "onUpdate", updateItemEffectsForEdit);
	DB.removeHandler(DB.getPath(node, "*.effectlist.*.durunit"), "onUpdate", updateItemEffectsForEdit);
	DB.removeHandler(DB.getPath(node, "*.effectlist.*.visibility"), "onUpdate", updateItemEffectsForEdit);
	DB.removeHandler(DB.getPath(node, "*.effectlist.*.actiononly"), "onUpdate", updateItemEffectsForEdit);
	DB.removeHandler(DB.getPath(node), "onChildDeleted", updateFromDeletedInventory);
end

function onMenuSelection(selection)
	if selection == 5 then
		addEntry(true);
	end
end

function StateChanged()
	for _,w in ipairs(getWindows()) do
		w.onIDChanged();
	end
	applySort();
end

function onIDChanged(nodeField)
	local nodeItem = DB.getChild(nodeField, "..");
	if (DB.getValue(nodeItem, "carried", 0) == 2) and ItemManager2.isArmor(nodeItem) then
		CharManager.calcItemArmorClass(DB.getChild(nodeItem, "..."));
	end
end

function onBonusChanged(nodeField)
	local nodeItem = DB.getChild(nodeField, "..");
	if (DB.getValue(nodeItem, "carried", 0) == 2) and ItemManager2.isArmor(nodeItem) then
		CharManager.calcItemArmorClass(DB.getChild(nodeItem, "..."));
	end
end

function onArmorChanged(nodeField)
	local nodeItem = DB.getChild(nodeField, "..");
	if (DB.getValue(nodeItem, "carried", 0) == 2) and ItemManager2.isArmor(nodeItem) then
		CharManager.calcItemArmorClass(DB.getChild(nodeItem, "..."));
	end
end

function onCarriedChanged(nodeField)
	local nodeChar = DB.getChild(nodeField, "....");
	if nodeChar then
		local nodeItem = DB.getChild(nodeField, "..");

		local nCarried = nodeField.getValue();
		local sCarriedItem = ItemManager.getDisplayName(nodeItem);
		if sCarriedItem ~= "" then
			for _,vNode in pairs(DB.getChildren(nodeChar, "inventorylist")) do
				if vNode ~= nodeItem then
					local sLoc = DB.getValue(vNode, "location", "");
					if sLoc == sCarriedItem then
						DB.setValue(vNode, "carried", "number", nCarried);
					end
				end
			end
		end
		
		if ItemManager2.isArmor(nodeItem) then
			CharManager.calcItemArmorClass(nodeChar);
		end
	end
	
    updateItemEffects(nodeField);
	onEncumbranceChanged();
end

function onEncumbranceChanged()
	if CharManager.updateEncumbrance then
		CharManager.updateEncumbrance(window.getDatabaseNode());
	end
end

function onListChanged()
	update();
	updateContainers();
end

function update()
	local bEditMode = (window.parentcontrol.window.inventory_iedit.getValue() == 1);
	for _,w in ipairs(getWindows()) do
		w.idelete.setVisibility(bEditMode);
	end
end

function addEntry(bFocus)
	local w = createWindow();
	if w then
		w.isidentified.setValue(1);
		if bFocus then
			w.name.setFocus();
		end
	end
	return w;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if not getNextWindow(nil) then
		addEntry(true);
	end
	return true;
end

function onSortCompare(w1, w2)
	if sortLocked then
		return false;
	end
	return ItemManager.onInventorySortCompare(w1, w2);
end

function updateContainers()
	ItemManager.onInventorySortUpdate(self);
end

function onDrop(x, y, draginfo)
	return ItemManager.handleAnyDrop(window.getDatabaseNode(), draginfo);
end

-- update run from onCarriedChanged
function updateItemEffects(nodeField)
	if EffectManagerADND.updateItemEffects then
		EffectManagerADND.updateItemEffects(DB.getChild(nodeField, ".."));
	end
end

-- update single item from edit for *.effect handler
function updateItemEffectsForEdit(nodeField)
    checkEffectsAfterEdit(DB.getChild(nodeField, ".."));
end

-- run from addHandler for deleted child
function updateFromDeletedInventory(node)
    local nodeChar = DB.getChild(node, "..");
    local nodeCT = EffectManagerADND.getCTNodeByNodeChar(nodeChar);
    if nodeCT then
        -- check that we still have the combat effect source item
        -- otherwise remove it
        checkEffectsAfterDelete(nodeCT);
    end
	onEncumbranceChanged();
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

-- find the effect for this source and delete and re-build
function checkEffectsAfterEdit(itemNode)
    local nodeChar = DB.getChild(itemNode, ".....");
    local nodeCT = EffectManagerADND.getCTNodeByNodeChar(nodeChar);
    if nodeCT then
        for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
            local sLabel = DB.getValue(nodeEffect, "label", "");
            local sEffSource = DB.getValue(nodeEffect, "source_name", "");
            -- see if the node exists and if it's in an inventory node
            local nodeFound = DB.findNode(sEffSource);
            if nodeFound and nodeFound == itemNode and string.match(sEffSource,"inventorylist") then
                nodeEffect.delete();
                EffectManagerADND.updateItemEffects(DB.getChild(itemNode, "..."));
            end
        end
    end
end
