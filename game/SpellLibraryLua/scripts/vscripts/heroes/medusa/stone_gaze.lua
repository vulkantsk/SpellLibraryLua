ability_stone_gaze = {}

LinkLuaModifier( "modifier_ability_stone_gaze", "heroes/medusa/stone_gaze", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_stone_gaze_debuff", "heroes/medusa/stone_gaze", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_stone_gaze_petrified", "heroes/medusa/stone_gaze", LUA_MODIFIER_MOTION_NONE )

function ability_stone_gaze:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor( "duration" )

    caster:AddNewModifier(
        caster,
        self,
        "modifier_ability_stone_gaze",
        { duration = duration }
    )
end

modifier_ability_stone_gaze = {}

function modifier_ability_stone_gaze:IsHidden()
    return false
end

function modifier_ability_stone_gaze:IsDebuff()
    return false
end

function modifier_ability_stone_gaze:IsPurgable()
    return false
end

function modifier_ability_stone_gaze:OnCreated( kv )
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )

    self.parent = self:GetParent()
    self.modifiers = {}

    if not IsServer() then return end

    self:StartIntervalThink( 0.1 )
    self:OnIntervalThink()

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_medusa/medusa_stone_gaze_active.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        self:GetParent(),
        PATTACH_POINT_FOLLOW,
        "attach_head",
        Vector( 0, 0, 0 ),
        true
    )

    self:AddParticle(
        effect_cast,
        false,
        false,
        -1,
        false,
        false 
    )

    EmitSoundOn( "Hero_Medusa.StoneGaze.Cast", self:GetParent() )
end

function modifier_ability_stone_gaze:OnDestroy()
    if not IsServer() then return end

    for modifier,_ in pairs(self.modifiers) do
        if not modifier:IsNull() then
            modifier:Destroy()
        end
    end

    StopSoundOn( "Hero_Medusa.StoneGaze.Cast", self:GetParent() )
end

function modifier_ability_stone_gaze:OnIntervalThink()
    local enemies = FindUnitsInRadius(
        self.parent:GetTeamNumber(),
        self.parent:GetOrigin(),
        nil,
        self.radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        0,
        false 
    )

    for _,enemy in pairs(enemies) do
        local modifier1 = enemy:FindModifierByNameAndCaster( "modifier_ability_stone_gaze_debuff", self.parent )
        local modifier2 = enemy:FindModifierByNameAndCaster( "modifier_ability_stone_gaze_petrified", self.parent )

        if (not modifier1) and (not modifier2) then
            local modifier = enemy:AddNewModifier(
                self.parent,
                self:GetAbility(),
                "modifier_ability_stone_gaze_debuff",
                {
                    center_unit = self.parent:entindex(),
                }
            )

            self.modifiers[modifier] = true
        end
    end
end

modifier_ability_stone_gaze_debuff = {}

function modifier_ability_stone_gaze_debuff:IsHidden()
    return false
end

function modifier_ability_stone_gaze_debuff:IsDebuff()
    return true
end

function modifier_ability_stone_gaze_debuff:IsStunDebuff()
    return false
end

function modifier_ability_stone_gaze_debuff:IsPurgable()
    return false
end

function modifier_ability_stone_gaze_debuff:OnCreated( kv )
    self.slow = -self:GetAbility():GetSpecialValueFor( "slow" )
    self.stun_duration = self:GetAbility():GetSpecialValueFor( "stone_duration" )
    self.face_duration = self:GetAbility():GetSpecialValueFor( "face_duration" )
    self.physical_bonus = self:GetAbility():GetSpecialValueFor( "bonus_physical_damage" )
    self.radius = self:GetAbility():GetSpecialValueFor( "radius" )

    self.stone_angle = self:GetAbility():GetSpecialValueFor( "vision_cone" )
    self.stone_angle = 85

    self.parent = self:GetParent()
    self.facing = false
    self.counter = 0
    self.interval = 0.03

    if not IsServer() then return end
    self.center_unit = EntIndexToHScript( kv.center_unit )

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_medusa/medusa_stone_gaze_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        self.center_unit,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector( 0, 0, 0 ),
        true
    )

    self:AddParticle(
        effect_cast,
        false,
        false,
        -1,
        false,
        false 
    )
    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_medusa/medusa_stone_gaze_facing.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        1,
        self:GetParent(),
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector( 0, 0, 0 ),
        true
    )

    self:AddParticle(
        self.effect_cast,
        false,
        false,
        -1,
        false,
        false
    )

    self:StartIntervalThink( self.interval )
    self:OnIntervalThink()
end

function modifier_ability_stone_gaze_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }

    return funcs
end

function modifier_ability_stone_gaze_debuff:GetModifierMoveSpeedBonus_Percentage()
    if self.facing then
        return self.slow
    end
end
function modifier_ability_stone_gaze_debuff:GetModifierAttackSpeedBonus_Constant()
    if self.facing then
        return self.slow
    end
end

function modifier_ability_stone_gaze_debuff:OnIntervalThink()
    local vector = self.center_unit:GetOrigin()-self.parent:GetOrigin()

    local center_angle = VectorToAngles( vector ).y
    local facing_angle = VectorToAngles( self.parent:GetForwardVector() ).y
    local distance = vector:Length2D()

    local prev_facing = self.facing

    self.facing = ( math.abs( AngleDiff(center_angle,facing_angle) ) < self.stone_angle ) and (distance < self.radius )

    if self.facing~=prev_facing then
        self:ChangeEffects( self.facing )
    end

    if self.facing then
        self.counter = self.counter + self.interval
    end

    if self.counter>=self.face_duration then
        self.parent:AddNewModifier(
            self:GetCaster(),
            self:GetAbility(),
            "modifier_ability_stone_gaze_petrified",
            {
                duration = self.stun_duration,
                physical_bonus = self.physical_bonus,
                center_unit = self.center_unit:entindex(),
            }
        )

        self:Destroy()
    end
end

function modifier_ability_stone_gaze_debuff:ChangeEffects( IsNowFacing )
    local target = self.parent

    if IsNowFacing then
        target = self.center_unit

        EmitSoundOnClient( "Hero_Medusa.StoneGaze.Target", self:GetParent():GetPlayerOwner() )
    end

    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        1,
        target,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector( 0, 0,0 ),
        true
    )
end

modifier_ability_stone_gaze_petrified = {}

function modifier_ability_stone_gaze_petrified:IsHidden()
    return false
end

function modifier_ability_stone_gaze_petrified:IsDebuff()
    return true
end

function modifier_ability_stone_gaze_petrified:IsStunDebuff()
    return true
end

function modifier_ability_stone_gaze_petrified:IsPurgable()
    return true
end

function modifier_ability_stone_gaze_petrified:OnCreated( kv )
    if not IsServer() then return end

    self.physical_bonus = kv.physical_bonus
    self.center_unit = EntIndexToHScript( kv.center_unit )

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_medusa/medusa_stone_gaze_debuff_stoned.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        self.center_unit,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector( 0,0,0 ),
        true
    )

    self:AddParticle(
        effect_cast,
        false,
        false,
        -1,
        false,
        false
    )

    EmitSoundOnClient( "Hero_Medusa.StoneGaze.Stun", self:GetParent():GetPlayerOwner() )
end

modifier_ability_stone_gaze_petrified.OnRefresh = modifier_ability_stone_gaze_petrified.OnCreated

function modifier_ability_stone_gaze_petrified:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }
end

function modifier_ability_stone_gaze_petrified:GetModifierIncomingDamage_Percentage( params )
    if params.damage_type==DAMAGE_TYPE_PHYSICAL then
        return self.physical_bonus
    end
end

function modifier_ability_stone_gaze_petrified:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_FROZEN] = true,
    }
end

function modifier_ability_stone_gaze_petrified:GetStatusEffectName()
    return "particles/status_fx/status_effect_medusa_stone_gaze.vpcf"
end
function modifier_ability_stone_gaze_petrified:StatusEffectPriority()
    return MODIFIER_PRIORITY_ULTRA
end