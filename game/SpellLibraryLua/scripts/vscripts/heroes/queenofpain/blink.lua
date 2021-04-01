ability_qop_blink = {}

function ability_qop_blink:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local origin = caster:GetOrigin()

	local max_range = self:GetSpecialValueFor("blink_range")

	local direction = (point - origin)
	if direction:Length2D() > max_range then
		direction = direction:Normalized() * max_range
	end

	FindClearSpaceForUnit( caster, origin + direction, true )

	local effect_cast_a = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_queenofpain/queen_blink_start.vpcf",
		PATTACH_ABSORIGIN,
		self:GetCaster()
	)
	ParticleManager:SetParticleControl( effect_cast_a, 0, origin )
	ParticleManager:SetParticleControlForward( effect_cast_a, 0, direction:Normalized() )
	ParticleManager:SetParticleControl( effect_cast_a, 1, origin + direction )
	ParticleManager:ReleaseParticleIndex( effect_cast_a )
	EmitSoundOnLocationWithCaster( origin, "Hero_QueenOfPain.Blink_out", self:GetCaster() )

	local effect_cast_b = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_queenofpain/queen_blink_end.vpcf",
		PATTACH_ABSORIGIN,
		self:GetCaster()
	)
	ParticleManager:SetParticleControl( effect_cast_b, 0, self:GetCaster():GetOrigin() )
	ParticleManager:SetParticleControlForward( effect_cast_b, 0, direction:Normalized() )
	ParticleManager:ReleaseParticleIndex( effect_cast_b )
	EmitSoundOnLocationWithCaster( self:GetCaster():GetOrigin(), "Hero_QueenOfPain.Blink_in", self:GetCaster() )
end