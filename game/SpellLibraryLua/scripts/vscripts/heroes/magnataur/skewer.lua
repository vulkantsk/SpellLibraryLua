LinkLuaModifier( "modifier_ability_skewer", "heroes/magnataur/skewer", LUA_MODIFIER_MOTION_HORIZONTAL )
LinkLuaModifier( "modifier_ability_skewer_debuff", "heroes/magnataur/skewer", LUA_MODIFIER_MOTION_HORIZONTAL )
LinkLuaModifier( "modifier_ability_skewer_slow", "heroes/magnataur/skewer", LUA_MODIFIER_MOTION_NONE )

ability_skewer = {}

function ability_skewer:GetCooldown( level )
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor( "skewer_cooldown" )
	end

	return self.BaseClass.GetCooldown( self, level )
end

function ability_skewer:GetManaCost( level )
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor( "skewer_manacost" )
	end

	return self.BaseClass.GetManaCost( self, level )
end

function ability_skewer:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	local maxrange = self:GetSpecialValueFor( "range" )

	local direction = point-caster:GetOrigin()
	if direction:Length2D() > maxrange then
		direction.z = 0
		direction = direction:Normalized()

		point = caster:GetOrigin() + direction * maxrange
	end

	caster:AddNewModifier(
		caster,
		self,
		"modifier_ability_skewer",
		{
			x = point.x,
			y = point.y,
		}
	)
end

modifier_ability_skewer = {}

function modifier_ability_skewer:IsHidden()
	return false
end

function modifier_ability_skewer:IsDebuff()
	return false
end

function modifier_ability_skewer:IsStunDebuff()
	return false
end

function modifier_ability_skewer:IsPurgable()
	return false
end

function modifier_ability_skewer:OnCreated( kv )
	self.radius = self:GetAbility():GetSpecialValueFor( "skewer_radius" )
	self.speed = self:GetAbility():GetSpecialValueFor( "skewer_speed" )
	self.tree = self:GetAbility():GetSpecialValueFor( "tree_radius" )

	if not IsServer() then return end

	self.origin = self:GetParent():GetOrigin()
	self.point = Vector( kv.x, kv.y, 0 )
	self.direction = self.point - self.origin
	self.distance = self.direction:Length2D()
	self.direction.z = 0
	self.direction = self.direction:Normalized()
	self.enemies = {}

	if not self:ApplyHorizontalMotionController() then
		self:Destroy()
		return
	end

	self:PlayEffects()
end

function modifier_ability_skewer:OnRefresh( kv )
	self:OnCreated( kv )
end

function modifier_ability_skewer:OnRemoved()
end

function modifier_ability_skewer:OnDestroy()
	if not IsServer() then return end
	self:GetParent():RemoveHorizontalMotionController( self )
end

function modifier_ability_skewer:DeclareFunctions()
	return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION }
end

function modifier_ability_skewer:GetOverrideAnimation()
	return ACT_DOTA_MAGNUS_SKEWER_START
end

function modifier_ability_skewer:CheckState()
	return { [MODIFIER_STATE_STUNNED] = true }
end

function modifier_ability_skewer:UpdateHorizontalMotion( me, dt )
	local origin = me:GetOrigin()
	local target = origin + self.direction*self.speed*dt
	me:SetOrigin( target )

	GridNav:DestroyTreesAroundPoint( origin, self.tree, false )

	local dist = (target-self.origin):Length2D()
	if dist>self.distance then
		self:Destroy()
	end
end

function modifier_ability_skewer:OnHorizontalMotionInterrupted()
	self:Destroy()
end

function modifier_ability_skewer:IsAura()
	return true
end

function modifier_ability_skewer:GetModifierAura()
	return "modifier_ability_skewer_debuff"
end

function modifier_ability_skewer:GetAuraRadius()
	return self.radius
end

function modifier_ability_skewer:GetAuraDuration()
	return 0.1
end

function modifier_ability_skewer:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_ability_skewer:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO
end

function modifier_ability_skewer:GetAuraSearchFlags()
	return 0
end

function modifier_ability_skewer:GetAuraEntityReject( hEntity )
	if IsServer() then
		
	end

	return false
end

function modifier_ability_skewer:PlayEffects()
	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_magnataur/magnataur_skewer.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self:GetParent()
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		self:GetParent(),
		PATTACH_POINT_FOLLOW,
		"attach_horn",
		Vector(),
		true
	)
	ParticleManager:SetParticleControlForward( effect_cast, 1, self:GetParent():GetForwardVector() )

	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		false
	)

	EmitSoundOn( "Hero_Magnataur.Skewer.Cast", self:GetParent() )
end

modifier_ability_skewer_debuff = {}

function modifier_ability_skewer_debuff:IsHidden()
	return false
end

function modifier_ability_skewer_debuff:IsDebuff()
	return true
end

function modifier_ability_skewer_debuff:IsStunDebuff()
	return true
end

function modifier_ability_skewer_debuff:IsPurgable()
	return true
end

function modifier_ability_skewer_debuff:OnCreated( kv )
	if not IsServer() then return end

	self.dist = self:GetAbility():GetSpecialValueFor( "skewer_radius" )
	self.damage = self:GetAbility():GetSpecialValueFor( "skewer_damage" )
	self.duration = self:GetAbility():GetSpecialValueFor( "slow_duration" )

	if not self:ApplyHorizontalMotionController() then
		self:Destroy()
		return
	end

	EmitSoundOn( "Hero_Magnataur.Skewer.Target", self:GetParent() )
end

function modifier_ability_skewer_debuff:OnDestroy()
	if not IsServer() then return end
	self:GetParent():RemoveHorizontalMotionController( self )

	self:GetParent():AddNewModifier(
		self:GetCaster(),
		self:GetAbility(),
		"modifier_ability_skewer_slow",
		{ duration = self.duration }
	)

	local damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = self.damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self:GetAbility()
	}
	ApplyDamage(damageTable)
end

function modifier_ability_skewer_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION }
end

function modifier_ability_skewer_debuff:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end

function modifier_ability_skewer_debuff:CheckState()
	return { [MODIFIER_STATE_STUNNED] = true }
end

function modifier_ability_skewer_debuff:UpdateHorizontalMotion( me, dt )
	local caster = self:GetCaster()
	local target = caster:GetOrigin() + caster:GetForwardVector() * self.dist

	me:SetOrigin( target )
end

function modifier_ability_skewer_debuff:OnHorizontalMotionInterrupted()
	self:Destroy()
end

modifier_ability_skewer_slow = {}

function modifier_ability_skewer_slow:IsHidden()
	return false
end

function modifier_ability_skewer_slow:IsDebuff()
	return true
end

function modifier_ability_skewer_slow:IsStunDebuff()
	return false
end

function modifier_ability_skewer_slow:IsPurgable()
	return true
end

function modifier_ability_skewer_slow:OnCreated( kv )
	self.as_slow = -self:GetAbility():GetSpecialValueFor( "tool_attack_slow" )
	self.ms_slow = -self:GetAbility():GetSpecialValueFor( "slow_pct" )
end

function modifier_ability_skewer_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_ability_skewer_slow:GetModifierAttackSpeedBonus_Constant()
	return self.as_slow
end

function modifier_ability_skewer_slow:GetModifierMoveSpeedBonus_Percentage()
	return self.ms_slow
end

function modifier_ability_skewer_slow:GetEffectName()
	return "particles/units/heroes/hero_magnataur/magnataur_skewer_debuff.vpcf"
end

function modifier_ability_skewer_slow:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end