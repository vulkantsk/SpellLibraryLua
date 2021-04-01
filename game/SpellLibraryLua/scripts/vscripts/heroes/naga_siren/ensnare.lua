LinkLuaModifier( "modifier_ability_ensnare", "heroes/naga_siren/ensnare", LUA_MODIFIER_MOTION_NONE )

ability_ensnare = {}

function ability_ensnare:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local fake_radius = self:GetSpecialValueFor( "fake_ensnare_distance" )
	local illusions = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster:GetOrigin(),
		nil,
		fake_radius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO,
		0,
		0,
		false
	)

	local playerID = caster:GetPlayerOwnerID()
	local model = caster:GetModelName()
	for _,illusion in pairs(illusions) do
		if illusion:GetPlayerOwnerID()==playerID and illusion:IsIllusion() and illusion:GetModelName()==model then
			illusion:StartGesture( ACT_DOTA_CAST_ABILITY_2 )

			self.illusions[illusion] = true
		end
	end

	return true
end

function ability_ensnare:OnAbilityPhaseInterrupted()
	self.illusions = {}
end

ability_ensnare.illusions = {}

function ability_ensnare:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local info = {
		Target = target,
		Source = caster,
		Ability = self,
		EffectName = "particles/units/heroes/hero_siren/siren_net_projectile.vpcf",
		iMoveSpeed = self:GetSpecialValueFor( "net_speed" ),
		bDodgeable = true,
		ExtraData = {
			fake = 0,
		}
	}
	ProjectileManager:CreateTrackingProjectile(info)

	for illusion,_ in pairs(self.illusions) do
		info.Source = illusion
		info.ExtraData = {
			fake = 1
		}
		ProjectileManager:CreateTrackingProjectile(info)

		EmitSoundOn( "Hero_NagaSiren.Ensnare.Cast", illusion )
	end

	self.illusions = {}

	EmitSoundOn( "Hero_NagaSiren.Ensnare.Cast", caster )
end

function ability_ensnare:OnProjectileHit_ExtraData( target, location, data )
	if not target then return end
	if data.fake==1 then return end
	if target:IsMagicImmune() then return end
	if target:TriggerSpellAbsorb( self ) then return end

	local duration = self:GetSpecialValueFor( "duration" )

	target:AddNewModifier(
		self:GetCaster(),
		self,
		"modifier_ability_ensnare",
		{ duration = duration }
	)

	EmitSoundOn( "Hero_NagaSiren.Ensnare.Target", target )
end

modifier_ability_ensnare = {}

function modifier_ability_ensnare:IsHidden()
	return false
end

function modifier_ability_ensnare:IsDebuff()
	return true
end

function modifier_ability_ensnare:IsStunDebuff()
	return false
end

function modifier_ability_ensnare:IsPurgable()
	return true
end

function modifier_ability_ensnare:GetPriority()
	return MODIFIER_PRIORITY_HIGH
end

function modifier_ability_ensnare:CheckState()
	return {
		[MODIFIER_STATE_INVISIBLE] = false,
		[MODIFIER_STATE_ROOTED] = true
	}
end

function modifier_ability_ensnare:GetEffectName()
	return "particles/units/heroes/hero_siren/siren_net.vpcf"
end

function modifier_ability_ensnare:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end