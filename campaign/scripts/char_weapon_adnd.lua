--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--
-- luacheck: globals onAttackAction onDamageAction

-- add itemPath to rActor so that when effects are checked we can
-- make compare against action only effects
-- luacheck: globals advancedEffectsPiece
function advancedEffectsPiece(nodeWeapon)
	local _, sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
	return sRecord;
end

function onAttackAction(draginfo)
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...")

	-- Build basic attack action record
	local rAction = CharWeaponManager.buildAttackAction(nodeChar, nodeWeapon);

	-- Decrement ammo
	CharWeaponManager.decrementAmmo(nodeChar, nodeWeapon);

	-- Perform action
	local rActor = ActorManager.resolveActor(nodeChar);

	-- add itemPath to rActor so that when effects are checked we can
	-- make compare against action only effects
	rActor.itemPath = advancedEffectsPiece(nodeWeapon);
	-- end Advanced Effects Piece ---

	-- bmos adding AmmunitionManager integration
	if AmmunitionManager then
		local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon, rActor);
		if nodeAmmo then
			rActor.ammoPath = DB.getPath(nodeAmmo);
		end
	end
	--end bmos adding ammoPath

	-- bmos adding AmmoManager loading weapon support and checking for ammo
	if not AmmunitionManager then
		ActionAttack.performRoll(draginfo, rActor, rAction);
		return true;
	else
		local nAmmo, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, AmmunitionManager.getAmmoNode(nodeWeapon));
		local messagedata = { text = "", sender = rActor.sName, font = "emotefont" };

		local nodeAmmoManager = DB.getChild(nodeWeapon, "ammunitionmanager");
		local bLoading = AmmunitionManager.hasLoadAction(nodeWeapon);
		local bIsLoaded = DB.getValue(nodeAmmoManager, "isloaded") == 1;
		if not bLoading or bIsLoaded then
			if bInfiniteAmmo or nAmmo > 0 then
				if bLoading then DB.setValue(nodeAmmoManager, "isloaded", "number", 0); end
				ActionAttack.performRoll(draginfo, rActor, rAction);
				return true;
			end
			messagedata.text = Interface.getString("char_message_atkwithnoammo");
			Comm.deliverChatMessage(messagedata);
			if bLoading then DB.setValue(nodeAmmoManager, "isloaded", "number", 0); end
		else
			local sWeaponName = DB.getValue(nodeWeapon, "name", "weapon");
			messagedata.text = string.format(Interface.getString("char_actions_notloaded"), sWeaponName, true, rActor);
			Comm.deliverChatMessage(messagedata);
		end
	end
	-- end bmos adding loading weapon and ammo check support
end

function onDamageAction(draginfo)
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...")

	-- Build basic damage action record
	local rAction = CharWeaponManager.buildDamageAction(nodeChar, nodeWeapon);

	-- Perform damage action
	local rActor = ActorManager.resolveActor(nodeChar);

	-- add itemPath to rActor so that when effects are checked we can
	-- make compare against action only effects
	rActor.itemPath = advancedEffectsPiece(nodeWeapon);
	-- end Advanced Effects Piece ---

	-- bmos adding AmmunitionManager integration
	if AmmunitionManager then
		local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon, rActor);
		if nodeAmmo then
			rActor.ammoPath = DB.getPath(nodeAmmo);
		end
	end
	-- end bmos adding ammoPath

	ActionDamage.performRoll(draginfo, rActor, rAction);
	return true;
end
