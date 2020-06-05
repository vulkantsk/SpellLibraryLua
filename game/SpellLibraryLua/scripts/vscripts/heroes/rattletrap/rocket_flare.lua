ability_rocket_flare = class({})
LinkLuaModifier('modifier_ability_rocket_flare_dummy', 'heroes/rattletrap/rocket_flare', LUA_MODIFIER_MOTION_NONE)

function ability_rocket_flare:OnSpellStart()
    local caster = self:GetCaster()
    local targetPos = self:GetCursorPosition()

    local dummy = CreateUnitByName('npc_dummy_unit', targetPos, false, nil, nil, caster:GetTeam())
    dummy:AddNewModifier(caster, self, 'modifier_ability_rocket_flare_dummy', {})
    local projectile = {
        Target = dummy,
        Source = self:GetCaster(),
        Ability = self,
        EffectName = "particles/units/heroes/hero_rattletrap/rattletrap_rocket_flare.vpcf",
        bDodgable = false,
        bProvidesVision = true,
		iVisionRadius = self:GetSpecialValueFor("vision_radius"),
		iVisionTeamNumber = caster:GetTeamNumber(),
        iMoveSpeed = self:GetSpecialValueFor("speed"),
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
    }
    ProjectileManager:CreateTrackingProjectile(projectile)
    EmitSoundOn("Hero_Rattletrap.Rocket_Flare.Fire", self:GetCaster())
end

function ability_rocket_flare:OnProjectileHit(target, position)
    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("radius")
    local duration = self:GetSpecialValueFor("duration")
    local enemies = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
    EmitSoundOn("Hero_Rattletrap.Rocket_Flare.Explode", self:GetCaster())
    UTIL_Remove(target)
    for _, enemy in pairs(enemies) do
        ApplyDamage({victim = enemy, attacker = caster, damage = self:GetSpecialValueFor("damage"), damage_type = self:GetAbilityDamageType(), ability = self})
    end
    AddFOWViewer( caster:GetTeamNumber(), position, self:GetSpecialValueFor("vision_radius"), self:GetSpecialValueFor("duration"), false ) 
end

modifier_ability_rocket_flare_dummy = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return false end,
    CheckState  = function(self)
        return {
            [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
            [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
            [MODIFIER_STATE_INVULNERABLE] = true,
            [MODIFIER_STATE_UNSELECTABLE] = true,
            [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        }
    end,  
})