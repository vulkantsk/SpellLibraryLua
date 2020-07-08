if ability_lion_impale == nil then
    ability_lion_impale = class({})
end

--------------------------------------------------------------------------------

function ability_lion_impale:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local position = self:GetCursorPosition()
    local pos = target and target:GetAbsOrigin() or position

    local direction = (pos - caster:GetAbsOrigin()):Normalized()

    local width = self:GetSpecialValueFor("width")
    local length_buffer = self:GetSpecialValueFor("length_buffer")
    local speed = self:GetSpecialValueFor("speed")

    local distance = self:GetCastRange(caster:GetAbsOrigin(), caster) + length_buffer

    local info = {
        Ability = self,
        EffectName = "particles/units/heroes/hero_lion/lion_spell_impale.vpcf",
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = distance,
        fStartRadius = width,
        fEndRadius = width,
        Source = caster,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        bDeleteOnHit = false,
        vVelocity = direction * speed,
        bProvidesVision = false,
        iVisionRadius = 0,
        iVisionTeamNumber = caster:GetTeamNumber(),
    }

    ProjectileManager:CreateLinearProjectile( info )

    EmitSoundOn("Hero_Lion.Impale", caster)
end

function ability_lion_impale:OnProjectileHit(Target, Location)
    if Target ~= nil and not Target:IsInvulnerable() then

        if Target:TriggerSpellAbsorb(self) then return false end

        local duration = self:GetSpecialValueFor("duration")
        Target:AddNewModifier( self:GetCaster(), self, "modifier_stunned", {duration=duration} )

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

        EmitSoundOn("Hero_Lion.ImpaleHitTarget", Target)

        local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_lion/lion_spell_impale_hit_spikes.vpcf", PATTACH_ABSORIGIN, Target)
        ParticleManager:SetParticleControl(fx, 0, Target:GetAbsOrigin())
        ParticleManager:SetParticleControl(fx, 2, Target:GetAttachmentOrigin(Target:ScriptLookupAttachment("attach_hitloc")))
        ParticleManager:ReleaseParticleIndex(fx)

        Target:AddNewModifier( self:GetCaster(), nil, "modifier_knockback", knockbackProperties )
        Timers:CreateTimer(0.5, function()

            local damageTable = {
                victim = Target,
                attacker = self:GetCaster(), 
                damage = self:GetAbilityDamage(),
                damage_type = self:GetAbilityDamageType(),
                ability = self
            }
        
            ApplyDamage(damageTable)        
        end)
    end
    return false
end