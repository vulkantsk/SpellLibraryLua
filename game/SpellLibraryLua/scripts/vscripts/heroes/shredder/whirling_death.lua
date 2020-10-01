ability_whirling_death = {}

LinkLuaModifier( "modifier_ability_whirling_death", "heroes/shredder/whirling_death", LUA_MODIFIER_MOTION_NONE )

function ability_whirling_death:OnSpellStart()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor( "whirling_radius" )
	local damage = self:GetSpecialValueFor( "whirling_damage" )
	local duration = self:GetSpecialValueFor( "duration" )
	local tree_damage = self:GetSpecialValueFor( "tree_damage_scale" )

	local trees = GridNav:GetAllTreesAroundPoint( caster:GetOrigin(), radius, false )
	GridNav:DestroyTreesAroundPoint( caster:GetOrigin(), radius, false )

	damage = damage + #trees * tree_damage
	local damageTable = {
		attacker = caster,
		damage = damage,
		damage_type = self:GetAbilityDamageType(),
		ability = self,
	}

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster:GetOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		0,
		false
	)

	local hashero = false
	for _,enemy in pairs(enemies) do
		if enemy:IsHero() then
			enemy:AddNewModifier(
				caster,
				self,
				"modifier_ability_whirling_death",
				{ duration = duration }
			)

			hashero = true
		end

		damageTable.victim = enemy
		ApplyDamage( damageTable )
	end

	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_shredder/shredder_whirling_death.vpcf", PATTACH_CENTER_FOLLOW, self:GetCaster() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		self:GetCaster(),
		PATTACH_CENTER_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0),
		true
	)
	ParticleManager:SetParticleControl( effect_cast, 2, Vector( radius, radius, radius ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Shredder.WhirlingDeath.Cast", self:GetCaster() )
	if hashero then
		EmitSoundOn( "Hero_Shredder.WhirlingDeath.Damage", self:GetCaster() )
	end
end

modifier_ability_whirling_death = {}

function modifier_ability_whirling_death:IsHidden()
	return false
end

function modifier_ability_whirling_death:IsDebuff()
	return true
end

function modifier_ability_whirling_death:IsStunDebuff()
	return false
end

function modifier_ability_whirling_death:IsPurgable()
	return true
end

function modifier_ability_whirling_death:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ability_whirling_death:OnCreated( kv )
	self.parent = self:GetParent()

	self.stat_loss_pct = self:GetAbility():GetSpecialValueFor( "stat_loss_pct" )

	if not IsServer() then return end

	self.stat_loss = -self.parent:GetPrimaryStatValue() * self.stat_loss_pct/100

	if self.parent:GetPrimaryAttribute()==DOTA_ATTRIBUTE_STRENGTH then
		self:GetParent():ModifyHealth( self:GetParent():GetHealth() + 20*self.stat_loss, self:GetAbility(), true, DOTA_DAMAGE_FLAG_NONE )
	end
end

function modifier_ability_whirling_death:OnRemoved()
	if not IsServer() then return end

	if self.parent:GetPrimaryAttribute()==DOTA_ATTRIBUTE_STRENGTH then
		self:GetParent():ModifyHealth( self:GetParent():GetHealth() - 19*self.stat_loss, self:GetAbility(), true, DOTA_DAMAGE_FLAG_NONE )
	end
end

function modifier_ability_whirling_death:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}
end

if IsServer() then
	function modifier_ability_whirling_death:GetModifierBonusStats_Agility()
		if self.parent:GetPrimaryAttribute()~=DOTA_ATTRIBUTE_AGILITY then return 0 end
		return self.stat_loss or 0
	end
	function modifier_ability_whirling_death:GetModifierBonusStats_Intellect()
		if self.parent:GetPrimaryAttribute()~=DOTA_ATTRIBUTE_INTELLECT then return 0 end
		return self.stat_loss or 0
	end
	function modifier_ability_whirling_death:GetModifierBonusStats_Strength()
		if self.parent:GetPrimaryAttribute()~=DOTA_ATTRIBUTE_STRENGTH then return 0 end
		return self.stat_loss or 0
	end
end

function modifier_ability_whirling_death:GetStatusEffectName()
	return "particles/status_fx/status_effect_shredder_whirl.vpcf"
end

function modifier_ability_whirling_death:StatusEffectPriority()
	return MODIFIER_PRIORITY_NORMAL
end

function modifier_ability_whirling_death:GetEffectName()
	return "particles/units/heroes/hero_shredder/shredder_whirling_death_debuff.vpcf"
end

function modifier_ability_whirling_death:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end