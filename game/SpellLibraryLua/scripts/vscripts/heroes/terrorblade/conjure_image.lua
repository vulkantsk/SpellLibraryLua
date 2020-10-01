ability_conjure_image = {}

LinkLuaModifier( "modifier_ability_conjure_image", "heroes/terrorblade/conjure_image", LUA_MODIFIER_MOTION_NONE )

function ability_conjure_image:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor( "illusion_duration" )
	local outgoing = self:GetSpecialValueFor( "illusion_outgoing_damage" )
	local incoming = self:GetSpecialValueFor( "illusion_incoming_damage" )
	local distance = 72
	local illusions = CreateIllusions(
		caster,
		caster,
		{
			outgoing_damage = outgoing,
			incoming_damage = incoming,
			duration = duration,
		},
		1,
		distance,
		false,
		true
	)
	local illusion = illusions[1]

	Timers:CreateTimer( FrameTime() * 2,function()
		illusion:AddNewModifier(
			caster,
			self,
			"modifier_ability_conjure_image",
			{ duration = duration }
		)
		EmitSoundOn( "Hero_Terrorblade.ConjureImage", illusion )
	end )
end

modifier_ability_conjure_image = {}

function modifier_ability_conjure_image:IsHidden()
	return true
end

function modifier_ability_conjure_image:IsDebuff()
	return false
end

function modifier_ability_conjure_image:IsStunDebuff()
	return false
end

function modifier_ability_conjure_image:IsPurgable()
	return false
end

function modifier_ability_conjure_image:GetEffectName()
	return "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf"
end

function modifier_ability_conjure_image:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_ability_conjure_image:GetStatusEffectName()
	return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_ability_conjure_image:StatusEffectPriority()
	return 10
end