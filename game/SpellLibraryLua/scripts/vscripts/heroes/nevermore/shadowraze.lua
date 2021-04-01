LinkLuaModifier( "modifier_shadowraze", "heroes/nevermore/shadowraze", LUA_MODIFIER_MOTION_NONE )

shadowraze = {}

function shadowraze:OnSpellStart()
	local distance = self:GetSpecialValueFor("shadowraze_range")
	local front = self:GetCaster():GetForwardVector():Normalized()
	local target_pos = self:GetCaster():GetOrigin() + front * distance
	local target_radius = self:GetSpecialValueFor("shadowraze_radius")
	local base_damage = self:GetSpecialValueFor("shadowraze_damage")
	local stack_damage = self:GetSpecialValueFor("stack_bonus_damage")
	local stack_duration = self:GetSpecialValueFor("duration")

	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),
		target_pos,
		nil,
		target_radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	for _,enemy in pairs(enemies) do
		local modifier = enemy:FindModifierByNameAndCaster("modifier_shadowraze", self:GetCaster())
		local stack = 0
		if modifier~=nil then
			stack = modifier:GetStackCount()
		end

		local damageTable = {
			victim = enemy,
			attacker = self:GetCaster(),
			damage = base_damage + stack*stack_damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self,
		}

		ApplyDamage( damageTable )

		if modifier==nil then
			enemy:AddNewModifier(
				self:GetCaster(),
				self,
				"modifier_shadowraze",
				{duration = stack_duration}
			)
		else
			modifier:IncrementStackCount()
			modifier:ForceRefresh()
		end
	end

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf",
		PATTACH_WORLDORIGIN,
		nil
	)
	ParticleManager:SetParticleControl( effect_cast, 0, target_pos )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( target_radius, 1, 1 ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )
	
	EmitSoundOnLocationWithCaster( target_pos, "Hero_Nevermore.Shadowraze", self:GetCaster() )
end

ability_shadowraze1 = shadowraze
ability_shadowraze2 = shadowraze
ability_shadowraze3 = shadowraze

modifier_shadowraze = {}

function modifier_shadowraze:IsHidden()
	return false
end

function modifier_shadowraze:IsDebuff()
	return true
end

function modifier_shadowraze:IsPurgable()
	return false
end

function modifier_shadowraze:OnCreated( kv )
	self:SetStackCount(1)
end

function modifier_shadowraze:GetEffectName()
	return "particles/units/heroes/hero_nevermore/nevermore_shadowraze_debuff.vpcf"
end

function modifier_shadowraze:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end