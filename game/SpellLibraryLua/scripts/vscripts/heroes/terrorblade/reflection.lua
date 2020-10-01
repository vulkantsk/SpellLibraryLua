ability_reflection = {}

LinkLuaModifier( "modifier_ability_reflection", "heroes/terrorblade/reflection", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_reflection_illusion", "heroes/terrorblade/reflection", LUA_MODIFIER_MOTION_NONE )


function ability_reflection:GetAOERadius()
	return self:GetSpecialValueFor( "range" )
end

function ability_reflection:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor( "range" )
	local duration = self:GetSpecialValueFor( "illusion_duration" )

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		point,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		0,
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		enemy:AddNewModifier(
			caster,
			self,
			"modifier_ability_reflection",
			{ duration = duration }
		)
	end
end

modifier_ability_reflection_illusion = {}

function modifier_ability_reflection_illusion:IsHidden()
	return true
end

function modifier_ability_reflection_illusion:IsDebuff()
	return false
end

function modifier_ability_reflection_illusion:IsPurgable()
	return false
end

function modifier_ability_reflection_illusion:OnCreated( kv )
	self.outgoing = self:GetAbility():GetSpecialValueFor( "illusion_outgoing_damage" )
end

function modifier_ability_reflection_illusion:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
	}
end

function modifier_ability_reflection_illusion:GetModifierMoveSpeed_Absolute()
	return 550
end

function modifier_ability_reflection_illusion:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
	}
end

function modifier_ability_reflection_illusion:GetStatusEffectName()
	return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_ability_reflection_illusion:StatusEffectPriority()
	return 100000
end

modifier_ability_reflection_illusion = {}

function modifier_ability_reflection_illusion:IsHidden()
	return true
end

function modifier_ability_reflection_illusion:IsDebuff()
	return false
end

function modifier_ability_reflection_illusion:IsPurgable()
	return false
end

function modifier_ability_reflection_illusion:OnCreated( kv )
	self.outgoing = self:GetAbility():GetSpecialValueFor( "illusion_outgoing_damage" )

	if not IsServer() then return end
end

function modifier_ability_reflection_illusion:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
	}

	return funcs
end

function modifier_ability_reflection_illusion:GetModifierMoveSpeed_Absolute()
	return 550
end

function modifier_ability_reflection_illusion:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
	}
end

function modifier_ability_reflection_illusion:GetStatusEffectName()
	return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_ability_reflection_illusion:StatusEffectPriority()
	return 100000
end

modifier_ability_reflection = {}

function modifier_ability_reflection:IsHidden()
	return false
end

function modifier_ability_reflection:IsDebuff()
	return true
end

function modifier_ability_reflection:IsStunDebuff()
	return false
end

function modifier_ability_reflection:IsPurgable()
	return true
end

function modifier_ability_reflection:OnCreated( kv )
	self.slow = -self:GetAbility():GetSpecialValueFor( "move_slow" )

	if not IsServer() then return end

	self.distance = 72

	local illusions = CreateIllusions(
		self:GetCaster(),
		self:GetParent(),
		{
			outgoing_damage = self.outgoing,
			duration = self:GetDuration(),
		},
		1,
		self.distance,
		false,
		true
	)
	local illusion = illusions[1]

	illusion:AddNewModifier(
		self:GetCaster(),
		self:GetAbility(),
		"modifier_ability_reflection_illusion",
		{ duration = self:GetDuration() }
	)

	self:GetAbility():SetContextThink( self:GetAbility():GetAbilityName(), function()
		local order = {
			UnitIndex = illusion:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = self:GetParent():entindex(),
		}
		ExecuteOrderFromTable( order )
	end, FrameTime())

	self.illusions = self.illusions or {}
	self.illusions[ illusion ] = true

	self:StartIntervalThink( 0.1 )
end

function modifier_ability_reflection:OnRefresh( kv )
	self:OnCreated( kv )	
end

function modifier_ability_reflection:OnDestroy()
	if not IsServer() then return end

	for illusion,_ in pairs( self.illusions ) do
		if not illusion:IsNull() then
			illusion:ForceKill( false )
		end
	end
end

function modifier_ability_reflection:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_ability_reflection:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_ability_reflection:OnIntervalThink()
	local parent = self:GetParent()
	local origin = parent:GetOrigin()
	local seen = self:GetCaster():CanEntityBeSeenByMyTeam( parent )

	if not seen then
		for illusion,_ in pairs( self.illusions ) do
			if not illusion:IsNull() and (illusion:GetOrigin()-origin):Length2D()>self.distance/2 then
				illusion:MoveToPosition( origin )
			end
		end
	else
		for illusion,_ in pairs( self.illusions ) do
			if not illusion:IsNull() and illusion:GetAggroTarget()~=parent then
				local order = {
					UnitIndex = illusion:entindex(),
					OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
					TargetIndex = parent:entindex(),
				}
				ExecuteOrderFromTable( order )
			end
		end
	end
end

function modifier_ability_reflection:GetEffectName()
	return "particles/units/heroes/hero_terrorblade/terrorblade_reflection_slow.vpcf"
end

function modifier_ability_reflection:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end