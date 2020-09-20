ability_demonic_conversion = {}

LinkLuaModifier( "modifier_ability_demonic_conversion", "heroes/enigma/demonic_conversion", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_demonic_conversion_damage", "heroes/enigma/demonic_conversion", LUA_MODIFIER_MOTION_NONE )

function ability_demonic_conversion:OnSpellStart()
	local target = self:GetCursorTarget()
	local pos = target:GetAbsOrigin()

	target:Kill( self, self:GetCaster() )

	for i = 1, self:GetSpecialValueFor( "spawn_count" ) do
		self:CreateEidolon( pos, true, self:GetCooldown( self:GetLevel() ) )
	end
end

function ability_demonic_conversion:CreateEidolon( pos, ve, duration )
	local levelUnit = {
		"npc_dota_lesser_eidolon",
		"npc_dota_eidolon",
		"npc_dota_greater_eidolon",
		"npc_dota_dire_eidolon"
	}

	local caster = self:GetCaster()
	local eidolon = CreateUnitByName( levelUnit[self:GetLevel()], pos, true, caster, caster, caster:GetTeamNumber() )
	eidolon:AddNewModifier( caster, self, "modifier_ability_demonic_conversion", { duration = duration, ve = ve } )
	eidolon:AddNewModifier( caster, self, "modifier_kill", { duration = duration } )
	eidolon:SetOwner( caster )
	eidolon:SetControllableByPlayer( caster:GetPlayerID(), true )
	FindClearSpaceForUnit( eidolon, pos, true )

	local talent = self:GetCaster():FindAbilityByName( "special_bonus_unique_enigma_3" )

	if talent and talent:GetLevel() > 0 then
		eidolon:AddNewModifier( caster, talent, "modifier_ability_demonic_conversion_damage", {} )
	end

	return eidolon
end

modifier_ability_demonic_conversion = {}

function modifier_ability_demonic_conversion:IsDebuff()
	return true
end

function modifier_ability_demonic_conversion:OnCreated( data )
	local ability = self:GetAbility()
	
	if data.ve then
		self.attacks = ability:GetSpecialValueFor( "split_attack_count" )
	end

	self.damage = ability:GetSpecialValueFor( "eidolon_dmg_tooltip" )
end

function modifier_ability_demonic_conversion:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end

function modifier_ability_demonic_conversion:OnAttackLanded( data )
	if self.attacks and data.attacker == self:GetParent() then
		if self.attacks > 1 then
			self.attacks = self.attacks - 1
		else
			local parent = self:GetParent()
			local pos = parent:GetAbsOrigin()
			local ability = self:GetAbility()

			ability:CreateEidolon( pos, nil, self:GetRemainingTime() )
			ability:CreateEidolon( pos, nil, self:GetRemainingTime() )
			
			parent:ForceKill( false )
		end
	end
end

modifier_ability_demonic_conversion_damage = {}

function modifier_ability_demonic_conversion_damage:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
	}
end

function modifier_ability_demonic_conversion_damage:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor( "value" )
end