LinkLuaModifier( "modifier_ability_drow_ranger_frost_arrows", "heroes/drow_ranger/frost_arrows" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_drow_ranger_frost_arrows_slow", "heroes/drow_ranger/frost_arrows" ,LUA_MODIFIER_MOTION_NONE )

if ability_drow_ranger_frost_arrows == nil then
    ability_drow_ranger_frost_arrows = class({})
end

function ability_drow_ranger_frost_arrows:GetIntrinsicModifierName()
    return "modifier_ability_drow_ranger_frost_arrows"
end

function ability_drow_ranger_frost_arrows:GetProjectileName()
    return "particles/units/heroes/hero_drow/drow_frost_arrow.vpcf"
end

function ability_drow_ranger_frost_arrows:OnOrbFire( params )
    local sound_cast = "Hero_DrowRanger.FrostArrows"
    EmitSoundOn( sound_cast, self:GetCaster() )
end

function ability_drow_ranger_frost_arrows:OnOrbImpact( params )
    local duration = self:GetDuration()

    params.target:AddNewModifier(self:GetCaster(), self, "modifier_ability_drow_ranger_frost_arrows_slow", {duration=duration})
end

--------------------------------------------------------------------------------


modifier_ability_drow_ranger_frost_arrows = class({
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

            MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        }
    end,
    GetAttributes           = function(self) return MODIFIER_ATTRIBUTE_PERMANENT end,
})


--------------------------------------------------------------------------------

function modifier_ability_drow_ranger_frost_arrows:GetModifierPreAttack_BonusDamage(k) 
    if IsServer() then
        if self:ShouldLaunch( k.target ) then
            return self:GetAbility():GetSpecialValueFor("damage")
        end
    end
    return
end

function modifier_ability_drow_ranger_frost_arrows:OnCreated()
    self.ability = self:GetAbility()
    self.cast = false
    self.records = {}
end

function modifier_ability_drow_ranger_frost_arrows:OnAttack( params )
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
function modifier_ability_drow_ranger_frost_arrows:GetModifierProcAttack_Feedback( params )
    if self.records[params.record] then
        -- apply the effect
        if self.ability.OnOrbImpact then self.ability:OnOrbImpact( params ) end
    end
end
function modifier_ability_drow_ranger_frost_arrows:OnAttackFail( params )
    if self.records[params.record] then
        -- apply the fail effect
        if self.ability.OnOrbFail then self.ability:OnOrbFail( params ) end
    end
end
function modifier_ability_drow_ranger_frost_arrows:OnAttackRecordDestroy( params )
    -- destroy attack record
    self.records[params.record] = nil
end

function modifier_ability_drow_ranger_frost_arrows:OnOrder( params )
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

function modifier_ability_drow_ranger_frost_arrows:GetModifierProjectileName()
    if not self.ability.GetProjectileName then return end

    if self:ShouldLaunch( self:GetCaster():GetAggroTarget() ) then
        return self.ability:GetProjectileName()
    end
end

function modifier_ability_drow_ranger_frost_arrows:ShouldLaunch( target )
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

function modifier_ability_drow_ranger_frost_arrows:FlagExist(a,b)
    local p,c,d=1,0,b
    while a>0 and b>0 do
        local ra,rb=a%2,b%2
        if ra+rb>1 then c=c+p end
        a,b,p=(a-ra)/2,(b-rb)/2,p*2
    end
    return c==d
end

--------------------------------------------------------------------------------


modifier_ability_drow_ranger_frost_arrows_slow = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsPurgeException        = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
        }
    end,
    GetEffectName           = function(self) return "particles/units/heroes/hero_drow/drow_frost_arrow_debuff.vpcf" end,
    GetEffectAttachType     = function(self) return PATTACH_ABSORIGIN_FOLLOW end,
    GetStatusEffectName     = function(self) return "particles/status_fx/status_effect_drow_frost_arrow.vpcf" end,
    StatusEffectPriority    = function(self) return MODIFIER_PRIORITY_HIGH end,
})


--------------------------------------------------------------------------------

function modifier_ability_drow_ranger_frost_arrows_slow:OnCreated()
    self.frost_arrows_movement_speed = self:GetAbility():GetSpecialValueFor("frost_arrows_movement_speed")
end

function modifier_ability_drow_ranger_frost_arrows_slow:OnRefresh()
    self:OnCreated()
end

function modifier_ability_drow_ranger_frost_arrows_slow:GetModifierMoveSpeedBonus_Percentage() return self.frost_arrows_movement_speed end