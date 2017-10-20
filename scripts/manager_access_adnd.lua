--
--
-- Access to nodes managed for certain places here
--
-- Right now this mainly deals with CT nodes so that players can apply effects
-- that are on items or other areas --celestian
--

function onInit()
    User.onIdentityActivation = onIdentityActivation;
end

function onIdentityActivation(sIdentity, sUser, bActivated)
-- Debug.console("manager_Access_adnd.lua","onIdentityActivation","sIdentity",sIdentity);
-- Debug.console("manager_Access_adnd.lua","onIdentityActivation","sUser",sUser);
-- Debug.console("manager_Access_adnd.lua","onIdentityActivation","bActivated",bActivated);
-- Debug.console("manager_Access_adnd.lua","onIdentityActivation","User.getAllActiveIdentities()",User.getAllActiveIdentities());
-- Debug.console("manager_Access_adnd.lua","onIdentityActivation","User.getAllActiveIdentities()",User.getAllActiveIdentities());
	if bActivated then
    -- give access to CT node it character if exists
        local nodeCT = CombatManager.getCTFromNode("charsheet." .. sIdentity);
        if nodeCT and sUser ~= "" then
			 local owner = nodeCT.getOwner();
			 if owner then
				 nodeCT.removeHolder(owner);
			 end
            DB.setOwner(nodeCT, sUser);
        end
	else
    -- remove access to CT node if character exists
        local nodeCT = CombatManager.getCTFromNode("charsheet." .. sIdentity);
        if nodeCT and sUser ~= "" then
			local owner = nodeCT.getOwner();
			if owner then
				nodeCT.removeHolder(owner);
			end
        end
    end
end

-- flip through active users and their active identities and if they match
-- the nodeCT we just added then give them ownership
function manageCTOwners(nodeCT)
    for _,vUser in ipairs(User.getActiveUsers()) do
        for _,vIdentity in ipairs(User.getActiveIdentities(vUser)) do
            local _, sRecord = DB.getValue(nodeCT, "link", "", "");
             if (sRecord == ("charsheet." .. vIdentity)) then
                DB.setOwner(nodeCT, vUser);
            end
        end
    end
end
