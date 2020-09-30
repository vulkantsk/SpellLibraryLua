ability_mortal_strike = {}

LinkLuaModifier( "modifier_ability_mortal_strike", "heroes/skeleton_king/mortal_strike", LUA_MODIFIER_MOTION_NONE )

function ability_mortal_strike:GetIntrinsicModifierName()
	return "modifier_ability_mortal_strike"
end

function ability_mortal_strike:SpawnSkeleton( pos, value, caster, duration )
	local summoned_unit = CreateUnitByName(
		"npc_dota_wraith_king_skeleton_warrior",
		pos,
		true,
		caster,
		caster:GetOwner(),
		caster:GetTeamNumber()
	)

	summoned_unit:SetControllableByPlayer( caster:GetPlayerID(), false )
	summoned_unit:SetOwner( caster )
	summoned_unit:AddNewModifier( caster, self, "modifier_kill", {duration = duration})
	summoned_unit:SetAcquisitionRange( 999999 )

	if value then
		summoned_unit:SetMinimumGoldBounty(self:GetSpecialValueFor("gold_bounty"))
		summoned_unit:SetMaximumGoldBounty(self:GetSpecialValueFor("gold_bounty"))
		summoned_unit:SetDeathXP(self:GetSpecialValueFor("xp_bounty"))
	else
		summoned_unit.needToRespawn = true
	end
end

function ability_mortal_strike:OnSpellStart()
	local target = self:GetCursorTarget()
	local unit_duration = self:GetSpecialValueFor("skeleton_duration")

	local caster = self:GetCaster()
	local delay = self:GetSpecialValueFor("spawn_interval")

	local modifier = caster:FindModifierByNameAndCaster( "modifier_ability_mortal_strike", caster )
	local count = modifier:GetStackCount()
	local talent = caster:FindAbilityByName( "special_bonus_unique_wraith_king_5" )

	if talent and talent:GetLevel() > 0 then
		count = count + talent:GetSpecialValueFor( "value" )
	end

	for i = 1, count do
		Timers:CreateTimer( delay * i, function()
			self:SpawnSkeleton( caster:GetAbsOrigin() + RandomVector( 150 ), false, caster, unit_duration )
		end )
	end

	modifier:SetStackCount( 0 )
end

modifier_ability_mortal_strike = {}

function modifier_ability_mortal_strike:IsHidden()
	return self:GetStackCount() == 0
end

function modifier_ability_mortal_strike:IsDebuff()
	return false
end

function modifier_ability_mortal_strike:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_ability_mortal_strike:GetModifierPreAttack_CriticalStrike( params )
	if IsServer() then
		if
			self:RollChance( self:GetAbility():GetSpecialValueFor( "crit_chance" ) ) and
			params.target:GetTeamNumber() ~= self:GetParent():GetTeamNumber()
		then
			EmitSoundOn( "Hero_SkeletonKing.CriticalStrike", params.target )
			return self:GetAbility():GetSpecialValueFor( "crit_mult" )
		end
	end

	return 0
end

function modifier_ability_mortal_strike:OnDeath( params )
	if IsServer() then
		if params.attacker == self:GetParent() and params.attacker ~= self:GetParent():GetTeam() then
			if self.addStack then
				self:AddStack()
				self.addStack = false
			else
				self.addStack = true
			end
		elseif params.unit.needToRespawn and params.unit:HasModifier( "modifier_kill" ) then
			local time = self:GetAbility():GetSpecialValueFor("reincarnate_time")
			local modifier = params.unit:FindModifierByName( "modifier_kill" )
			local duration = modifier:GetRemainingTime() - time

			if duration > 0 then
				Timers:CreateTimer( time, function()
					local duration = 
					self:GetAbility():SpawnSkeleton( params.unit:GetAbsOrigin(), true, self:GetCaster(), duration )
				end )
			end
		end
	end
end

function modifier_ability_mortal_strike:RollChance( chance )
	local rand = RandomFloat( 0,1 )
	if rand < chance / 100 then
		return true
	end

	return false
end

function modifier_ability_mortal_strike:AddStack()
	local target = self:GetStackCount() + 1

	if target <= self:GetAbility():GetLevel() * 2 then
		self:IncrementStackCount()
	end
end