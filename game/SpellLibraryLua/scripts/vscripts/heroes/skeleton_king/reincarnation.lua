ability_reincarnation = {}

LinkLuaModifier( "modifier_ability_reincarnation", "heroes/skeleton_king/reincarnation", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_reincarnation_debuff", "heroes/skeleton_king/reincarnation", LUA_MODIFIER_MOTION_NONE )

function ability_reincarnation:GetIntrinsicModifierName()
	return "modifier_ability_reincarnation"
end

function ability_reincarnation:GetCastRange()
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor( "aura_radius" )
	else
		return self:GetSpecialValueFor( "slow_radius" )
	end
end

modifier_ability_reincarnation = {}

function modifier_ability_reincarnation:IsHidden()
	return true
end

function modifier_ability_reincarnation:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_REINCARNATION
	}
end

function modifier_ability_reincarnation:ReincarnateTime( params )
	if IsServer() then
		if self:GetAbility():IsFullyCastable() then
			self:Reincarnate()

			return self:GetAbility():GetSpecialValueFor( "reincarnate_time" )
		end

		return 0
	end
end

function modifier_ability_reincarnation:Reincarnate()
	self:GetAbility():UseResources( true, false, true )

	local enemies = FindUnitsInRadius(
		self:GetParent():GetTeamNumber(),
		self:GetParent():GetAbsOrigin(),
		nil,
		self:GetAbility():GetSpecialValueFor( "slow_radius" ),
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		enemy:AddNewModifier(
			self:GetParent(),
			self:GetAbility(),
			"modifier_ability_reincarnation_debuff",
			{ duration = self:GetAbility():GetSpecialValueFor( "slow_duration" ) }
		)
	end

	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_skeletonking/wraith_king_reincarnate.vpcf", PATTACH_ABSORIGIN, self:GetParent() )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( self:GetAbility():GetSpecialValueFor( "reincarnate_time" ), 0, 0 ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_SkeletonKing.Reincarnate", self:GetParent() )
end

modifier_ability_reincarnation_debuff = {}

function modifier_ability_reincarnation_debuff:IsHidden()
	return false
end

function modifier_ability_reincarnation_debuff:IsDebuff()
	return true
end

function modifier_ability_reincarnation_debuff:IsStunDebuff()
	return false
end

function modifier_ability_reincarnation_debuff:IsPurgable()
	return true
end

function modifier_ability_reincarnation_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end
function modifier_ability_reincarnation_debuff:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor( "attackslow" )
end

function modifier_ability_reincarnation_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor( "movespeed" )
end

function modifier_ability_reincarnation_debuff:GetEffectName()
	return "particles/units/heroes/hero_skeletonking/wraith_king_reincarnate_slow_debuff.vpcf"
end

function modifier_ability_reincarnation_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end