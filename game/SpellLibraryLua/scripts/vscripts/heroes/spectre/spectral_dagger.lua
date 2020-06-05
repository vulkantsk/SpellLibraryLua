LinkLuaModifier( "modifier_ability_spectral_dagger_dummy_proj", "heroes/spectre/spectral_dagger" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_spectral_path", "heroes/spectre/spectral_dagger" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_spectral_in_path", "heroes/spectre/spectral_dagger" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_spectral_grace", "heroes/spectre/spectral_dagger" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_spectral_path_by_heroes", "heroes/spectre/spectral_dagger" ,LUA_MODIFIER_MOTION_NONE )

if ability_spectral_dagger == nil then
    ability_spectral_dagger = class({})
end

--------------------------------------------------------------------------------

function ability_spectral_dagger:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local position = self:GetCursorPosition()

    self.dagger_radius = self:GetSpecialValueFor("dagger_radius")
    local speed = self:GetSpecialValueFor("speed")
    local vision_radius = self:GetSpecialValueFor("vision_radius")
    local direction = nil

    caster:EmitSound("Hero_Spectre.DaggerCast")

    local proj = "particles/units/heroes/hero_spectre/spectre_spectral_dagger.vpcf"
    local proj_tracking = "particles/units/heroes/hero_spectre/spectre_spectral_dagger_tracking.vpcf"

    if target and target:IsHero() then
        local info = {
            Target = target,
            Source = caster,
            Ability = self,
            EffectName = proj_tracking,
            bDodgeable = false,
            bIsAttack = false,
            bProvidesVision = true,
            iMoveSpeed = speed,
            vSpawnOrigin = caster:GetAbsOrigin(),
            iVisionRadius = vision_radius,
            iVisionTeamNumber = caster:GetTeamNumber(),
        }
        ProjectileManager:CreateTrackingProjectile( info )
        local dummy = CreateUnitByName("npc_dummy_unit_spectre", caster:GetAbsOrigin(), true, nil, nil, caster:GetTeam())
        dummy.TargetingHero = target
        dummy:AddNewModifier(caster, self, "modifier_ability_spectral_dagger_dummy_proj", {})
    else
        direction = (position - caster:GetAbsOrigin()):Normalized()

        local info = {
            Ability = self,
            EffectName = proj,
            vSpawnOrigin = caster:GetAbsOrigin(),
            fDistance = 2000,
            fStartRadius = self.dagger_radius,
            fEndRadius = self.dagger_radius,
            Source = caster,
            bHasFrontalCone = false,
            bReplaceExisting = false,
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
            iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            bDeleteOnHit = false,
            vVelocity = direction * speed,
            bProvidesVision = true,
            iVisionRadius = vision_radius,
            iVisionTeamNumber = caster:GetTeamNumber(),
        }

        ProjectileManager:CreateLinearProjectile( info )
    end
end

function ability_spectral_dagger:OnProjectileHit(Target, Location)
    if Target ~= nil and not Target:IsInvulnerable() then
        local damage = self:GetSpecialValueFor("damage")
        local hero_path_duration = self:GetSpecialValueFor("hero_path_duration")

        ApplyDamage({
            victim = Target,
            attacker = self:GetCaster(),
            damage = damage,
            damage_type = self:GetAbilityDamageType(),
            ability = self
        })

        EmitSoundOn("Hero_Spectre.DaggerImpact", Target)

        if Target:IsHero() then
            Target:AddNewModifier(self:GetCaster(), self, "modifier_ability_spectral_path_by_heroes", {duration=hero_path_duration})
        end
    end
    return false
end

function ability_spectral_dagger:OnProjectileThink(vLocation)
    local caster = self:GetCaster()

    CreateModifierThinker(caster, self, "modifier_ability_spectral_path", {duration = self:GetSpecialValueFor('dagger_path_duration')}, vLocation, caster:GetTeam(), false)
end

--------------------------------------------------------------------------------


modifier_ability_spectral_dagger_dummy_proj = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
            MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
            MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL
        }
    end,
    CheckState              = function(self)
        return {
            [MODIFIER_STATE_LOW_ATTACK_PRIORITY] = true,
            [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
            [MODIFIER_STATE_UNSELECTABLE] = true,
            [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
            [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
            [MODIFIER_STATE_NO_HEALTH_BAR] = true,
            [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
            [MODIFIER_STATE_STUNNED ] = true,
            [MODIFIER_STATE_ATTACK_IMMUNE] = true,
            [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        }
    end,
})


--------------------------------------------------------------------------------

if IsServer() then
function modifier_ability_spectral_dagger_dummy_proj:OnCreated()
    self.target = self:GetParent().TargetingHero
    self.targets = {}
    self.speed = self:GetAbility():GetSpecialValueFor("speed") * 1/30
    self:StartIntervalThink(0.03)
end

function modifier_ability_spectral_dagger_dummy_proj:OnIntervalThink()
    local parent = self:GetParent()

    local damage = self:GetAbility():GetSpecialValueFor("damage")

    local all = FindUnitsInRadius(self:GetCaster():GetTeam(), 
    parent:GetAbsOrigin(), 
    nil, 
    self:GetAbility().dagger_radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_ANY_ORDER, 
    false)

    local hero_path_duration = self:GetAbility():GetSpecialValueFor("hero_path_duration")

    for _, unit in ipairs(all) do
        if not HasDamaged(self.targets, unit) and unit ~= self.target then
            table.insert(self.targets, unit)
            ApplyDamage({
                victim = unit,
                attacker = self:GetCaster(),
                damage = damage,
                damage_type = self:GetAbility():GetAbilityDamageType(),
                ability = self:GetAbility()
            })

            EmitSoundOn("Hero_Spectre.DaggerImpact", unit)

            if unit:IsHero() then
                unit:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_ability_spectral_path_by_heroes", {duration=hero_path_duration})
            end
        end
    end

    if not parent:IsPositionInRange(self.target:GetAbsOrigin(), self:GetAbility().dagger_radius) then
        local direction = (self.target:GetAbsOrigin() - parent:GetAbsOrigin()):Normalized()
        parent:SetAbsOrigin(GetGroundPosition(parent:GetAbsOrigin(), parent) + direction * self.speed)
    else
        parent:Kill(nil, parent)
    end
end
end

function modifier_ability_spectral_dagger_dummy_proj:GetAbsoluteNoDamageMagical() return 1 end
function modifier_ability_spectral_dagger_dummy_proj:GetAbsoluteNoDamagePure() return 1 end
function modifier_ability_spectral_dagger_dummy_proj:GetAbsoluteNoDamagePhysical() return 1 end

function HasDamaged(table, target)
    for k,v in pairs(table) do
        if v == target then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------


modifier_ability_spectral_path = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
})


--------------------------------------------------------------------------------

function modifier_ability_spectral_path:IsAura()
    return true
end

function modifier_ability_spectral_path:GetModifierAura()
    return "modifier_ability_spectral_in_path"
end

function modifier_ability_spectral_path:GetAuraRadius()
    return self.path_radius
end

function modifier_ability_spectral_path:GetAuraDuration()
    return self.buff_persistence
end

function modifier_ability_spectral_path:GetAuraSearchTeam()    
    return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_ability_spectral_path:GetAuraSearchType()    
    return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_ability_spectral_path:OnCreated()
    self.path_radius = self:GetAbility():GetSpecialValueFor("path_radius")
    self.buff_persistence = self:GetAbility():GetSpecialValueFor("buff_persistence")
    self.dagger_grace_period = self:GetAbility():GetSpecialValueFor("dagger_grace_period")
    self:StartIntervalThink(0.03)
end

function modifier_ability_spectral_path:OnIntervalThink()
    local all = FindUnitsInRadius(self:GetParent():GetTeam(), 
    self:GetParent():GetAbsOrigin(), 
    nil, 
    self.path_radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
    DOTA_UNIT_TARGET_HERO, 
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER, 
    false)

    for _, hero in ipairs(all) do
        if hero == self:GetCaster() then
            self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_ability_spectral_grace", {duration=self.dagger_grace_period})
        end
    end
end

--------------------------------------------------------------------------------


modifier_ability_spectral_in_path = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_spectral_in_path:OnCreated()
    self.bonus_movespeed = self:GetAbility():GetSpecialValueFor("bonus_movespeed")
end

function modifier_ability_spectral_in_path:IsDebuff()
    if self:GetParent():GetTeamNumber() == self:GetCaster():GetTeamNumber() then
        return false
    end
    return true
end

function modifier_ability_spectral_in_path:GetModifierMoveSpeedBonus_Percentage()
    if self:GetParent():GetTeamNumber() == self:GetCaster():GetTeamNumber() then
        return self.bonus_movespeed
    end
    return self.bonus_movespeed * -1
end

--------------------------------------------------------------------------------


modifier_ability_spectral_grace = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    CheckState              = function(self)
        return {
            [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        }
    end,
})


--------------------------------------------------------------------------------

--------------------------------------------------------------------------------


modifier_ability_spectral_path_by_heroes = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
})


--------------------------------------------------------------------------------

if IsServer() then
function modifier_ability_spectral_path_by_heroes:OnCreated()
    self.dagger_path_duration = self:GetAbility():GetSpecialValueFor("dagger_path_duration")
    self:StartIntervalThink(0.15)
    self.pathFX = ParticleManager:CreateParticle("particles/units/heroes/hero_spectre/spectre_shadow_path.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControlEnt(self.pathFX, 3, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(self.pathFX, 5, Vector(self.dagger_path_duration, 0, 0) )
end

function modifier_ability_spectral_path_by_heroes:OnDestroy()
    ParticleManager:DestroyParticle(self.pathFX, false)
end

function modifier_ability_spectral_path_by_heroes:OnIntervalThink()
    local caster = self:GetCaster()

    CreateModifierThinker(caster, self:GetAbility(), "modifier_ability_spectral_path", {duration = self.dagger_path_duration}, self:GetParent():GetAbsOrigin(), caster:GetTeam(), false)
end
end





--[[
function ability_spectral_dagger:OnProjectileThink_ExtraData(vLocation, ExtraData)
    if ExtraData.IsTracking == true then
        local caster = self:GetCaster()

        local damage = self:GetSpecialValueFor("damage")

        local all = FindUnitsInRadius(caster:GetTeam(), 
        vLocation, 
        nil, 
        self.dagger_radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY, 
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        FIND_ANY_ORDER, 
        false)

        for _, unit in ipairs(all) do
            ApplyDamage({
                victim = unit,
                attacker = caster,
                damage = damage,
                damage_type = self:GetAbilityDamageType(),
                ability = self
            })
        end
    end
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end]]