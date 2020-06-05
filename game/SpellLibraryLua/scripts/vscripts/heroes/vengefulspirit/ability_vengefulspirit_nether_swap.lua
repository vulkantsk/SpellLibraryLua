if ability_vengefulspirit_nether_swap == nil then
    ability_vengefulspirit_nether_swap = class({})
end

--------------------------------------------------------------------------------

function ability_vengefulspirit_nether_swap:CastFilterResultTarget( target )
    if target ~= nil and target == self:GetCaster() then
        return UF_FAIL_OTHER
    end
    
    return UF_SUCCESS
end

function ability_vengefulspirit_nether_swap:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if target:GetTeam() ~= caster:GetTeam() then
        if target:TriggerSpellAbsorb(self) then
            return nil
        end
        target:Stop()
    end
    
    caster:EmitSound("Hero_VengefulSpirit.NetherSwap")
    target:EmitSound("Hero_VengefulSpirit.NetherSwap")

    local caster_pos = caster:GetAbsOrigin()
    local target_pos = target:GetAbsOrigin()

    ProjectileManager:ProjectileDodge(caster)
    if target:GetTeamNumber() == caster:GetTeamNumber() then
        ProjectileManager:ProjectileDodge(target)
    end

    local caster_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_vengeful/vengeful_nether_swap.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControlEnt(caster_pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(caster_pfx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

    local target_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_vengeful/vengeful_nether_swap_target.vpcf", PATTACH_ABSORIGIN, target)
    ParticleManager:SetParticleControlEnt(target_pfx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(target_pfx, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)

    caster:SetAbsOrigin(target_pos)
    target:SetAbsOrigin(caster_pos)

    FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
    FindClearSpaceForUnit(target, target:GetAbsOrigin(), true)

    GridNav:DestroyTreesAroundPoint(caster:GetAbsOrigin(), 300, false)
    GridNav:DestroyTreesAroundPoint(target:GetAbsOrigin(), 300, false)
end