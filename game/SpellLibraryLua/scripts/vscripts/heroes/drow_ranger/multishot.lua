LinkLuaModifier( "modifier_ability_drow_ranger_multishot", "heroes/drow_ranger/multishot" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_drow_ranger_multishot_hidden", "heroes/drow_ranger/multishot" ,LUA_MODIFIER_MOTION_NONE )

if ability_drow_ranger_multishot == nil then
    ability_drow_ranger_multishot = class({})
end

--------------------------------------------------------------------------------

function ability_drow_ranger_multishot:OnSpellStart()
    local caster = self:GetCaster()
    self.dir = (self:GetCursorPosition() - caster:GetAbsOrigin()):Normalized()
    self.arrow_damage_pct = self:GetSpecialValueFor("arrow_damage_pct")
    self.arrow_slow_duration = self:GetSpecialValueFor("arrow_slow_duration")

    caster:AddNewModifier(caster, self, "modifier_ability_drow_ranger_multishot", {duration=self:GetChannelTime()})
end

function ability_drow_ranger_multishot:OnChannelFinish(bInterrupted)
    self:GetCaster():RemoveModifierByName("modifier_ability_drow_ranger_multishot")
    StopSoundOn("Hero_DrowRanger.Multishot.Channel", self:GetCaster())
end

function ability_drow_ranger_multishot:OnProjectileHit(Target, Location)
    if Target ~= nil and not Target:IsInvulnerable() then
        if not Target:HasModifier("modifier_ability_drow_ranger_multishot_hidden") then
            Target:AddNewModifier(self:GetCaster(), self, "modifier_ability_drow_ranger_multishot_hidden", {duration=0.1})

            local abil = self:GetCaster():FindAbilityByName("ability_drow_ranger_frost_arrows")
            if abil and abil:IsTrained() and not Target:IsMagicImmune() then
                Target:AddNewModifier(self:GetCaster(), abil, "modifier_ability_drow_ranger_frost_arrows_slow", {duration=self.arrow_slow_duration})
            end
            local damage = ((self:GetCaster():GetBaseDamageMax() + self:GetCaster():GetBaseDamageMin()) / 2) / 100 * self.arrow_damage_pct
            ApplyDamage({
                victim = Target,
                attacker = self:GetCaster(),
                damage = damage,
                damage_type = DAMAGE_TYPE_PHYSICAL,
                ability = self
            })

            EmitSoundOn("Hero_DrowRanger.ProjectileImpact", Target)

            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------


modifier_ability_drow_ranger_multishot = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
})


--------------------------------------------------------------------------------

if IsServer() then
function modifier_ability_drow_ranger_multishot:OnCreated(kv)
    self.arrow_width = self:GetAbility():GetSpecialValueFor("arrow_width")
    self.arrow_speed = self:GetAbility():GetSpecialValueFor("arrow_speed")
    self.arrow_range_multiplier = self:GetAbility():GetSpecialValueFor("arrow_range_multiplier")
    self.arrow_angle = self:GetAbility():GetSpecialValueFor("arrow_angle")
    self.direction = self:GetAbility().dir
    self.caster_origin = self:GetCaster():GetAbsOrigin()
    self.start_angle = -20

    self.count = 0
    EmitSoundOn("Hero_DrowRanger.Multishot.Channel", self:GetCaster())

    self:StartIntervalThink(0.1)
end

function modifier_ability_drow_ranger_multishot:OnIntervalThink()
    local caster = self:GetCaster()
    local abil = caster:FindAbilityByName("ability_drow_ranger_frost_arrows")
    local sound = abil:IsTrained() and "Hero_DrowRanger.Multishot.FrostArrows" or "Hero_DrowRanger.Multishot.Attack"
    EmitSoundOn(sound, caster)
    local distance = caster:Script_GetAttackRange() * self.arrow_range_multiplier
    local Qangle = QAngle(0,self.start_angle,0)
    local endpos = RotatePosition(Vector(0,0,0), Qangle, self.direction)
    local direction = endpos

    local proj = abil:IsTrained() and "particles/units/heroes/hero_drow/drow_multishot_proj_linear_proj.vpcf" or "particles/units/heroes/hero_drow/drow_base_attack_linear_proj.vpcf"
    local info = {
        Ability = self:GetAbility(),
        EffectName = proj,
        vSpawnOrigin = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1")),
        fDistance = distance,
        fStartRadius = self.arrow_width,
        fEndRadius = self.arrow_width,
        Source = caster,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        iUnitTargetType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
        fExpireTime = GameRules:GetGameTime() + 10.0,
        bDeleteOnHit = true,
        vVelocity = direction * self.arrow_speed,
        bProvidesVision = true,
        iVisionRadius = 100,
        iVisionTeamNumber = caster:GetTeamNumber()
    }

    ProjectileManager:CreateLinearProjectile( info )
    self.start_angle = self.start_angle + (self.arrow_angle / 5)

    self.count = self.count + 1
    if self.count >= 4 then
        self.start_angle = -20
        self.count = 0
        self:StartIntervalThink(0.50)
    else
        self:StartIntervalThink(0.033)
    end
end
end

--------------------------------------------------------------------------------


modifier_ability_drow_ranger_multishot_hidden = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
})


--------------------------------------------------------------------------------