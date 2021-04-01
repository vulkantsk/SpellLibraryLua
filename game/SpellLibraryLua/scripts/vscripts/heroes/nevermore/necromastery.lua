LinkLuaModifier( "modifier_ability_necromastery", "heroes/nevermore/necromastery", LUA_MODIFIER_MOTION_NONE )

ability_necromastery = {}

function ability_necromastery:GetIntrinsicModifierName()
	return "modifier_ability_necromastery"
end

modifier_ability_necromastery = {}

function modifier_ability_necromastery:IsHidden()
	return false
end

function modifier_ability_necromastery:IsDebuff()
	return false
end

function modifier_ability_necromastery:IsPurgable()
	return false
end

function modifier_ability_necromastery:RemoveOnDeath()
	return false
end

function modifier_ability_necromastery:OnCreated( kv )
	self.soul_max = self:GetAbility():GetSpecialValueFor("necromastery_max_souls")
	self.soul_max_scepter = self:GetAbility():GetSpecialValueFor("necromastery_max_souls_scepter")
	self.soul_release = self:GetAbility():GetSpecialValueFor("soul_release")
	self.soul_damage = self:GetAbility():GetSpecialValueFor("necromastery_damage_per_soul")
end

modifier_ability_necromastery.OnRefresh = modifier_ability_necromastery.OnCreated

function modifier_ability_necromastery:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
	}
end

function modifier_ability_necromastery:GetModifierSpellAmplify_Percentage()
	return self:GetStackCount()
end

function modifier_ability_necromastery:OnDeath( params )
	if IsServer() then
		self:DeathLogic( params )
		self:KillLogic( params )
	end
end

function modifier_ability_necromastery:GetModifierPreAttack_BonusDamage( params )
	if not self:GetParent():IsIllusion() then
		local max_stack = self.soul_max
		if self:GetParent():HasScepter() then
			return self:GetStackCount() * self.soul_damage
		else
			return math.min(self.soul_max,self:GetStackCount()) * self.soul_damage
		end
	end
end

function modifier_ability_necromastery:DeathLogic( params )
	local unit = params.unit
	local pass = false
	if unit==self:GetParent() and params.reincarnate==false then
		pass = true
	end

	if pass then
		local after_death = math.floor(self:GetStackCount() * self.soul_release)
		self:SetStackCount(math.max(after_death,1))
	end
end

function modifier_ability_necromastery:KillLogic( params )
	local target = params.unit
	local attacker = params.attacker
	local pass = false
	if attacker==self:GetParent() and target~=self:GetParent() and attacker:IsAlive() then
		if (not target:IsIllusion()) and (not target:IsBuilding()) then
			pass = true
		end
	end

	if pass and (not self:GetParent():PassivesDisabled()) then
		self:AddStack(1)

		ProjectileManager:CreateTrackingProjectile( {
			Target = self:GetParent(),
			Source = target,
			EffectName = "particles/units/heroes/hero_nevermore/nevermore_necro_souls.vpcf",
			iMoveSpeed = 400,
			vSourceLoc= target:GetAbsOrigin(),
			bDodgeable = false,
			bReplaceExisting = false,
			flExpireTime = GameRules:GetGameTime() + 5,
			bProvidesVision = false,
		} )
	end
end

function modifier_ability_necromastery:AddStack()
	local after = self:GetStackCount() + 1
	if not self:GetParent():HasScepter() then
		if after > self.soul_max then
			after = self.soul_max
		end
	else
		if after > self.soul_max_scepter then
			after = self.soul_max_scepter
		end
	end
	self:SetStackCount( after )
end