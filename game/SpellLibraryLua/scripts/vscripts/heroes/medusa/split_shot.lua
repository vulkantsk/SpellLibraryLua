ability_split_shot = {}

LinkLuaModifier( "modifier_ability_split_shot", "heroes/medusa/split_shot", LUA_MODIFIER_MOTION_NONE )

function ability_split_shot:OnToggle()
    local caster = self:GetCaster()
    local modifier = caster:FindModifierByName( "modifier_ability_split_shot" )

    if self:GetToggleState() then
        if not modifier then
            caster:AddNewModifier(
                caster,
                self,
                "modifier_ability_split_shot",
                {}
            )
        end
    else
        if modifier then
            modifier:Destroy()
        end
    end
end

function ability_split_shot:ProcsMagicStick()
    return false
end

function ability_split_shot:OnUpgrade()
    local modifier = self:GetCaster():FindModifierByName( "modifier_ability_split_shot" )

    if modifier then
        modifier:ForceRefresh()
    end
end

function ability_split_shot:OnProjectileHit( target, location )
    if not target then return end

    self.split_shot_attack = true
    self:GetCaster():PerformAttack(
        target,
        false,
        false,
        true,
        false,
        false,
        false,
        false
    )
    self.split_shot_attack = false
end

modifier_ability_split_shot = {}

function modifier_ability_split_shot:IsHidden()
    return true
end

function modifier_ability_split_shot:IsPurgable()
    return false
end

function modifier_ability_split_shot:GetPriority()
    return MODIFIER_PRIORITY_HIGH
end

function modifier_ability_split_shot:OnCreated( kv )
    self.reduction = self:GetAbility():GetSpecialValueFor( "damage_modifier" )
    self.count = self:GetAbility():GetSpecialValueFor( "arrow_count" )
    self.bonus_range = self:GetAbility():GetSpecialValueFor( "split_shot_bonus_range" )

    self.parent = self:GetParent()

    if not IsServer() then return end

    local talent = self:GetParent():FindAbilityByName( "special_bonus_unique_medusa_4" )

    self.use_modifier = talent and talent:GetLevel() > 0 or false
    self.projectile_name = self.parent:GetRangedProjectileName()
    self.projectile_speed = self.parent:GetProjectileSpeed()
end

function modifier_ability_split_shot:OnRefresh( kv )
    self.reduction = self:GetAbility():GetSpecialValueFor( "damage_modifier" )
    self.count = self:GetAbility():GetSpecialValueFor( "arrow_count" )
    self.bonus_range = self:GetAbility():GetSpecialValueFor( "split_shot_bonus_range" )
end

function modifier_ability_split_shot:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
    }
end

function modifier_ability_split_shot:OnAttack( params )
    if not IsServer() then return end

    if params.attacker~=self.parent then return end

    if params.no_attack_cooldown then return end

    if params.target:GetTeamNumber()==params.attacker:GetTeamNumber() then return end

    if self.parent:PassivesDisabled() then return end

    if params.process_procs then return end

    if self.split_shot then return end

    if self.use_modifier then
        self:SplitShotModifier( params.target )
    else
        self:SplitShotNoModifier( params.target )
    end
end

function modifier_ability_split_shot:GetModifierDamageOutgoing_Percentage()
    if not IsServer() then return end

    if self.split_shot then
        return self.reduction
    end

    if self:GetAbility().split_shot_attack then
        return self.reduction
    end
end

function modifier_ability_split_shot:SplitShotModifier( target )
    local radius = self.parent:Script_GetAttackRange() + self.bonus_range

    local enemies = FindUnitsInRadius(
        self.parent:GetTeamNumber(),
        self.parent:GetOrigin(),
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_COURIER,
        DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        0,
        false
    )

    local count = 0
    for _,enemy in pairs(enemies) do
        if enemy~=target then
            self.split_shot = true
            self.parent:PerformAttack(
                enemy,
                false,
                self.use_modifier,
                true,
                false,
                true,
                false,
                false
            )
            self.split_shot = false

            count = count + 1
            if count >= self.count then break end
        end
    end

    if count > 0 then
        EmitSoundOn( "Hero_Medusa.AttackSplit", self.parent )
    end
end

function modifier_ability_split_shot:SplitShotNoModifier( target )
    local radius = self.parent:Script_GetAttackRange() + self.bonus_range

    local enemies = FindUnitsInRadius(
        self.parent:GetTeamNumber(),
        self.parent:GetOrigin(),
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_COURIER,
        DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        0,
        false
    )

    local count = 0
    for _,enemy in pairs(enemies) do
        if enemy~=target then
            local info = {
                Target = enemy,
                Source = self.parent,
                Ability = self:GetAbility(),
                EffectName = self.projectile_name,
                iMoveSpeed = self.projectile_speed,
                bDodgeable = true,
            }
            ProjectileManager:CreateTrackingProjectile(info)

            count = count + 1
            if count >= self.count then break end
        end
    end

    if count>0 then
        EmitSoundOn( "Hero_Medusa.AttackSplit", self.parent )
    end
end