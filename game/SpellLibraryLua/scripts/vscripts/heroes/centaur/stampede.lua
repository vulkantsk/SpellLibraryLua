ability_stampede = class({})
LinkLuaModifier('modifier_ability_stampede_buff', 'heroes/centaur/stampede', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_ability_stampede_debuff', 'heroes/centaur/stampede', LUA_MODIFIER_MOTION_NONE)
function ability_stampede:OnSpellStart()

    local caster = self:GetCaster()

    EmitSoundOn("Hero_Centaur.Stampede.Cast", caster)


    local duration = self:GetSpecialValueFor("duration")
    caster:StartGesture(ACT_DOTA_CENTAUR_STAMPEDE)

    local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
    caster:GetAbsOrigin(),
    nil,
    FIND_UNITS_EVERYWHERE,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false)

    for _,enemy in pairs(enemies) do
        enemy.__ability_stampede__ = nil
    end

    -- Find all allied heroes and player controlled creeps
    local allies = FindUnitsInRadius(caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        FIND_UNITS_EVERYWHERE, 
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED,
        FIND_ANY_ORDER,
        false)

    -- Give them haste buff
    for _,ally in pairs (allies) do
        ally:AddNewModifier(caster, self, "modifier_ability_stampede_buff", {duration = duration})
    end

end

-- Original: https://github.com/EarthSalamander42/dota_imba/blob/4466b4c94dde75ba438a9ea816bb5ce4ffe3de38/game/dota_addons/dota_imba_reborn/scripts/vscripts/components/abilities/heroes/hero_centaur.lua#L704-L851
modifier_ability_stampede_buff = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return true end,
})

function modifier_ability_stampede_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MIN,
	}
end

function modifier_ability_stampede_buff:GetModifierMoveSpeed_AbsoluteMin()
	return 550
end

function modifier_ability_stampede_buff:CheckState()
	return {[MODIFIER_STATE_NO_UNIT_COLLISION] = true}
end

function modifier_ability_stampede_buff:GetEffectName()
	return "particles/units/heroes/hero_centaur/centaur_stampede_overhead.vpcf"
end

function modifier_ability_stampede_buff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_ability_stampede_buff:OnCreated()
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
    self.parent = self:GetParent()
    
    self.strength_damage = self.caster:GetStrength() * (self.ability:GetSpecialValueFor("strength_damage"))
    self.slow_movement_speed = self.ability:GetSpecialValueFor("slow_movement_speed")
    self.radius = self.ability:GetSpecialValueFor("radius")
    self.slow_duration = self.ability:GetSpecialValueFor("slow_duration")


    self.nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_centaur/centaur_stampede.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
    ParticleManager:SetParticleControl(self.nfx, 0, self.parent:GetAbsOrigin())
    self:AddParticle(self.nfx, false, false, -1, false, false)
    self:StartIntervalThink(0.1)

end

function modifier_ability_stampede_buff:OnIntervalThink()
	if IsServer() then
		-- Look for nearby enemies
		local enemies = FindUnitsInRadius(self.caster:GetTeamNumber(),
			self.parent:GetAbsOrigin(),
			nil,
			self.radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false)

		-- If enemy wasn't trampled before, trample it now
		for _,enemy in pairs(enemies) do
			if not enemy:IsMagicImmune() and not enemy.__ability_stampede__ then
				-- Mark it as trampled
				enemy.__ability_stampede__ = true

				-- Deal damage
				ApplyDamage({
                    victim = enemy,
                    attacker = self.parent,
                    damage = self.strength_damage,
                    damage_type = DAMAGE_TYPE_MAGICAL,
                    ability = self.ability
                })

                enemy:AddNewModifier(self.caster, self.ability, 'modifier_ability_stampede_debuff', {
                    duration = self.slow_duration,
                    slow = -self.ability:GetSpecialValueFor("slow_movement_speed"),
                })
			end
		end
	end
end

modifier_ability_stampede_debuff = class({})

function modifier_ability_stampede_debuff:OnCreated(data)
	self.ms_slow_pct = data.slow
end

function modifier_ability_stampede_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_ability_stampede_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.ms_slow_pct
end