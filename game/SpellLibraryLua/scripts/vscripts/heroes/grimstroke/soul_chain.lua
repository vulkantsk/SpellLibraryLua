LinkLuaModifier( "modifier_ability_soul_chain", "heroes/grimstroke/soul_chain", LUA_MODIFIER_MOTION_NONE )

ability_soul_chain = {}

function ability_soul_chain:GetAOERadius()
	return self:GetSpecialValueFor( "chain_latch_radius" )
end

function ability_soul_chain:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if target:TriggerSpellAbsorb( self ) then return end

	local duration = self:GetSpecialValueFor( "chain_duration" )

	target:AddNewModifier(
		caster,
		self,
		"modifier_ability_soul_chain",
		{ 
			duration = duration,
			primary = true,
		 }
	)

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_grimstroke/grimstroke_cast_soulchain.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self:GetCaster()
	)

	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(),
		true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(),
		true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Grimstroke.SoulChain.Cast", self:GetCaster() )
end

modifier_ability_soul_chain = {}

function modifier_ability_soul_chain:IsHidden()
	return false
end

function modifier_ability_soul_chain:IsDebuff()
	return true
end

function modifier_ability_soul_chain:IsStunDebuff()
	return false
end

function modifier_ability_soul_chain:IsPurgable()
	return false
end

function modifier_ability_soul_chain:OnCreated( kv )
	if IsServer() then
		self.primary = (kv.primary==1)
		if kv.pair then
			self.pair = self:GetAbility().grimSoulbindModifier
		else
			self.pair = nil
		end

		self.slow = -self:GetAbility():GetSpecialValueFor( "movement_slow" )

		self.radius = self:GetAbility():GetSpecialValueFor( "chain_latch_radius" )
		self.buffer = self:GetAbility():GetSpecialValueFor( "leash_radius_buffer" )
		self.buffer_radius = self.radius - self.buffer
		self.break_radius = self:GetAbility():GetSpecialValueFor( "chain_break_distance" )

		self.search_tick = 0.1
		self.normal_ms_limit = 550
		self.limit = self.normal_ms_limit

		self:StartIntervalThink( self.search_tick )
		self:OnIntervalThink()

		local effect_cast1 = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_grimstroke/grimstroke_soulchain_debuff.vpcf",
			PATTACH_ABSORIGIN_FOLLOW,
			self:GetParent()
		)
		ParticleManager:SetParticleControlEnt(
			effect_cast1,
			2,
			self:GetParent(),
			PATTACH_ABSORIGIN_FOLLOW,
			nil,
			self:GetParent():GetAbsOrigin(),
			true
		)

		self:AddParticle(
			effect_cast1,
			false,
			false,
			-1,
			false,
			false
		)

		if self.primary then
			local effect_cast2 = ParticleManager:CreateParticle(
				"particles/units/heroes/hero_grimstroke/grimstroke_soulchain_marker.vpcf",
				PATTACH_OVERHEAD_FOLLOW,
				self:GetParent()
			)

			self:AddParticle(
				effect_cast2,
				false,
				false,
				-1,
				false,
				true
			)
		end

		EmitSoundOn( "Hero_Grimstroke.SoulChain.Target", target )
	end
end

function modifier_ability_soul_chain:OnRefresh( kv )
	if IsServer() then
		self.slow = -self:GetAbility():GetSpecialValueFor( "movement_slow" )

		if kv.pair then
			self.pair = self:GetAbility().grimSoulbindModifier
		end

		if not kv.duration then
			self:SetDuration( -1, true )
		else
			self:SetDuration( kv.duration, true )
		end

		if (kv.primary==1) and (not self.primary) then
			self.primary = true
			self.pair.primary = false
		end

		if self.primary and self.pair and (not self.pair:IsNull()) then
			self:GetAbility().grimSoulbindModifier = self
			self.pair = self.pair:GetParent():AddNewModifier(
				self:GetCaster(),
				self:GetAbility(),
				"modifier_ability_soul_chain",
				{
					primary = false
				}
			)
		end

	end
end

function modifier_ability_soul_chain:OnRemoved()
	if IsServer() then
		if self.primary and self.pair and not self.pair:IsNull() then
			ParticleManager:DestroyParticle( self.effect_cast, false )
			ParticleManager:ReleaseParticleIndex( self.effect_cast )
		end
	end
end

function modifier_ability_soul_chain:OnDestroy( kv )
	if IsServer() then
		if self.primary and self.pair and (not self.pair:IsNull()) then
			self.pair:Destroy()
		end
	end
end

function modifier_ability_soul_chain:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_LIMIT,
	}
end
function modifier_ability_soul_chain:OnAbilityFullyCast( params )
	if IsServer() then
		if not self.pair then return end
		if not params.target then return end
		if params.target~=self:GetParent() then return end
		if params.ability==self:GetAbility() then return end
		if params.ability.soulbind then return end
		if params.unit:GetTeamNumber()==self:GetParent():GetTeamNumber() then return end

		local ready = false
		if params.ability:IsCooldownReady() then
			ready = true
		end

		params.ability:EndCooldown()
		params.ability:RefundManaCost()
		params.ability.soulbind = true
		params.unit:SetCursorCastTarget( self.pair:GetParent() )
		params.ability:CastAbility()
		params.ability.soulbind = nil

		if not (params.ability:IsCooldownReady()==ready) then
			params.ability:EndCooldown()
		end

		local effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_grimstroke/grimstroke_soulchain_proc.vpcf",
			PATTACH_ABSORIGIN_FOLLOW,
			self:GetParent()
		)
		ParticleManager:SetParticleControlEnt(
			effect_cast,
			0,
			self:GetParent(),
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			Vector(),
			true
		)
		ParticleManager:SetParticleControlEnt(
			effect_cast,
			1,
			self.pair:GetParent(),
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			Vector(),
			true
		)
		ParticleManager:ReleaseParticleIndex( effect_cast )

		effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_grimstroke/grimstroke_soulchain_proc_tgt.vpcf",
			PATTACH_ABSORIGIN_FOLLOW,
			self:GetParent()
		)
		ParticleManager:SetParticleControlEnt(
			effect_cast,
			0,
			self:GetParent(),
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			Vector(),
			true
		)
		ParticleManager:ReleaseParticleIndex( effect_cast )

		effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_grimstroke/grimstroke_soulchain_proc_tgt.vpcf",
			PATTACH_ABSORIGIN_FOLLOW,
			self.pair:GetParent()
		)
		ParticleManager:SetParticleControlEnt(
			effect_cast,
			0,
			self.pair:GetParent(),
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			Vector(),
			true
		)
		ParticleManager:ReleaseParticleIndex( effect_cast )
	end
end

function modifier_ability_soul_chain:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_ability_soul_chain:GetModifierMoveSpeed_Limit()
	if IsServer() then
		return self.limit
	end
end

function modifier_ability_soul_chain:OnIntervalThink()
	if self.primary and not self.pair then
		self:FindPair()
	end

	if self.pair then
		self:Bind()
	end
end

function modifier_ability_soul_chain:FindPair()
	local heroes = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),
		self:GetParent():GetAbsOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_NO_INVIS,
		FIND_CLOSEST,
		false
	)

	local target = nil
	for _, hero in pairs(heroes) do
		if hero ~= self:GetParent() and not hero:HasModifier( "modifier_ability_soul_chain" ) then
			target = hero
			break
		end
	end

	if target then
		self:GetAbility().grimSoulbindModifier = self
		self.pair = target:AddNewModifier(
			self:GetCaster(),
			self:GetAbility(),
			"modifier_ability_soul_chain",
			{
				primary = false
			}
		)

		self.effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_grimstroke/grimstroke_soulchain.vpcf",
			PATTACH_ABSORIGIN_FOLLOW,
			self:GetParent()
		)
		ParticleManager:SetParticleControlEnt(
			self.effect_cast,
			0,
			self:GetParent(),
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			Vector(),
			true
		)
		ParticleManager:SetParticleControlEnt(
			self.effect_cast,
			1,
			self.pair:GetParent(),
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			Vector(),
			true
		)

		EmitSoundOn( "Hero_Grimstroke.SoulChain.Partner", self.pair:GetParent() )
	end
end

function modifier_ability_soul_chain:Bind()
	local vectorToPair = self.pair:GetParent():GetAbsOrigin() - self:GetParent():GetAbsOrigin()
	local facingAngle = self:GetParent():GetAnglesAsVector().y

	local angleToPair = VectorToAngles(vectorToPair).y
	local angleDifference = math.abs(AngleDiff( angleToPair, facingAngle ))

	local distanceToPair = vectorToPair:Length2D()

	if distanceToPair < self.buffer_radius then
		self.limit = self.normal_ms_limit
	elseif distanceToPair < self.break_radius then
		if angleDifference > 90 then
			local interpolate = math.min( (distanceToPair-self.buffer_radius)/self.buffer, 1 )

			self.limit = (1-interpolate) * self.normal_ms_limit

			if self.limit < 1 then
				self.limit = 0.01
			end
		else
			self.limit = self.normal_ms_limit
		end

		self:GetParent():InterruptMotionControllers( true )
	else
		self.limit = self.normal_ms_limit
		if self.primary then
			self.pair:Destroy()
			self.pair = nil
			ParticleManager:DestroyParticle( self.effect_cast, false )
			ParticleManager:ReleaseParticleIndex( self.effect_cast )
		end
	end
end