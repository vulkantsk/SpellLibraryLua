LinkLuaModifier( "modifier_ability_viper_poison_attack", "heroes/viper/poison_attack" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_viper_poison_attack_slow", "heroes/viper/poison_attack" ,LUA_MODIFIER_MOTION_NONE )

if ability_viper_poison_attack == nil then
    ability_viper_poison_attack = class({})
end

function ability_viper_poison_attack:GetIntrinsicModifierName()
    return "modifier_ability_viper_poison_attack"
end

function ability_viper_poison_attack:GetProjectileName()
    return "particles/units/heroes/hero_viper/viper_poison_attack.vpcf"
end

function ability_viper_poison_attack:OnOrbFire( params )
    local sound_cast = "hero_viper.poisonAttack.Cast"
    EmitSoundOn( sound_cast, self:GetCaster() )
end

function ability_viper_poison_attack:OnOrbImpact( params )
    local duration = self:GetSpecialValueFor( "duration" )

    local modif = params.target:AddNewModifier(self:GetCaster(), self, "modifier_ability_viper_poison_attack_slow", {duration=duration})
    modif:SetStackCount(modif:GetStackCount() + 1)

    local sound_cast = "hero_viper.poisonAttack.Target"
    EmitSoundOn( sound_cast, params.target )
end

--------------------------------------------------------------------------------


modifier_ability_viper_poison_attack = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_EVENT_ON_ATTACK,
            MODIFIER_EVENT_ON_ATTACK_FAIL,
            MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
            MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,

            MODIFIER_EVENT_ON_ORDER,

            MODIFIER_PROPERTY_PROJECTILE_NAME,
        }
    end,
    GetAttributes           = function(self) return MODIFIER_ATTRIBUTE_PERMANENT end,
})


--------------------------------------------------------------------------------

function modifier_ability_viper_poison_attack:OnCreated()
    self.ability = self:GetAbility()
    self.cast = false
    self.records = {}
end

function modifier_ability_viper_poison_attack:OnAttack( params )
    -- if not IsServer() then return end
    if params.attacker~=self:GetParent() then return end

    -- register attack if being cast and fully castable
    if self:ShouldLaunch( params.target ) then
        -- use mana and cd
        self.ability:UseResources( true, false, true )

        -- record the attack
        self.records[params.record] = true

        -- run OrbFire script if available
        if self.ability.OnOrbFire then self.ability:OnOrbFire( params ) end
    end

    self.cast = false
end
function modifier_ability_viper_poison_attack:GetModifierProcAttack_Feedback( params )
    if self.records[params.record] then
        -- apply the effect
        if self.ability.OnOrbImpact then self.ability:OnOrbImpact( params ) end
    end
end
function modifier_ability_viper_poison_attack:OnAttackFail( params )
    if self.records[params.record] then
        -- apply the fail effect
        if self.ability.OnOrbFail then self.ability:OnOrbFail( params ) end
    end
end
function modifier_ability_viper_poison_attack:OnAttackRecordDestroy( params )
    -- destroy attack record
    self.records[params.record] = nil
end

function modifier_ability_viper_poison_attack:OnOrder( params )
    if params.unit~=self:GetParent() then return end

    if params.ability then
        -- if this ability, cast
        if params.ability==self:GetAbility() then
            self.cast = true
            return
        end

        -- if casting other ability that cancel channel while casting this ability, turn off
        local pass = false
        local behavior = params.ability:GetBehavior()
        if self:FlagExist( behavior, DOTA_ABILITY_BEHAVIOR_DONT_CANCEL_CHANNEL ) or 
            self:FlagExist( behavior, DOTA_ABILITY_BEHAVIOR_DONT_CANCEL_MOVEMENT ) or
            self:FlagExist( behavior, DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL )
        then
            local pass = true -- do nothing
        end

        if self.cast and (not pass) then
            self.cast = false
        end
    else
        -- if ordering something which cancel channel, turn off
        if self.cast then
            if self:FlagExist( params.order_type, DOTA_UNIT_ORDER_MOVE_TO_POSITION ) or
                self:FlagExist( params.order_type, DOTA_UNIT_ORDER_MOVE_TO_TARGET ) or
                self:FlagExist( params.order_type, DOTA_UNIT_ORDER_ATTACK_MOVE ) or
                self:FlagExist( params.order_type, DOTA_UNIT_ORDER_ATTACK_TARGET ) or
                self:FlagExist( params.order_type, DOTA_UNIT_ORDER_STOP ) or
                self:FlagExist( params.order_type, DOTA_UNIT_ORDER_HOLD_POSITION )
            then
                self.cast = false
            end
        end
    end
end

function modifier_ability_viper_poison_attack:GetModifierProjectileName()
    if not self.ability.GetProjectileName then return end

    if self:ShouldLaunch( self:GetCaster():GetAggroTarget() ) then
        return self.ability:GetProjectileName()
    end
end

function modifier_ability_viper_poison_attack:ShouldLaunch( target )
    -- check autocast
    if self.ability:GetAutoCastState() then
        -- filter whether target is valid
        if self.ability.CastFilterResultTarget~=CDOTA_Ability_Lua.CastFilterResultTarget then
            -- check if ability has custom target cast filter
            if self.ability:CastFilterResultTarget( target )==UF_SUCCESS then
                self.cast = true
            end
        else
            local nResult = UnitFilter(
                target,
                self.ability:GetAbilityTargetTeam(),
                self.ability:GetAbilityTargetType(),
                self.ability:GetAbilityTargetFlags(),
                self:GetCaster():GetTeamNumber()
            )
            if nResult == UF_SUCCESS then
                self.cast = true
            end
        end
    end

    if self.cast and self.ability:IsFullyCastable() and (not self:GetParent():IsSilenced()) then
        return true
    end

    return false
end

function modifier_ability_viper_poison_attack:FlagExist(a,b)
    local p,c,d=1,0,b
    while a>0 and b>0 do
        local ra,rb=a%2,b%2
        if ra+rb>1 then c=c+p end
        a,b,p=(a-ra)/2,(b-rb)/2,p*2
    end
    return c==d
end

--------------------------------------------------------------------------------


modifier_ability_viper_poison_attack_slow = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsPurgeException        = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
        }
    end,
    GetEffectName           = function(self) return "particles/units/heroes/hero_viper/viper_poison_debuff.vpcf" end,
    GetEffectAttachType     = function(self) return PATTACH_ABSORIGIN_FOLLOW end,
})


--------------------------------------------------------------------------------

function modifier_ability_viper_poison_attack_slow:OnCreated()
    self.damage = self:GetAbility():GetSpecialValueFor("damage")
    self.movement_speed = self:GetAbility():GetSpecialValueFor("movement_speed") * (-1)
    self.magic_resistance = self:GetAbility():GetSpecialValueFor("magic_resistance") * (-1)
    self.max_stacks = self:GetAbility():GetSpecialValueFor("max_stacks")

    self:StartIntervalThink(1)
end

function modifier_ability_viper_poison_attack_slow:OnRefresh()
    self.damage = self:GetAbility():GetSpecialValueFor("damage")
    self.movement_speed = self:GetAbility():GetSpecialValueFor("movement_speed") * (-1)
    self.magic_resistance = self:GetAbility():GetSpecialValueFor("magic_resistance") * (-1)
    self.max_stacks = self:GetAbility():GetSpecialValueFor("max_stacks")

    if self:GetStackCount() > self.max_stacks then
        self:SetStackCount(self.max_stacks)
    end
end

if IsServer() then
function modifier_ability_viper_poison_attack_slow:OnIntervalThink()
    local damage = self.damage * self:GetStackCount()

    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = damage,
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility()
    })

    SendOverheadEventMessage( self:GetParent(), OVERHEAD_ALERT_BONUS_POISON_DAMAGE, self:GetParent(), damage, nil )
end
end

function modifier_ability_viper_poison_attack_slow:GetModifierMoveSpeedBonus_Percentage() return self.movement_speed * self:GetStackCount() end
function modifier_ability_viper_poison_attack_slow:GetModifierMagicalResistanceBonus() return self.magic_resistance * self:GetStackCount() end