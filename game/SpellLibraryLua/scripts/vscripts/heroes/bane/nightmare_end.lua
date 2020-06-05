ability_nightmare_end = class({})
function ability_nightmare_end:OnSpellStart()
    self.parentAbility:EndNightmare( true )

    self:SetHidden(true)
    self.parentAbility:SetHidden(false)
end