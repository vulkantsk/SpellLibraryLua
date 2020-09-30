ability_rearm = {}

function ability_rearm:OnSpellStart()
	EmitSoundOn( "Hero_Tinker.Rearm", self:GetCaster() )
end

function ability_rearm:OnChannelFinish( bInterrupted )
	local caster = self:GetCaster()

	local sound_cast = "Hero_Tinker.Rearm"
	StopSoundOn( sound_cast, self:GetCaster() )

	if bInterrupted then return end

	for i=0,caster:GetAbilityCount()-1 do
		local ability = caster:GetAbilityByIndex( i )
		if ability and ability:GetAbilityType()~=DOTA_ABILITY_TYPE_ATTRIBUTES then
			ability:RefreshCharges()
			ability:EndCooldown()
		end
	end

	for i=0,8 do
		local item = caster:GetItemInSlot(i)
		if item then
			local pass = false
			if item:GetPurchaser()==caster and not self:IsItemException( item ) then
				pass = true
			end

			if pass then
				item:EndCooldown()
			end
		end
	end

	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_tinker/tinker_rearm.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Tinker.RearmStart", self:GetCaster() )
end

function ability_rearm:IsItemException( item )
	return self.ItemException[item:GetName()]
end

ability_rearm.ItemException = {
	["item_aeon_disk"] = true,
	["item_arcane_boots"] = true,
	["item_black_king_bar"] = true,
	["item_hand_of_midas"] = true,
	["item_helm_of_the_dominator"] = true,
	["item_meteor_hammer"] = true,
	["item_necronomicon"] = true,
	["item_necronomicon_2"] = true,
	["item_necronomicon_3"] = true,
	["item_refresher"] = true,
	["item_refresher_shard"] = true,
	["item_pipe"] = true,
	["item_sphere"] = true,
}