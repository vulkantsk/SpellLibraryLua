LinkLuaModifier( "modifier_ability_spirit_walk_thinker", "heroes/grimstroke/spirit_walk", LUA_MODIFIER_MOTION_HORIZONTAL )
LinkLuaModifier( "modifier_ability_spirit_walk_target", "heroes/grimstroke/spirit_walk", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_spirit_walk_debuff", "heroes/grimstroke/spirit_walk", LUA_MODIFIER_MOTION_NONE )

ability_spirit_walk = {}

function ability_spirit_walk:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if target:TriggerSpellAbsorb( self ) then return end

	local modifier = target:AddNewModifier(
		caster,
		self,
		"modifier_ability_spirit_walk_target",
		{}
	)
	local spawnPos = caster:GetOrigin() + caster:GetForwardVector() * 150
	local phantom = CreateUnitByName( "npc_dota_grimstroke_ink_creature", spawnPos, true, nil, nil, self:GetCaster():GetTeamNumber() )

	self.grimPEModifier = modifier

	phantom:AddNewModifier( caster, self, "modifier_ability_spirit_walk_thinker", {} )

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_grimstroke/grimstroke_cast_phantom.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		caster
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Grimstroke.InkCreature.Cast", caster )
end

function ability_spirit_walk:OnProjectileHit( target, location )
	self:EndCooldown()

	EmitSoundOn( "Hero_Grimstroke.InkCreature.Returned", self:GetCaster() )
end

modifier_ability_spirit_walk_debuff = {}

function modifier_ability_spirit_walk_debuff:IsHidden()
	return false
end

function modifier_ability_spirit_walk_debuff:IsDebuff()
	return true
end

function modifier_ability_spirit_walk_debuff:IsStunDebuff()
	return false
end

function modifier_ability_spirit_walk_debuff:IsPurgable()
	return false
end

function modifier_ability_spirit_walk_debuff:OnCreated( kv )
	if IsServer() then
		self:SetStackCount( 1 )
	end
end

function modifier_ability_spirit_walk_debuff:OnRefresh( kv )
	if IsServer() then
		self:IncrementStackCount()
	end
end

function modifier_ability_spirit_walk_debuff:OnDestroy( kv )

end

function modifier_ability_spirit_walk_debuff:OnStackCountChanged( oldStack )
	if IsServer() then
		if self:GetStackCount()<1 then
			self:Destroy()
		end
	end
end

function modifier_ability_spirit_walk_debuff:CheckState()
	return {
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_PROVIDES_VISION] = true,
	}
end

function modifier_ability_spirit_walk_debuff:GetEffectName()
	return "particles/generic_gameplay/generic_silenced.vpcf"
end

function modifier_ability_spirit_walk_debuff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

modifier_ability_spirit_walk_target = {}

function modifier_ability_spirit_walk_target:IsHidden()
	return false
end

function modifier_ability_spirit_walk_target:IsDebuff()
	return true
end

function modifier_ability_spirit_walk_target:IsStunDebuff()
	return false
end

function modifier_ability_spirit_walk_target:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ability_spirit_walk_target:IsPurgable()
	return false
end

function modifier_ability_spirit_walk_target:OnCreated( kv )
	if IsServer() then
		self.silence = false
	end
end

function modifier_ability_spirit_walk_target:CheckState()
	return { [MODIFIER_STATE_PROVIDES_VISION] = true }
end

function modifier_ability_spirit_walk_target:GetEffectName()
	return "particles/units/heroes/hero_grimstroke/grimstroke_phantom_marker.vpcf"
end

function modifier_ability_spirit_walk_target:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

modifier_ability_spirit_walk_thinker = {}

function modifier_ability_spirit_walk_thinker:IsHidden()
	return true
end

function modifier_ability_spirit_walk_thinker:IsDebuff()
	return false
end

function modifier_ability_spirit_walk_thinker:IsPurgable()
	return false
end

function modifier_ability_spirit_walk_thinker:OnCreated( kv )
	if IsServer() then
		self.target_modifier = self:GetAbility().grimPEModifier
		self.target = self.target_modifier:GetParent()	
		self.speed = self:GetAbility():GetSpecialValueFor( "speed" )
		self.latch_offset = self:GetAbility():GetSpecialValueFor( "latched_unit_offset" )
		self.latch_duration = self:GetAbility():GetSpecialValueFor( "latch_duration" )
		self.tick_interval = self:GetAbility():GetSpecialValueFor( "tick_interval" )
		local tick_damage = self:GetAbility():GetSpecialValueFor( "damage_per_tick" )
		self.pop_damage = self:GetAbility():GetSpecialValueFor( "pop_damage" )
		self.return_projectile = "particles/units/heroes/hero_grimstroke/grimstroke_phantom_return.vpcf"

		self.health = self:GetAbility():GetSpecialValueFor( "destroy_attacks" )
		self.hero_attack = self.health/self:GetAbility():GetSpecialValueFor( "destroy_attacks_tooltip" )
		self.max_health = self.health

		self.latching = false
		self.damageTable = {
			victim = self.target,
			attacker = self:GetCaster(),
			damage = tick_damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self:GetAbility(),
			damage_flags = DOTA_DAMAGE_FLAG_NONE,
		}

		if self:ApplyHorizontalMotionController() == false then
			self:Destroy()
		end

		local effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_grimstroke/grimstroke_phantom_ambient.vpcf",
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

		self:AddParticle(
			effect_cast,
			false,
			false,
			-1,
			false,
			false
		)

		EmitSoundOn( "Hero_Grimstroke.InkCreature.Spawn", self:GetParent() )
	end
end

function modifier_ability_spirit_walk_thinker:OnDestroy( kv )
	if IsServer() then
		self:GetParent():InterruptMotionControllers( true )

		if not self.latching then
			if not self.target_modifier:IsNull() then
				self.target_modifier:Destroy()
			end
		else
			if not self.modifier:IsNull() then
				self.modifier:DecrementStackCount()
			end
		end

		if self:GetParent():IsAlive() and not self.forcedKill then
			local info = {
				Target = self:GetCaster(),
				Source = self:GetParent(),
				Ability = self:GetAbility(),	
				
				EffectName = self.return_projectile,
				iMoveSpeed = self.speed,
				bDodgeable = true,		
			}
			ProjectileManager:CreateTrackingProjectile(info)

			self.damageTable.damage = self.pop_damage
			ApplyDamage( self.damageTable )

			local sound_damage = "Hero_Grimstroke.InkCreature.Damage"
			EmitSoundOn( sound_damage, self:GetParent() )

			UTIL_Remove( self:GetParent() )
			return
		end

		local effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_grimstroke/grimstroke_phantom_death.vpcf",
			PATTACH_ABSORIGIN_FOLLOW,
			self:GetParent()
		)
		ParticleManager:ReleaseParticleIndex( effect_cast )

		EmitSoundOn( "Hero_Grimstroke.InkCreature.Death", self:GetParent() )

		self:GetParent():ForceKill( false )
	end
end

function modifier_ability_spirit_walk_thinker:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_EVENT_ON_ATTACKED,
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_ability_spirit_walk_thinker:GetModifierIncomingDamage_Percentage()
	return -100
end

function modifier_ability_spirit_walk_thinker:OnAttacked( params )
	if params.target~=self:GetParent() then return end

	if params.attacker:IsHero() then
		self.health = math.max(self.health - self.hero_attack, 0)
	else
		self.health = math.max(self.health - 1, 0)
	end

	self:GetParent():SetHealth( self.health/self.max_health * self:GetParent():GetMaxHealth() )

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_grimstroke/grimstroke_phantom_attacked.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self:GetParent()
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )
end

function modifier_ability_spirit_walk_thinker:GetOverrideAnimation()
	if self.latching then
	    return ACT_DOTA_CAPTURE
	else
	    return ACT_DOTA_RUN
	end
end

function modifier_ability_spirit_walk_thinker:CheckState()
	return { [MODIFIER_STATE_MAGIC_IMMUNE] = true }
end

function modifier_ability_spirit_walk_thinker:OnIntervalThink()
	ApplyDamage( self.damageTable )
	EmitSoundOn( "Hero_Grimstroke.InkCreature.Attack", self:GetParent() )
end

function modifier_ability_spirit_walk_thinker:UpdateHorizontalMotion( me, dt )
	if self.target:IsInvisible() or self.target:IsMagicImmune() or self.target:IsInvulnerable() then
		self.forcedKill = true
		self:Destroy()
		return
	end

	if not self.latching then
		if (self.target:GetOrigin()-self:GetParent():GetOrigin()):Length2D()<self.latch_offset then
			self:SetLatching()
		end
		self:Charge( me, dt )
	else
		self:Latch( me, dt )
	end
end

function modifier_ability_spirit_walk_thinker:OnHorizontalMotionInterrupted()
	if IsServer() then
		self:Destroy()
	end
end

function modifier_ability_spirit_walk_thinker:Charge( me, dt )
	local parent = self:GetParent()
	local pos = self:GetParent():GetOrigin()
	local targetpos = self.target:GetOrigin()

	local direction = targetpos-pos
	direction.z = 0		
	local target = pos + direction:Normalized() * (self.speed*dt)

	parent:SetOrigin( target )
	parent:FaceTowards( targetpos )
end

function modifier_ability_spirit_walk_thinker:Latch( me, dt )
	local target = self.target:GetOrigin() + self.target:GetForwardVector()*self.latch_offset

	self:GetParent():SetOrigin( target )
	self:GetParent():FaceTowards(self.target:GetOrigin())
end

function modifier_ability_spirit_walk_thinker:SetLatching()
	self.latching = true
	self:SetStackCount( 1 )

	self.target_modifier:Destroy()

	self.modifier = self.target:AddNewModifier(
		self:GetCaster(),
		self:GetAbility(),
		"modifier_ability_spirit_walk_debuff",
		{ duration = self.latch_duration }
	)

	self:SetDuration( self.latch_duration, false )
	self:StartIntervalThink( self.tick_interval )

	EmitSoundOn( "Hero_Grimstroke.InkCreature.Attach", self:GetParent() )
end
function modifier_ability_spirit_walk_thinker:OnStackCountChanged( oldCount )
	if IsClient() then
		self.latching = true
	end
end