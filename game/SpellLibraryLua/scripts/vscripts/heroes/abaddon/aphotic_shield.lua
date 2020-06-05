ability_aphotic_shield = class({})
LinkLuaModifier('modifier_abaddon_aphotic_shield_lua', 'heroes/abaddon/aphotic_shield', LUA_MODIFIER_MOTION_NONE)
function ability_aphotic_shield:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    target:Purge(false, true, false, true, false)
    target:RemoveModifierByName('modifier_abaddon_aphotic_shield_lua')
    target:AddNewModifier(caster, self, 'modifier_abaddon_aphotic_shield_lua', {
        duration = self:GetSpecialValueFor('duration'),
        absorb = self:GetSpecialValueFor('damage_absorb'),
    })

    target:EmitSound('Hero_Abaddon.AphoticShield.Cast')

end

modifier_abaddon_aphotic_shield_lua = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        }
    end,

    GetModifierIncomingDamage_Percentage = function(self,data) 
        self.absorbAmount = self.absorbAmount + data.damage
        if self.absorbAmount > self.absorb then 
            self:Destroy()
        end 
        print(self.absorbAmount)
        return -100 
    end,
})


function modifier_abaddon_aphotic_shield_lua:OnCreated(data)
    if IsClient() then return end
    self.absorb = data.absorb
    self.absorbAmount = 0
    self.parent = self:GetParent()
    local shield_size = 70
    self.nfx = ParticleManager:CreateParticle('particles/units/heroes/hero_abaddon/abaddon_aphotic_shield.vpcf', PATTACH_CUSTOMORIGIN_FOLLOW,self:GetParent())
    ParticleManager:SetParticleControl(self.nfx, 1, Vector(shield_size,0,shield_size))
    ParticleManager:SetParticleControl(self.nfx, 2, Vector(shield_size,0,shield_size))
    ParticleManager:SetParticleControl(self.nfx, 4, Vector(shield_size,0,shield_size))
    ParticleManager:SetParticleControl(self.nfx, 5, Vector(shield_size,0,0))
    ParticleManager:SetParticleControlEnt(self.nfx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
end

function modifier_abaddon_aphotic_shield_lua:OnDestroy()
    if IsClient() then return end

    local nfx = ParticleManager:CreateParticle('particles/units/heroes/hero_abaddon/abaddon_aphotic_shield_explosion.vpcf', PATTACH_CUSTOMORIGIN_FOLLOW,self:GetParent())
    ParticleManager:SetParticleControlEnt(nfx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(nfx)

    local units = FindUnitsInRadius(self:GetCaster():GetTeam(), 
    self:GetParent():GetOrigin(), 
    nil, 
    self:GetAbility():GetSpecialValueFor('radius'),
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    self:GetAbility():GetAbilityTargetType(), 
    self:GetAbility():GetAbilityTargetFlags(),
    FIND_ANY_ORDER, 
    false)

    local damage_type = self:GetAbility():GetAbilityDamageType()
    for __,v in pairs(units) do 

        ApplyDamage({
            victim = v,
            attacker = self:GetCaster(),
            damage = self.absorb,
            damage_type = damage_type,
            ability = self:GetAbility(),
        })

    end
    ParticleManager:DestroyParticle(self.nfx , true)
    ParticleManager:ReleaseParticleIndex(self.nfx)
    self:GetParent():EmitSound('Hero_Abaddon.AphoticShield.Destroy')
end