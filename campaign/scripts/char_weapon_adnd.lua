-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onAttackAction(draginfo)
	local nodeWeapon = getDatabaseNode();
	local nodeChar = nodeWeapon.getChild("...")

	-- Build basic attack action record
	local rAction = CharWeaponManager.buildAttackAction(nodeChar, nodeWeapon);

	-- Decrement ammo
	CharWeaponManager.decrementAmmo(nodeChar, nodeWeapon);

	-- Perform action
	local rActor = ActorManager.resolveActor(nodeChar);

	-- add itemPath to rActor so that when effects are checked we can 
	-- make compare against action only effects
	local _, sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
	rActor.itemPath = sRecord;
	-- end Adanced Effects Piece ---

	-- bmos adding AmmunitionManager integration
	if AmmunitionManager then
		local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon, rActor)
		if nodeAmmo then
			rActor.ammoPath = nodeAmmo.getPath()
		end
	end
	--end bmos adding ammoPath

	-- bmos adding AmmoManager loading weapon support and checking for ammo
	if not AmmunitionManager then	
		ActionAttack.performRoll(draginfo, rActor, rAction);
		return true;
	else
		local bLoading = DB.getValue(nodeWeapon, 'properties', ''):lower():find('loading') ~= nil
		local bIsLoaded = DB.getValue(nodeWeapon, 'isloaded', 0) == 1
		if not bLoading or (bLoading and bIsLoaded) then
			if (bInfiniteAmmo or nAmmo > 0) then	
				if bLoading then DB.setValue(nodeWeapon, 'isloaded', 'number', 0); end
				ActionAttack.performRoll(draginfo, rActor, rAction);
				return true;
			else
				ChatManager.Message(Interface.getString("char_message_atkwithnoammo"), true, rActor);
				if bLoading then DB.setValue(nodeWeapon, 'isloaded', 'number', 0); end
			end
		else
			ChatManager.Message(string.format(Interface.getString('char_actions_notloaded'), DB.getValue(nodeWeapon, 'name', 'weapon')), true, rActor);
		end
	end
	-- end bmos adding loading weapon and ammo check support
end

function onDamageAction(draginfo)
	local nodeWeapon = getDatabaseNode();
	local nodeChar = nodeWeapon.getChild("...")

	-- Build basic damage action record
	local rAction = CharWeaponManager.buildDamageAction(nodeChar, nodeWeapon);

	-- Perform damage action
	local rActor = ActorManager.resolveActor(nodeChar);

	-- add itemPath to rActor so that when effects are checked we can 
	-- make compare against action only effects
	local _, sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
	rActor.itemPath = sRecord;
	-- end Adanced Effects Piece ---

	-- bmos adding AmmunitionManager integration
	if AmmunitionManager then
		local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon, rActor)
		if nodeAmmo then
			rActor.ammoPath = nodeAmmo.getPath()
		end
	end
	-- end bmos adding ammoPath
	
	ActionDamage.performRoll(draginfo, rActor, rAction);
	return true;
end
