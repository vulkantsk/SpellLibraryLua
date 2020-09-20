ability_mana_shield = {}

LinkLuaModifier( "modifier_ability_mana_shield", "heroes/medusa/mana_shield", LUA_MODIFIER_MOTION_NONE )

function ability_mana_shield:OnToggle()
    local caster = self:GetCaster()
    local modifier = caster:FindModifierByName( "modifier_ability_mana_shield" )

    if self:GetToggleState() then
        if not modifier then
            caster:AddNewModifier(
                caster,
                self,
                "modifier_ability_mana_shield",
                {}
            )
        end
    else
        if modifier then
            modifier:Destroy()
        end
    end
end
function ability_mana_shield:ProcsMagicStick()
    return false
end

function ability_mana_shield:OnUpgrade()
    local modifier = self:GetCaster():FindModifierByName( "modifier_ability_mana_shield" )

    if modifier then
        modifier:ForceRefresh()
    end
end

modifier_ability_mana_shield = {}

function modifier_ability_mana_shield:IsHidden()
    return false
end

function modifier_ability_mana_shield:IsDebuff()
    return false
end

function modifier_ability_mana_shield:IsPurgable()
    return false
end

function modifier_ability_mana_shield:GetAttributes()
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_ability_mana_shield:OnCreated( kv )
    self.damage_per_mana = self:GetAbility():GetSpecialValueFor( "damage_per_mana" )
    self.absorb_pct = self:GetAbility():GetSpecialValueFor( "absorption_tooltip" ) / 100

    if not IsServer() then return end

    EmitSoundOn( "Hero_Medusa.ManaShield.On", self:GetParent() )
end

function modifier_ability_mana_shield:OnRefresh( kv )
    self.damage_per_mana = self:GetAbility():GetSpecialValueFor( "damage_per_mana" )
    self.absorb_pct = self:GetAbility():GetSpecialValueFor( "absorption_tooltip" )  
end

function modifier_ability_mana_shield:OnDestroy()
    if not IsServer() then return end

    EmitSoundOn( "Hero_Medusa.ManaShield.Off", self:GetParent() )
end

function modifier_ability_mana_shield:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }
end

function modifier_ability_mana_shield:GetModifierIncomingDamage_Percentage( params )
    local absorb = -100*self.absorb_pct
    local damage_absorbed = params.damage * self.absorb_pct
    local manacost = damage_absorbed/self.damage_per_mana
    local mana = self:GetParent():GetMana()

    if mana<manacost then
        damage_absorbed = mana * self.damage_per_mana
        absorb = -damage_absorbed/params.damage*100

        manacost = mana
    end

    self:GetParent():SpendMana( manacost, self:GetAbility() )

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_medusa/medusa_mana_shield_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( damage_absorbed, 0, 0 ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn( "Hero_Medusa.ManaShield.Proc", self:GetParent() )

    return absorb
end

function modifier_ability_mana_shield:GetEffectName()
    return "particles/units/heroes/hero_medusa/medusa_mana_shield.vpcf"
end

function modifier_ability_mana_shield:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end