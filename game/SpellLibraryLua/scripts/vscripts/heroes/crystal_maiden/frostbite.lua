ability_frostbite = class({})
LinkLuaModifier( "modifier_ability_frostbite_debuff", "heroes/crystal_maiden/frostbite", LUA_MODIFIER_MOTION_NONE )

function ability_frostbite:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- set duration
	local bduration = self:GetSpecialValueFor("duration")
	if target:IsCreep() and (target:GetLevel()<=6) then
		bduration = self:GetSpecialValueFor("creep_duration")
    end
    
	-- Add modifier
	target:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_ability_frostbite_debuff", -- modifier name
		{ duration = bduration } -- kv
	)

	ProjectileManager:CreateTrackingProjectile({
		Target = target,
		Source = caster,
		Ability = self,	
		EffectName = "particles/units/heroes/hero_crystalmaiden/maiden_frostbite.vpcf",
		iMoveSpeed = 100,
		vSourceLoc= caster:GetAbsOrigin(),           
		bDodgeable = false,                               
	})
end


modifier_ability_frostbite_debuff = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ability_frostbite_debuff:IsHidden()
	return false
end

function modifier_ability_frostbite_debuff:IsDebuff()
	return true
end

function modifier_ability_frostbite_debuff:IsStunDebuff()
	return false
end

function modifier_ability_frostbite_debuff:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_ability_frostbite_debuff:OnCreated( kv )
	-- references
    local tick_damage = self:GetAbility():GetSpecialValueFor( self:GetParent():IsCreep() and 'creep_total_damage' or "total_damage" ) -- special value
    self.interval =self:GetAbility():GetSpecialValueFor( "tick_interval" ) 
    tick_damage = tick_damage / (self:GetDuration() /  self.interval )

	if IsServer() then
		-- Apply Damage	 
		self.damageTable = {
			victim = self:GetParent(),
			attacker = self:GetCaster(),
			damage = tick_damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self, --Optional.
		}

		-- Start interval
		self:StartIntervalThink( self.interval )

		-- Play Effects
		self.sound_target = "hero_Crystal.frostbite"
		EmitSoundOn( self.sound_target, self:GetParent() )
	end
end

function modifier_ability_frostbite_debuff:OnRefresh( kv )
	self:OnCreated()
end

function modifier_ability_frostbite_debuff:OnDestroy()
	StopSoundOn( self.sound_target, self:GetParent() )
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_ability_frostbite_debuff:CheckState()
	local state = {
	[MODIFIER_STATE_DISARMED] = true,
	[MODIFIER_STATE_ROOTED] = true,
	[MODIFIER_STATE_INVISIBLE] = false,
	}

	return state
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_ability_frostbite_debuff:OnIntervalThink()
	ApplyDamage( self.damageTable )
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_ability_frostbite_debuff:GetEffectName()
	return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf"
end

function modifier_ability_frostbite_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end