ability_drunken_brawler = class({})
LinkLuaModifier('modifier_ability_drunken_brawler_buff', 'heroes/brewmaster/drunken_brawler', LUA_MODIFIER_MOTION_NONE)
function ability_drunken_brawler:OnSpellStart()
	self:GetCaster():EmitSound("Hero_Brewmaster.Brawler.Cast")

	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_ability_drunken_brawler_buff", {duration = self:GetSpecialValueFor("duration")})
end

modifier_ability_drunken_brawler_buff = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return true end,
    DeclareFunctions        = function(self) return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_EVASION_CONSTANT
    } end,
    GetModifierMoveSpeedBonus_Percentage = function(self) 	
        if math.floor(self:GetElapsedTime()) % 2 == 0 then
            return self.max_movement
        else
            return self.min_movement
        end  
    end,
    GetModifierEvasion_Constant              = function(self) return self.dodge_chance end,
    GetModifierPreAttack_CriticalStrike = function(self) if RollPercentage(self.crit_chance) then return self.crit_multiplier end end,
    GetEffectName = function(self) return "particles/units/heroes/hero_brewmaster/brewmaster_drunkenbrawler_crit.vpcf" end,
    GetStatusEffectName     = function(self) return "particles/status_fx/status_effect_drunken_brawler.vpcf" end,
    StatusEffectPriority    = function(self) return MODIFIER_PRIORITY_HIGH end,
})

function modifier_ability_drunken_brawler_buff:OnCreated()
    local ability = self:GetAbility()
    self.dodge_chance = ability:GetSpecialValueFor('dodge_chance')
    self.crit_chance = ability:GetSpecialValueFor('crit_chance')
    self.crit_multiplier = ability:GetSpecialValueFor('crit_multiplier')
    self.min_movement = ability:GetSpecialValueFor('min_movement')
    self.max_movement = ability:GetSpecialValueFor('max_movement')
    self:OnIntervalThink()
	local evade_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_brewmaster/brewmaster_drunkenbrawler_evade.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    self:AddParticle(evade_particle, false, false, MODIFIER_PRIORITY_SUPER_ULTRA, true, true)
end

