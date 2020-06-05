ability_unstable_concoction_throw = class({})

function ability_unstable_concoction_throw:OnSpellStart() 
    local modifierCounter = self:GetCaster():FindModifierByName('modifier_unstable_concoction_lua_counter')
    if not modifierCounter then return end
    local abilityOwner = self:GetCaster():FindAbilityByName('ability_unstable_concoction')
    if not abilityOwner then return end 

    local maxDMG = abilityOwner:GetLevelSpecialValueFor('max_damage', self:GetLevel() - 1)
    local maxStun = abilityOwner:GetLevelSpecialValueFor('max_stun', self:GetLevel() - 1)
    local minDMG = abilityOwner:GetLevelSpecialValueFor('min_damage', self:GetLevel() - 1)
    local minStun = abilityOwner:GetLevelSpecialValueFor('min_stun', self:GetLevel() - 1)

    local durationFull = modifierCounter:GetDuration()
    local remaining = modifierCounter:GetRemainingTime()
    local procentageFull = (1 - remaining/durationFull)
    self.damage = minDMG + (maxDMG - minDMG) * procentageFull
    self.durStun = minStun + (maxStun - minStun) * procentageFull
    modifierCounter.bIsUse = true
    modifierCounter:Destroy()
    self:GetCaster():StartGesture(ACT_DOTA_ALCHEMIST_CONCOCTION_THROW)
    ProjectileManager:CreateTrackingProjectile({
        Target = self:GetCursorTarget(),
        Source = self:GetCaster(),
        Ability = self,	
        EffectName = "particles/units/heroes/hero_alchemist/alchemist_unstable_concoction_projectile.vpcf",
        iMoveSpeed = self:GetSpecialValueFor('movement_speed'),
        vSourceLoc= self:GetCaster():GetAbsOrigin(),
        bDrawsOnMinimap = false,                         
        bDodgeable = false,                                
        bIsAttack = false,                               
        bVisibleToEnemies = true,                         
        bReplaceExisting = false,                        
        bProvidesVision = true,
        iVisionRadius = self:GetSpecialValueFor('vision_range'),
        iVisionTeamNumber = self:GetCaster():GetTeamNumber()
    })
    self:GetCaster():EmitSound("Hero_Alchemist.UnstableConcoction.Throw")
end

function ability_unstable_concoction_throw:OnProjectileHit(hTarget, vLocation)
    if not hTarget then return end

    ApplyDamage({
        victim = hTarget,
        attacker = self:GetCaster(),
        ability = self,
        damage = self.damage,
        damage_type = DAMAGE_TYPE_PHYSICAL,
    })

    hTarget:AddNewModifier(self:GetCaster(), self, 'modifier_stunned', {duration = self.durStun})
    hTarget:EmitSound("Hero_Alchemist.UnstableConcoction.Stun")

    local nfx = ParticleManager:CreateParticle('particles/econ/items/alchemist/alchemist_smooth_criminal/alchemist_smooth_criminal_unstable_concoction_explosion.vpcf', PATTACH_ABSORIGIN, hTarget)
    ParticleManager:ReleaseParticleIndex(nfx)

end