LinkLuaModifier( "modifier_ability_bloodseeker_thirst", "heroes/bloodseeker/bloodseeker_thirst" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_bloodseeker_thirst_vision", "heroes/bloodseeker/bloodseeker_thirst" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_bloodseeker_thirst_speed", "heroes/bloodseeker/bloodseeker_thirst" ,LUA_MODIFIER_MOTION_NONE )

if ability_bloodseeker_thirst == nil then
    ability_bloodseeker_thirst = class({})
end

--------------------------------------------------------------------------------

function ability_bloodseeker_thirst:GetIntrinsicModifierName()
    return "modifier_ability_bloodseeker_thirst"
end

--------------------------------------------------------------------------------


modifier_ability_bloodseeker_thirst = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
            MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_bloodseeker_thirst:OnRefresh()
    self.min_bonus_pct = self:GetAbility():GetSpecialValueFor("min_bonus_pct")
    self.max_bonus_pct = self:GetAbility():GetSpecialValueFor("max_bonus_pct")
    self.visibility_threshold_pct = self:GetAbility():GetSpecialValueFor("visibility_threshold_pct")
    self.bonus_movement_speed = self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
    self.bonus_attack_speed = self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end 

function modifier_ability_bloodseeker_thirst:OnCreated()
    self.min_bonus_pct = self:GetAbility():GetSpecialValueFor("min_bonus_pct")
    self.max_bonus_pct = self:GetAbility():GetSpecialValueFor("max_bonus_pct")
    self.visibility_threshold_pct = self:GetAbility():GetSpecialValueFor("visibility_threshold_pct")
    self.bonus_movement_speed = self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
    self.bonus_attack_speed = self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
    self:StartIntervalThink(0.03)
end

function modifier_ability_bloodseeker_thirst:IsAura()
    return true
end

function modifier_ability_bloodseeker_thirst:GetModifierAura()
    return "modifier_ability_bloodseeker_thirst_vision"
end

function modifier_ability_bloodseeker_thirst:GetAuraRadius()
    return 99999
end

function modifier_ability_bloodseeker_thirst:GetAuraSearchTeam()    
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_ability_bloodseeker_thirst:GetAuraSearchType()    
    return DOTA_UNIT_TARGET_HERO
end

function modifier_ability_bloodseeker_thirst:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO
end

function modifier_ability_bloodseeker_thirst:GetAuraEntityReject(ent)
    if ent:GetHealthPercent() <= self.visibility_threshold_pct and not self:GetCaster():PassivesDisabled() then return false end
    return true
end

if IsServer() then
function modifier_ability_bloodseeker_thirst:OnIntervalThink()
    local caster = self:GetCaster()

    self.thirst_visioners = 0
    local stacks = 0

    local all = FindUnitsInRadius(caster:GetTeamNumber(), 
    caster:GetAbsOrigin(), 
    nil, 
    99999,
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    DOTA_UNIT_TARGET_HERO, 
    DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_DEAD,
    FIND_ANY_ORDER, 
    false)

    for _, hero in pairs(all) do
        local hero_pct = hero:GetHealthPercent()

        if not self:GetCaster():PassivesDisabled() then
            if hero_pct <= self.min_bonus_pct and hero:IsAlive() then
                local add = self.min_bonus_pct - hero_pct
                if add > (self.min_bonus_pct - self.max_bonus_pct) then
                    add = self.min_bonus_pct - self.max_bonus_pct
                end

                stacks = stacks + add
            end
            if hero:HasModifier("modifier_ability_bloodseeker_thirst_vision") and not hero:IsAlive() then
                stacks = stacks + self.min_bonus_pct - self.max_bonus_pct
            end
        end

        if hero_pct <= self.visibility_threshold_pct and hero:HasModifier("modifier_ability_bloodseeker_thirst_vision") then
            self.thirst_visioners = self.thirst_visioners + 1
        end
    end

    if self.thirst_visioners >= 1 then
        if not caster:HasModifier("modifier_ability_bloodseeker_thirst_speed") then
            caster:AddNewModifier(caster, self:GetAbility(), "modifier_ability_bloodseeker_thirst_speed", {})
        end
    else
        if caster:HasModifier("modifier_ability_bloodseeker_thirst_speed") then
            caster:RemoveModifierByName("modifier_ability_bloodseeker_thirst_speed")
        end
    end

    self:SetStackCount(stacks)
end
end

function modifier_ability_bloodseeker_thirst:GetModifierAttackSpeedBonus_Constant() return self.bonus_attack_speed / (self.min_bonus_pct - self.max_bonus_pct) * self:GetStackCount() end

function modifier_ability_bloodseeker_thirst:GetModifierMoveSpeedBonus_Percentage() return self.bonus_movement_speed / (self.min_bonus_pct - self.max_bonus_pct) * self:GetStackCount() end

function modifier_ability_bloodseeker_thirst:GetModifierIgnoreMovespeedLimit() if not self:GetParent():PassivesDisabled() then return 1 end return 0 end

--------------------------------------------------------------------------------


modifier_ability_bloodseeker_thirst_vision = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
            MODIFIER_EVENT_ON_DEATH
        }
    end,
    CheckState              = function(self)
        return {
            [MODIFIER_STATE_INVISIBLE] = false
        }
    end,
    GetEffectName           = function(self) return "particles/units/heroes/hero_bloodseeker/bloodseeker_vision.vpcf" end,
    GetEffectAttachType     = function(self) return PATTACH_ABSORIGIN_FOLLOW end,
    GetStatusEffectName     = function(self) return "particles/status_fx/status_effect_thirst_vision.vpcf" end,
    StatusEffectPriority    = function(self) return 8 end,
    GetPriority             = function(self) return MODIFIER_PRIORITY_HIGH end,
})


--------------------------------------------------------------------------------

function modifier_ability_bloodseeker_thirst_vision:GetModifierProvidesFOWVision() return 1 end

function modifier_ability_bloodseeker_thirst_vision:OnCreated()
    self.linger_duration = self:GetAbility():GetSpecialValueFor("linger_duration")
end

function modifier_ability_bloodseeker_thirst_vision:OnDeath(k)
    if k.unit == self:GetParent() then
        if not self:GetParent():IsReincarnating() then
            self:SetDuration(self.linger_duration, true)
        end
    end
end

--------------------------------------------------------------------------------


modifier_ability_bloodseeker_thirst_speed = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    GetEffectName           = function(self) return "particles/units/heroes/hero_bloodseeker/bloodseeker_thirst_owner.vpcf" end,
    GetEffectAttachType     = function(self) return PATTACH_ABSORIGIN_FOLLOW end,
})


--------------------------------------------------------------------------------
