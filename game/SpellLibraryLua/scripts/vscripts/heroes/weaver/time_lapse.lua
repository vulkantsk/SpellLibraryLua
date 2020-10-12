LinkLuaModifier("modifier_time_lapse", "heroes/weaver/time_lapse", LUA_MODIFIER_MOTION_NONE)

ability_time_lapse = class({
    GetIntrinsicModifierName = function()
        return "modifier_time_lapse"
    end
})

function ability_time_lapse:OnUpgrade()
    if (not IsServer()) then
        return
    end
    if (not self.modifier) then
        self.modifier = self:GetCaster():FindModifierByName(self:GetIntrinsicModifierName())
    end
end

function ability_time_lapse:OnSpellStart()
    if (not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local pidx = ParticleManager:CreateParticle("particles/units/heroes/hero_weaver/weaver_timelapse.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(pidx, 2, self.modifier.position)
    ParticleManager:ReleaseParticleIndex(pidx)
    caster:EmitSound("Hero_Weaver.TimeLapse")
    ProjectileManager:ProjectileDodge(caster)
    caster:Purge(false, true, false, true, true)
    FindClearSpaceForUnit(caster, self.modifier.position, false)
    caster:SetHealth(self.modifier.health)
    caster:SetMana(self.modifier.mana)
    caster:Stop()
end

modifier_time_lapse = class({
    IsHidden = function()
        return true
    end,
    GetAttributes = function()
        return MODIFIER_ATTRIBUTE_PERMANENT
    end,
    DeclareFunctions = function()
        return {
            MODIFIER_EVENT_ON_RESPAWN
        }
    end
})

function modifier_time_lapse:OnCreated()
    if (not IsServer()) then
        return
    end
    self.ability = self:GetAbility()
    self.caster = self.ability:GetCaster()
    self:OnIntervalThink()
    self:StartIntervalThink(self.ability:GetSpecialValueFor("return_time"))
end

function modifier_time_lapse:OnRefresh()
    self:OnCreated()
end

function modifier_time_lapse:OnIntervalThink()
    if (self.caster:IsAlive()) then
        self.position = self.caster:GetAbsOrigin()
        self.health = self.caster:GetHealth()
        self.mana = self.caster:GetMana()
    end
end

function modifier_time_lapse:OnRespawn()
    if (not IsServer()) then
        return
    end
    self:StartIntervalThink(self.ability:GetSpecialValueFor("return_time"))
end