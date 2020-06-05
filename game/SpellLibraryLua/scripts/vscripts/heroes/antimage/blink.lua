ability_blink = class({})

function ability_blink:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local origin = caster:GetOrigin()

	-- load data
    local max_range = self:GetSpecialValueFor("blink_range")
    local min_blink_range = self:GetSpecialValueFor("min_blink_range")

	-- determine target position
	local direction = (point - origin)
	if direction:Length2D() > max_range then
		direction = direction:Normalized() * max_range
    end
    
	if direction:Length2D() < min_blink_range then
		direction = direction:Normalized() * min_blink_range
	end

	-- teleport
    FindClearSpaceForUnit( caster, origin + direction, true )
    
	local effect_cast_a = ParticleManager:CreateParticle( "particles/units/heroes/hero_antimage/antimage_blink_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast_a, 0, origin )
	ParticleManager:SetParticleControlForward( effect_cast_a, 0, direction:Normalized() )
	ParticleManager:ReleaseParticleIndex( effect_cast_a )
	EmitSoundOnLocationWithCaster( origin, "Hero_Antimage.Blink_out", self:GetCaster() )

	local effect_cast_b = ParticleManager:CreateParticle( "particles/units/heroes/hero_antimage/antimage_blink_end.vpcf", PATTACH_ABSORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast_b, 0, self:GetCaster():GetOrigin() )
	ParticleManager:SetParticleControlForward( effect_cast_b, 0, direction:Normalized() )
	ParticleManager:ReleaseParticleIndex( effect_cast_b )
	EmitSoundOnLocationWithCaster( self:GetCaster():GetOrigin(), "Hero_Antimage.Blink_in", self:GetCaster() )
end