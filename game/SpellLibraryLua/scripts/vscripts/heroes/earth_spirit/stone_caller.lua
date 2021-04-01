LinkLuaModifier( "modifier_ability_stone_caller", "heroes/earth_spirit/stone_caller", LUA_MODIFIER_MOTION_NONE )

ability_stone_caller = {}

function ability_stone_caller:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local duration = self:GetSpecialValueFor("duration")
	local stone = CreateUnitByName( "npc_dota_earth_spirit_stone", point, true, nil, nil, self:GetCaster():GetTeamNumber() )

	stone:AddNewModifier(
		caster,
		self,
		"modifier_ability_stone_caller",
		nil
	)

	stone:AddNewModifier(
		caster,
		self,
		"modifier_ability_stone_caller",
		{ duration = duration }
	)
end

function ability_stone_caller:Spawn()
	if not IsServer() then return end
	self:SetLevel(1)
end

modifier_ability_stone_caller = {}

function modifier_ability_stone_caller:IsHidden()
	return true
end

function modifier_ability_stone_caller:IsPurgable()
	return false
end

function modifier_ability_stone_caller:OnCreated( kv )
	if IsServer() then
		local caster_origin = self:GetCaster():GetAbsOrigin()
		local effect_cast = ParticleManager:CreateParticle( 
			"particles/econ/items/earth_spirit/earth_spirit_vanquishingdemons_summons/espirit_stoneremnant_vanquishingdemons.vpcf",
			PATTACH_ABSORIGIN_FOLLOW,
			self:GetParent()
		)
		ParticleManager:SetParticleControl( effect_cast, 1, self:GetParent():GetAbsOrigin() )

		self:AddParticle(
			effect_cast,
			false,
			false,
			-1,
			false,
			false
		)

		EmitSoundOn( "Hero_EarthSpirit.StoneRemnant.Impact", self:GetParent() )
	end
end

function modifier_ability_stone_caller:OnDestroy( kv )
	if IsServer() then
		self:GetParent():ForceKill( false )
		EmitSoundOn( "Hero_EarthSpirit.StoneRemnant.Destroy", self:GetParent() )
	end
end

function modifier_ability_stone_caller:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_UNTARGETABLE] = true
	}
end