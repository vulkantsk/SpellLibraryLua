LinkLuaModifier( "modifier_ability_dream_coil", "heroes/puck/dream_coil", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_dream_coil_thinker", "heroes/puck/dream_coil", LUA_MODIFIER_MOTION_NONE )

ability_dream_coil = {}

function ability_dream_coil:GetAOERadius()
	return self:GetSpecialValueFor( "coil_radius" )
end

function ability_dream_coil:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("coil_radius")
	local duration = self:GetSpecialValueFor("coil_duration")
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	if caster:HasScepter() then
		duration = self:GetSpecialValueFor("coil_duration_scepter")
	end

	local center = CreateModifierThinker(
		self:GetCaster(),
		self,
		"modifier_ability_dream_coil_thinker",
		{ duration = duration },
		point,
		self:GetCaster():GetTeamNumber(),
		false
	)

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		point,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		enemy:AddNewModifier(
			caster,
			self,
			"modifier_stunned",
			{ duration = stun_duration }
		)

		local modifier = enemy:AddNewModifier(
			caster,
			self,
			"modifier_ability_dream_coil",
			{
				duration = duration,
				coil_x = point.x,
				coil_y = point.y,
				coil_z = point.z,
			}
		)
	end

	EmitSoundOnLocationWithCaster( point, "Hero_Puck.Dream_Coil", self:GetCaster() )
end

modifier_ability_dream_coil = {}

function modifier_ability_dream_coil:IsHidden()
	return false
end

function modifier_ability_dream_coil:IsDebuff()
	return true
end

function modifier_ability_dream_coil:IsStunDebuff()
	return false
end

function modifier_ability_dream_coil:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE 
end

function modifier_ability_dream_coil:IsPurgable()
	return false
end

function modifier_ability_dream_coil:OnCreated( kv )
	self.center = Vector( kv.coil_x, kv.coil_y, kv.coil_z )
	if self:GetCaster():HasScepter() then
		self.break_radius = self:GetAbility():GetSpecialValueFor( "coil_break_radius" )
		self.break_stun = self:GetAbility():GetSpecialValueFor( "coil_stun_duration_scepter" )
		self.break_damage = self:GetAbility():GetSpecialValueFor( "coil_break_damage_scepter" )
		self.scepter = true
	else
		self.break_radius = self:GetAbility():GetSpecialValueFor( "coil_break_radius" )
		self.break_stun = self:GetAbility():GetSpecialValueFor( "coil_stun_duration" )
		self.break_damage = self:GetAbility():GetSpecialValueFor( "coil_break_damage" )
	end

	if IsServer() then
		local effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_puck/puck_dreamcoil_tether.vpcf",
			PATTACH_ABSORIGIN,
			self:GetParent()
		)
		ParticleManager:SetParticleControl( effect_cast, 0, self.center )
		ParticleManager:SetParticleControlEnt(
			effect_cast,
			1,
			self:GetParent(),
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			self:GetParent():GetOrigin(),
			true
		)

		self:AddParticle(
			effect_cast,
			false,
			false,
			-1,
			false,
			false
		)
	end
end

function modifier_ability_dream_coil:DeclareFunctions()
	return { MODIFIER_EVENT_ON_UNIT_MOVED }
end

function modifier_ability_dream_coil:OnUnitMoved( params )
	if IsServer() then
		if params.unit~=self:GetParent() then
			return
		end

		if (params.new_pos-self.center):Length2D()>self.break_radius then
			ApplyDamage({
				victim = self:GetParent(),
				attacker = self:GetCaster(),
				damage = self.break_damage,
				damage_type = DAMAGE_TYPE_MAGICAL,
				ability = self:GetAbility(),
			})

			if not self:GetParent():IsMagicImmune() or self.scepter then
				self:GetParent():AddNewModifier(
					self:GetCaster(),
					self,
					"modifier_generic_stunned_lua",
					{ duration = self.break_stun }
				)
			end

			EmitSoundOn( "Hero_Puck.Dream_Coil_Snap", self:GetParent() )

			self:Destroy()
		end
	end
end

modifier_ability_dream_coil_thinker = {}

function modifier_ability_dream_coil_thinker:IsHidden()
	return false
end

function modifier_ability_dream_coil_thinker:IsPurgable()
	return false
end

function modifier_ability_dream_coil_thinker:OnCreated( kv )
	if IsServer() then
		self.effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_puck/puck_dreamcoil.vpcf",
			PATTACH_WORLDORIGIN,
			self:GetParent()
		)
		ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetOrigin() )
	end
end

function modifier_ability_dream_coil_thinker:OnDestroy( kv )
	if IsServer() then
		ParticleManager:DestroyParticle( self.effect_cast, false )
		ParticleManager:ReleaseParticleIndex( self.effect_cast )
		UTIL_Remove( self:GetParent() )
	end
end