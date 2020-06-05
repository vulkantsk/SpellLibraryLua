ability_unstable_concoction = class({})
LinkLuaModifier('modifier_unstable_concoction_lua_counter', 'heroes/alchemist/unstable_concoction', LUA_MODIFIER_MOTION_NONE)

function ability_unstable_concoction:OnSpellStart()
    self:GetCaster():AddNewModifier(self:GetCaster(), self, 'modifier_unstable_concoction_lua_counter', {duration = self:GetSpecialValueFor('brew_explosion')})
    self:GetCaster():EmitSound("Hero_Alchemist.UnstableConcoction.Fuse")
    
    self:GetCaster():StartGesture(ACT_DOTA_ALCHEMIST_CONCOCTION)
    
    local abilityThrow = self:GetCaster():FindAbilityByName('ability_unstable_concoction_throw')
    if not abilityThrow then return end
    self:GetCaster():SwapAbilities('ability_unstable_concoction', 'ability_unstable_concoction_throw', true, true)
    self:SetHidden(true)
    abilityThrow:SetHidden(false)
    abilityThrow:SetLevel(self:GetLevel())

end

modifier_unstable_concoction_lua_counter = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return false end,
    IsPermanent             = function(self) return false end,
    
})


function modifier_unstable_concoction_lua_counter:OnCreated(table)
    if IsClient() then return end
    self:StartIntervalThink(0.5)
end

function modifier_unstable_concoction_lua_counter:OnDestroy()
    if IsClient() then return end
    self:GetParent():RemoveGesture(ACT_DOTA_ALCHEMIST_CONCOCTION)
    self:GetParent():StopSound("Hero_Alchemist.UnstableConcoction.Fuse")
    if not self.bIsUse and self:GetParent():IsAlive() then 
        self:GetParent():EmitSound("Hero_Alchemist.UnstableConcoction.Throw")
        self:GetParent():EmitSound("Hero_Alchemist.UnstableConcoction.Stun")
        ApplyDamage({
            victim = self:GetParent(),
            attacker = self:GetParent(),
            ability = self:GetAbility(),
            damage = self:GetAbility():GetSpecialValueFor('max_damage'),
            damage_type = self:GetAbility():GetAbilityDamageType(),
        })
    
        self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), 'modifier_stunned', {duration = self:GetAbility():GetSpecialValueFor('max_stun')})

    end

    local abilityThrow = self:GetCaster():FindAbilityByName('ability_unstable_concoction_throw')
    if not abilityThrow then return end

    self:GetCaster():SwapAbilities('ability_unstable_concoction_throw', 'ability_unstable_concoction', true, true)
    self:GetAbility():SetHidden(false)
    abilityThrow:SetHidden(true)


end

function modifier_unstable_concoction_lua_counter:OnIntervalThink()
    if IsClient() then return end

    local timer = math.round(self:GetRemainingTime(), 1)
    local length = math.symbolsCount(timer)
    local decimal = timer - math.floor(timer)
    self.nfx = ParticleManager:CreateParticle('particles/units/heroes/hero_alchemist/alchemist_unstable_concoction_timer.vpcf', PATTACH_OVERHEAD_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(self.nfx, 1, Vector(0,math.floor(timer),decimal + 1 > 1 and 8 or 1))
    ParticleManager:SetParticleControl(self.nfx, 2, Vector(length + (decimal > 0 and 0 or 1),0,0))
    ParticleManager:ReleaseParticleIndex(self.nfx)
end
