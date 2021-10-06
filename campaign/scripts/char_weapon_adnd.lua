-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...");
	DB.addHandler(nodeWeapon.getNodeName(), "onChildUpdate", onDataChanged);
	DB.addHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", onDataChanged);
	DB.addHandler(DB.getPath(nodeChar, "weapon.twoweaponfighting"), "onUpdate", onDataChanged);

	onDataChanged();
end

function onClose()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...");
	DB.removeHandler(nodeWeapon.getNodeName(), "onChildUpdate", onDataChanged);
	DB.removeHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", onDataChanged);
	DB.removeHandler(DB.getPath(nodeChar, "weapon.twoweaponfighting"), "onUpdate", onDataChanged);
end

local m_sClass = "";
local m_sRecord = "";
function onLinkChanged()
	local node = getDatabaseNode();
	local sClass, sRecord = DB.getValue(node, "shortcut", "", "");
	if sClass ~= m_sClass or sRecord ~= m_sRecord then
		m_sClass = sClass;
		m_sRecord = sRecord;
		
		local sInvList = DB.getPath(DB.getChild(node, "..."), "inventorylist") .. ".";
		if sRecord:sub(1, #sInvList) == sInvList then
			carried.setLink(DB.findNode(DB.getPath(sRecord, "carried")));
		end
	end
end

function onDataChanged()
	onLinkChanged();
	onAttackChanged();
	onDamageChanged();
	
	local bRanged = (type.getValue() ~= 0);
	label_ammo.setVisible(bRanged);
	maxammo.setVisible(bRanged);
	ammocounter.setVisible(bRanged);
end

function highlightAttack(bOnControl)
	if bOnControl then
		attackshade.setFrame("rowshade");
	else
		attackshade.setFrame(nil);
	end
end
	
function onAttackChanged()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = nodeWeapon.getChild("...")

	local nMod = CharWeaponManager.getAttackBonus(nodeChar, nodeWeapon);
	
	attackview.setValue(nMod);
end

function onAttackAction(draginfo)
	local nodeWeapon = getDatabaseNode();
	local nodeChar = nodeWeapon.getChild("...")

	-- Build basic attack action record
	local rAction = CharWeaponManager.buildAttackAction(nodeChar, nodeWeapon);

	-- Decrement ammo
	-- bmos removing redundant ammo counting
	-- for compatibility with ammunition tracker, make this change in your char_weapon.lua
	if not AmmunitionManager then
		CharWeaponManager.decrementAmmo(nodeChar, nodeWeapon);
	end
	-- end bmos removing redundant ammo counting

	-- Perform action
	local rActor = ActorManager.getActor("pc", nodeChar);

	-- add itemPath to rActor so that when effects are checked we can 
	-- make compare against action only effects
	local _, sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
	rActor.itemPath = sRecord;
	-- end Adanced Effects Piece ---

	-- bmos only allowing attacks when ammo is sufficient
	-- for compatibility with ammunition tracker, make this change in your char_weapon.lua
	-- this if section replaces the two commented out lines above:
	-- "ActionAttack.performRoll(draginfo, rActor, rAction);" and "return true;"
	local nMaxAmmo = DB.getValue(nodeWeapon, 'maxammo', 0)
	local nMaxAttacks = nMaxAmmo - DB.getValue(nodeWeapon, 'ammo', 0)
	if not AmmunitionManager or (not (nMaxAmmo > 0) or (nMaxAttacks >= 1)) then	
		ActionAttack.performRoll(draginfo, rActor, rAction);
		return true;
	else
		ChatManager.Message(Interface.getString("char_message_atkwithnoammo"), true, rActor);
	end
	-- end bmos only allowing attacks when ammo is sufficient
end

function onDamageChanged()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = nodeWeapon.getChild("...")
	
	local sDamage = CharWeaponManager.buildDamageString(nodeChar, nodeWeapon);

	damageview.setValue(sDamage);
end

function onDamageAction(draginfo)
	local nodeWeapon = getDatabaseNode();
	local nodeChar = nodeWeapon.getChild("...")

	-- Build basic damage action record
	local rAction = CharWeaponManager.buildDamageAction(nodeChar, nodeWeapon);

	-- Perform damage action
	local rActor = ActorManager.getActor("pc", nodeChar);

	-- add itemPath to rActor so that when effects are checked we can 
	-- make compare against action only effects
	local _, sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
	rActor.itemPath = sRecord;
	-- end Adanced Effects Piece ---
	
	ActionDamage.performRoll(draginfo, rActor, rAction);
	return true;

end
