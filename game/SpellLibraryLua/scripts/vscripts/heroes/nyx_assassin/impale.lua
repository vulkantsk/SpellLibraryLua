if ability_nyx_assassin_impale == nil then
    ability_nyx_assassin_impale = class({})
end

--------------------------------------------------------------------------------

function ability_nyx_assassin_impale:OnSpellStart()
    local caster = self:GetCaster()
    local position = self:GetCursorPosition()

    local direction = (position - caster:GetAbsOrigin()):Normalized()

    local width = self:GetSpecialValueFor("width")
    local length = self:GetSpecialValueFor("length")
    local speed = self:GetSpecialValueFor("speed")

    local info = {
        Ability = self,
        EffectName = "particles/units/heroes/hero_nyx_assassin/nyx_assassin_impale.vpcf",
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = length,
        fStartRadius = width,
        fEndRadius = width,
        Source = caster,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        bDeleteOnHit = false,
        vVelocity = direction * speed,
        bProvidesVision = false,
        iVisionRadius = 0,
        iVisionTeamNumber = caster:GetTeamNumber(),
    }

    ProjectileManager:CreateLinearProjectile( info )

    EmitSoundOn("Hero_NyxAssassin.Impale", caster)
end

function ability_nyx_assassin_impale:OnProjectileHit(Target, Location)
    if Target ~= nil and not Target:IsInvulnerable() and not Target:IsMagicImmune() then

        if Target:TriggerSpellAbsorb(self) then return false end

        local duration = self:GetSpecialValueFor("duration")

        local knockbackProperties =
        {
            center_x = Target.x,
            center_y = Target.y,
            center_z = Target.z,
            duration = 0.5,
            knockback_duration = 0.5,
            knockback_distance = 0,
            knockback_height = 350
        }

        EmitSoundOn("Hero_NyxAssassin.Impale.Target", Target)

        local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_impale_hit.vpcf", PATTACH_ABSORIGIN, Target)
        ParticleManager:SetParticleControl(fx, 0, Target:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(fx)

        Target:AddNewModifier( self:GetCaster(), nil, "modifier_knockback", knockbackProperties )
        Timers:CreateTimer(0.5, function()
            if not Target:IsMagicImmune() then

                Target:AddNewModifier( self:GetCaster(), self, "modifier_stunned", {duration=duration} )

                local damageTable = {
                    victim = Target,
                    attacker = self:GetCaster(), 
                    damage = self:GetSpecialValueFor("impale_damage"),
                    damage_type = self:GetAbilityDamageType(),
                    ability = self
                }
            
                ApplyDamage(damageTable) 
            end   

            EmitSoundOn("Hero_NyxAssassin.Impale.TargetLand", Target)   
        end)
    end
    return false
end