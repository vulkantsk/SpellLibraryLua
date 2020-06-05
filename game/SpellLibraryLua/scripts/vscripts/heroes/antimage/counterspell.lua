ability_counterspell = class({})
LinkLuaModifier( "modifier_ability_counterspell_passive", "heroes/antimage/counterspell", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_counterspell_buff", "heroes/antimage/counterspell", LUA_MODIFIER_MOTION_NONE )
function ability_counterspell:GetIntrinsicModifierName()
    return 'modifier_ability_counterspell_passive'
end 

function ability_counterspell:OnSpellStart()
    self:GetCaster():AddNewModifier(self:GetCaster(), self, 'modifier_ability_counterspell_buff', {
        duration = self:GetSpecialValueFor('duration')
    })

    self:GetCaster():EmitSound('Hero_Antimage.SpellShield.Block')
end 

modifier_ability_counterspell_passive = class({
    IsHidden        =   function(self) return true end,
    IsPurgable      =   function(self) return false end,

    DeclareFunctions    = function(self)
        return {
            MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
        }
    end,
    GetModifierMagicalResistanceBonus = function(self) return self.magic_resistance end,
})

function modifier_ability_counterspell_passive:OnCreated()
    self.magic_resistance = self:GetAbility():GetSpecialValueFor('magic_resistance')
end 

function modifier_ability_counterspell_passive:OnRefresh()
    self.magic_resistance = self:GetAbility():GetSpecialValueFor('magic_resistance')
end 

modifier_ability_counterspell_buff = class({
    IsPurgable      = function(self) return false end,
    DeclareFunctions    = function(self)
		return {
            MODIFIER_PROPERTY_ABSORB_SPELL,
            MODIFIER_PROPERTY_REFLECT_SPELL,
        }
    end,

})

function modifier_ability_counterspell_buff:GetAbsorbSpell( params )
	if IsServer() then
        local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_antimage/antimage_spellshield_reflect.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
        ParticleManager:SetParticleControlEnt(effect_cast,0,self:GetParent(),PATTACH_POINT_FOLLOW,"attach_hitloc",self:GetParent():GetOrigin(),true)
        ParticleManager:ReleaseParticleIndex( effect_cast )
        EmitSoundOn(  "Hero_Antimage.SpellShield.Reflect", self:GetParent() )
        return 1
	end
end

function modifier_ability_counterspell_buff:OnCreated()
    if IsClient() then return end
	self.effect_cast = ParticleManager:CreateParticle( 'particles/units/heroes/hero_antimage/antimage_counter.vpcf', PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControlEnt(
		self.effect_cast,
		0,
		self:GetParent(),
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		self:GetParent():GetOrigin(), -- unknown
		true -- unknown, true
    )
    
    ParticleManager:SetParticleControl(self.effect_cast, 1, Vector(120,120,120))

end

function modifier_ability_counterspell_buff:OnDestroy()
    if self.effect_cast then 
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end 
end 

function modifier_ability_counterspell_buff:GetReflectSpell(keys)
	local parent = self:GetParent()
    if parent:IsIllusion() then 
        return 
    end
    local originalAbility = keys.ability
    if originalAbility:GetCaster():GetTeam() == parent:GetTeam() then 
        return 
    end

    if IsValidEntity(self.reflect_stolen_ability) then
        self.reflect_stolen_ability:RemoveSelf()
    end

    local nfx = ParticleManager:CreateParticle('particles/units/heroes/hero_antimage/antimage_spellshield_reflect.vpcf', PATTACH_ABSORIGIN, parent)
	ParticleManager:SetParticleControlEnt(nfx,0,parent,PATTACH_POINT_FOLLOW,"attach_hitloc",parent:GetOrigin(), true )
    ParticleManager:ReleaseParticleIndex(nfx)
    self:GetCaster():EmitSound('Hero_Antimage.SpellShield.Reflect')
    local hAbility = parent:AddAbility(originalAbility:GetAbilityName())
    if hAbility then
        hAbility:SetStolen(true)
        hAbility:SetHidden(true)
        hAbility:SetLevel(originalAbility:GetLevel())
        parent:SetCursorCastTarget(originalAbility:GetCaster())
        hAbility:OnSpellStart()
        hAbility:SetActivated(false)
        self.reflect_stolen_ability = hAbility
    end
end