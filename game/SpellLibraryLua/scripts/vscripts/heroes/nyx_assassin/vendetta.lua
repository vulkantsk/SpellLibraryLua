LinkLuaModifier( "modifier_ability_nyx_assassin_vendetta", "heroes/nyx_assassin/vendetta" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_nyx_assassin_vendetta_break", "heroes/nyx_assassin/vendetta" ,LUA_MODIFIER_MOTION_NONE )

if ability_nyx_assassin_vendetta == nil then
    ability_nyx_assassin_vendetta = class({})
end

--------------------------------------------------------------------------------

function ability_nyx_assassin_vendetta:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    EmitSoundOn("Hero_NyxAssassin.Vendetta", caster)

    caster:AddNewModifier(caster, self, "modifier_ability_nyx_assassin_vendetta", {duration=duration})

    local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_vendetta_start.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(fx, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(fx, 1, caster:GetAbsOrigin())
end

--------------------------------------------------------------------------------


modifier_ability_nyx_assassin_vendetta = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_EVENT_ON_ATTACK_LANDED,
            MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
            MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
            MODIFIER_EVENT_ON_ABILITY_EXECUTED

        }
    end,
    CheckState              = function(self)
        return {
            [MODIFIER_STATE_CANNOT_MISS] = true,
            [MODIFIER_STATE_INVISIBLE] = true,
            [MODIFIER_STATE_NO_UNIT_COLLISION] = true
        }
    end,
    GetEffectName           = function(self) return "particles/units/heroes/hero_nyx_assassin/nyx_assassin_vendetta_speed.vpcf" end,
    GetEffectAttachType     = function(self) return PATTACH_ABSORIGIN_FOLLOW end,
})


--------------------------------------------------------------------------------

function modifier_ability_nyx_assassin_vendetta:OnCreated()
    self.movement_speed = self:GetAbility():GetSpecialValueFor("movement_speed")
    self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
    self.break_duration = self:GetAbility():GetSpecialValueFor("break_duration")
end

function modifier_ability_nyx_assassin_vendetta:OnAttackLanded(k)
    local target = k.target
    local attacker = k.attacker
    local caster = self:GetCaster()
    if attacker == caster then

        if target:IsBuilding() or target:IsOther() then self:Destroy() return end 

        target:AddNewModifier(caster, self:GetAbility(), "modifier_ability_nyx_assassin_vendetta_break", {duration=self.break_duration})

        local damageTable = {
            victim = target,
            attacker = caster, 
            damage = self.bonus_damage,
            damage_type = self:GetAbility():GetAbilityDamageType(),
            ability = self:GetAbility()
        }

        ApplyDamage(damageTable)

        SendOverheadEventMessage(target, OVERHEAD_ALERT_CRITICAL, target, self.bonus_damage, nil)

        self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_vendetta.vpcf", PATTACH_CUSTOMORIGIN, caster)
        ParticleManager:SetParticleControl(self.fx, 0, caster:GetAbsOrigin() )
        ParticleManager:SetParticleControl(self.fx, 1, target:GetAbsOrigin() )
        ParticleManager:SetParticleControlForward(self.fx, 0, caster:GetForwardVector())


        EmitSoundOn("Hero_NyxAssassin.Vendetta.Crit", target)

        self:Destroy()
    end
end

function modifier_ability_nyx_assassin_vendetta:OnAbilityExecuted(k)
    local ability = k.ability
    local caster = k.unit

    if caster == self:GetCaster() then
        if ability:GetName() == "ability_nyx_assassin_spiked_carapace" then return end

        self:Destroy()
    end
end

function modifier_ability_nyx_assassin_vendetta:GetModifierMoveSpeedBonus_Percentage() return self.movement_speed end
function modifier_ability_nyx_assassin_vendetta:GetModifierInvisibilityLevel() return 1.0 end
function modifier_ability_nyx_assassin_vendetta:GetActivityTranslationModifiers() return "vendetta" end

--------------------------------------------------------------------------------


modifier_ability_nyx_assassin_vendetta_break = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    CheckState              = function(self)
        return {
            [MODIFIER_STATE_PASSIVES_DISABLED] = true
        }
    end,
    GetEffectName           = function(self) return "particles/generic_gameplay/generic_break.vpcf" end,
    GetEffectAttachType     = function(self) return PATTACH_OVERHEAD_FOLLOW end,
})


--------------------------------------------------------------------------------