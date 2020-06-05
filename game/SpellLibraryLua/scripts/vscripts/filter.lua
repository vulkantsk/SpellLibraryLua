function GameMode:ActivateFilters()
    -- GameRules:GetGameModeEntity():SetDamageFilter(Dynamic_Wrap(GameMode, 'DamageFilter'), self)
    GameRules:GetGameModeEntity():SetBountyRunePickupFilter(Dynamic_Wrap(GameMode, 'RuneFilter'), self)
end

function GameMode:RuneFilter(data)
    PrintTable(data)
    local ent = PlayerResource:GetSelectedHeroEntity(data.player_id_const)
    if ent then 
        data.gold_bounty = data.gold_bounty * math.max(GetMultipleBountyBonus(ent),1)
    end 
    return true
end

function GameMode:DamageFilter(filterDamage)
	local attacker = filterDamage.entindex_attacker_const and EntIndexToHScript(filterDamage.entindex_attacker_const) 
	if not attacker then
		print('[DamageFilter] Unit damage not attacker!',EntIndexToHScript(filterDamage.entindex_victim_const):GetUnitName()) 
		return true 
	end 
	local ability,abilityName
	local victim = EntIndexToHScript(filterDamage.entindex_victim_const)
	local typeDamage = filterDamage.damagetype_const
	if filterDamage.entindex_inflictor_const then
		ability = EntIndexToHScript(filterDamage.entindex_inflictor_const )
		if ability and ability.GetAbilityName and ability:GetAbilityName() then
			abilityName = ability:GetAbilityName()
		end
    end
    
    local data = {
        victim = victim,
        attacker = attacker,
        typeDamage = typeDamage,
        ability = ability,
        abilityName = abilityName,
        damage = filterDamage.damage,
    }

    local applyFilter = GameMode:OnApplyDamage(data)
    if applyFilter then 
        filterDamage.damage = GameMode:OnTakeDamageFilter(applyFilter)
        return not not filterDamage.damage
    end 
    return false  

end

function GameMode:OnApplyDamage(data)
 
    return data
end

function GameMode:OnTakeDamageFilter(data)
    return data.damage
end


