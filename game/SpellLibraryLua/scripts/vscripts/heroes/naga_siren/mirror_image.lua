LinkLuaModifier( "modifier_ability_mirror_image", "heroes/naga_siren/mirror_image", LUA_MODIFIER_MOTION_NONE )

ability_mirror_image = {}
ability_mirror_image.illusions = {}

function ability_mirror_image:OnSpellStart()
	local caster = self:GetCaster()
	local delay = self:GetSpecialValueFor( "invuln_duration" )

	caster:Stop()
	ProjectileManager:ProjectileDodge( caster )
	caster:Purge( false, true, false, false, false )

	caster:AddNewModifier(
		caster,
		self,
		"modifier_ability_mirror_image",
		{ duration = delay }
	)

	EmitSoundOn( "Hero_NagaSiren.MirrorImage", caster )
end

modifier_ability_mirror_image = {}

function modifier_ability_mirror_image:IsHidden()
	return true
end

function modifier_ability_mirror_image:IsDebuff()
	return false
end

function modifier_ability_mirror_image:IsStunDebuff()
	return false
end

function modifier_ability_mirror_image:IsPurgable()
	return false
end

function modifier_ability_mirror_image:OnCreated( kv )
	self.count = self:GetAbility():GetSpecialValueFor( "images_count" )
	self.duration = self:GetAbility():GetSpecialValueFor( "illusion_duration" )
	self.outgoing = self:GetAbility():GetSpecialValueFor( "outgoing_damage" )
	self.incoming = self:GetAbility():GetSpecialValueFor( "incoming_damage" )
	self.distance = 72

	if not IsServer() then return end
end

function modifier_ability_mirror_image:OnDestroy()
	if not IsServer() then return end

	for illusion,_ in pairs(self:GetAbility().illusions) do
		if not illusion:IsNull() then
			illusion:ForceKill( false )
		end

		self:GetAbility().illusions[ illusion ]	= nil	
	end

	local illusions = CreateIllusions(
		self:GetParent(),
		self:GetParent(),
		{
			outgoing_damage = self.outgoing,
			incoming_damage = self.incoming,
			duration = self.duration,
		},
		self.count,
		self.distance,
		true,
		true
	)

	for _,illusion in pairs(illusions) do
		self:GetAbility().illusions[ illusion ] = true
	end
end

function modifier_ability_mirror_image:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function modifier_ability_mirror_image:CreateIllusion()
	self:GetAbility().illusions = {}
end

function modifier_ability_mirror_image:GetEffectName()
	return "particles/units/heroes/hero_siren/naga_siren_mirror_image.vpcf"
end

function modifier_ability_mirror_image:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end