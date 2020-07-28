LinkLuaModifier( "modifier_ability_omniknight_repel", "heroes/omniknight/repel" ,LUA_MODIFIER_MOTION_NONE )

if ability_omniknight_repel == nil then
    ability_omniknight_repel = class({})
end

--------------------------------------------------------------------------------

function ability_omniknight_repel:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local duration = self:GetSpecialValueFor("duration")

    target:AddNewModifier(caster, self, "modifier_ability_omniknight_repel", {duration=duration})

    target:Purge(false, true, false, true, true)

    if caster:GetName() == "npc_dota_hero_omniknight" then
        if target ~= caster then
            caster:EmitSound("omniknight_omni_ability_repel_0"..math.random(1,6))
        else
            local responses = {"omniknight_omni_ability_repel_01", "omniknight_omni_ability_repel_05", "omniknight_omni_ability_repel_06"}
            
            caster:EmitSound(responses[RandomInt(1, #responses)])
        end
    end

    local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_repel_cast.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack2", Vector(0,0,0), true)
    ParticleManager:ReleaseParticleIndex(fx)

    EmitSoundOn("Hero_Omniknight.Repel", target)
end

--------------------------------------------------------------------------------


modifier_ability_omniknight_repel = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
        }
    end,
    GetEffectName           = function(self) return "particles/units/heroes/hero_omniknight/omniknight_heavenly_grace_buff.vpcf" end,
    GetEffectAttachType     = function(self) return PATTACH_ABSORIGIN_FOLLOW end,
    GetStatusEffectName     = function(self) return "particles/status_fx/status_effect_repel.vpcf" end,
    StatusEffectPriority    = function(self) return MODIFIER_PRIORITY_HIGH end,
})


--------------------------------------------------------------------------------

function modifier_ability_omniknight_repel:OnCreated()
    self.status_resistance = self:GetAbility():GetSpecialValueFor("status_resistance")
    self.bonus_str = self:GetAbility():GetSpecialValueFor("bonus_str")
    self.hp_regen = self:GetAbility():GetSpecialValueFor("hp_regen")
end

function modifier_ability_omniknight_repel:OnRefresh()
    self:OnCreated()
end

function modifier_ability_omniknight_repel:GetModifierStatusResistanceStacking() return self.status_resistance end
function modifier_ability_omniknight_repel:GetModifierBonusStats_Strength() return self.bonus_str end
function modifier_ability_omniknight_repel:GetModifierConstantHealthRegen() return self.hp_regen end