LinkLuaModifier( "modifier_ability_lion_voodoo", "heroes/lion/voodoo" ,LUA_MODIFIER_MOTION_NONE )

if ability_lion_voodoo == nil then
    ability_lion_voodoo = class({})
end

--------------------------------------------------------------------------------

function ability_lion_voodoo:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if target:TriggerSpellAbsorb(self) then return end

    local duration = self:GetSpecialValueFor("duration")

    EmitSoundOn("Hero_Lion.Voodoo", target)

    if not target:IsIllusion() then
        target:AddNewModifier(caster, self, "modifier_ability_lion_voodoo", {duration = duration})

        local partname = "particles/units/heroes/hero_lion/lion_spell_voodoo.vpcf"
        local part = ParticleManager:CreateParticle(partname, PATTACH_ABSORIGIN_FOLLOW, target)
        ParticleManager:ReleaseParticleIndex(part)
        
        EmitSoundOn("Hero_Lion.Hex.Target", target)
    else
        target:Kill(self, caster)
    end
end


--------------------------------------------------------------------------------


modifier_ability_lion_voodoo = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE,
            MODIFIER_PROPERTY_MODEL_CHANGE
        }
    end,
    CheckState              = function(self)
        return {
            [ MODIFIER_STATE_HEXED ] = true,
            [ MODIFIER_STATE_MUTED ] = true,
            [ MODIFIER_STATE_DISARMED ] = true,
            [ MODIFIER_STATE_SILENCED ] = true,
            [ MODIFIER_STATE_BLOCK_DISABLED ] = true,
            [ MODIFIER_STATE_EVADE_DISABLED ] = true,
            [ MODIFIER_STATE_PASSIVES_DISABLED ] = true
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_lion_voodoo:OnCreated()
    self.movespeed = self:GetAbility():GetSpecialValueFor("movespeed")
end

--------------------------------------------------------------------------------

function modifier_ability_lion_voodoo:GetModifierMoveSpeedOverride() return self.movespeed end
function modifier_ability_lion_voodoo:GetModifierModelChange() return "models/props_gameplay/frog.vmdl" end