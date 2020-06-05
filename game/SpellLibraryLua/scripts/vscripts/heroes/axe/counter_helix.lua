ability_counter_helix = class({})

function ability_counter_helix:GetIntrinsicModifierName()
    return 'modifier_ability_counter_helix'
end 
LinkLuaModifier('modifier_ability_counter_helix', 'heroes/axe/counter_helix', LUA_MODIFIER_MOTION_NONE)

modifier_ability_counter_helix = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
    AllowIllusionDuplicate  = function(self) return true end,
    IsPermanent             = function(self) return true end,
    DeclareFunctions        = function(self) return {MODIFIER_EVENT_ON_ATTACK_LANDED} end,
})

function modifier_ability_counter_helix:OnCreated()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self.chance = self.ability:GetSpecialValueFor('trigger_chance')
    self.damage = self.ability:GetSpecialValueFor('damage')
    self.radius = self.ability:GetSpecialValueFor('radius')
    self.cooldown = self.ability:GetSpecialValueFor('cooldown')
end     

function modifier_ability_counter_helix:OnRefresh()
    self:OnCreated()
end 

function modifier_ability_counter_helix:OnAttackLanded(data)
    if IsClient() then return end
    if data.target ~= self.parent  then return end
    if not self.ability:IsCooldownReady() then return end
    if data.attacker == self.parent or self.parent:PassivesDisabled() or data.attacker:IsBuilding() or data.attacker:GetTeam() == self.parent:GetTeam() then return end
    
    if RollPercentage(self.chance) then 
        local helix_pfx_1 = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_attack_blur_counterhelix.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControl(helix_pfx_1, 0, self:GetParent():GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(helix_pfx_1)

        self:GetParent():StartGesture(ACT_DOTA_CAST_ABILITY_3)
        self:GetParent():EmitSound("Hero_Axe.CounterHelix")

        local enemies = FindUnitsInRadius(self.parent:GetTeamNumber(), 
        self.parent:GetAbsOrigin(),
        nil, 
        self.radius, 
        DOTA_UNIT_TARGET_TEAM_ENEMY, 
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 
        FIND_ANY_ORDER, 
        false)

        for _,enemy in pairs(enemies) do
    
            ApplyDamage({
                attacker = self.parent, 
                victim = enemy, 
                ability = self.ability, 
                damage = self.damage,
                damage_type = DAMAGE_TYPE_PURE
            })

        end

        self.ability:StartCooldown(self.cooldown)
    end 
end 



