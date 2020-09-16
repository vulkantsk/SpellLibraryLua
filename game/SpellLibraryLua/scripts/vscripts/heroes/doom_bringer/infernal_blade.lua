ability_infernal_blade = {}

LinkLuaModifier( "modifier_ability_infernal_blade_attack", "heroes/doom_bringer/infernal_blade", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_infernal_blade_stun", "heroes/doom_bringer/infernal_blade", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_infernal_blade", "heroes/doom_bringer/infernal_blade", LUA_MODIFIER_MOTION_NONE )

function ability_infernal_blade:GetIntrinsicModifierName()
	return "modifier_ability_infernal_blade_attack"
end

function ability_infernal_blade:OnOrbImpact( params )
	local duration = self:GetSpecialValueFor( "burn_duration" )
	local bash = self:GetSpecialValueFor( "ministun_duration" )

	params.target:AddNewModifier(
		self:GetCaster(),
		self,
		"modifier_ability_infernal_blade",
		{ duration = duration }
	)

	params.target:AddNewModifier(
		self:GetCaster(),
		self,
		"modifier_ability_infernal_blade_stun",
		{ duration = bash }
	)
end

modifier_ability_infernal_blade = {}

function modifier_ability_infernal_blade:IsHidden()
	return false
end

function modifier_ability_infernal_blade:IsDebuff()
	return true
end

function modifier_ability_infernal_blade:IsStunDebuff()
	return false
end

function modifier_ability_infernal_blade:IsPurgable()
	return true
end

function modifier_ability_infernal_blade:OnCreated( kv )
	if not IsServer() then return end

	self.damage = self:GetAbility():GetSpecialValueFor( "burn_damage" )
	self.damage_pct = self:GetAbility():GetSpecialValueFor( "burn_damage_pct" )
	local interval = 1

	self.damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self,
	}

	self:StartIntervalThink( interval )

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_doom_bringer/doom_infernal_blade_impact.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self:GetParent()
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn(  "Hero_DoomBringer.InfernalBlade.Target", self:GetParent() )
end

modifier_ability_infernal_blade.OnRefresh = OnCreated

function modifier_ability_infernal_blade:OnIntervalThink()
	self.damageTable.damage = self.damage + (self.damage_pct/100)*self:GetParent():GetMaxHealth()

	ApplyDamage( self.damageTable )
end

function modifier_ability_infernal_blade:GetEffectName()
	return "particles/units/heroes/hero_doom_bringer/doom_infernal_blade_debuff.vpcf"
end

function modifier_ability_infernal_blade:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_ability_infernal_blade_attack = class({})

function modifier_ability_infernal_blade_attack:IsHidden()
	return true
end

function modifier_ability_infernal_blade_attack:IsDebuff()
	return false
end

function modifier_ability_infernal_blade_attack:IsPurgable()
	return false
end

function modifier_ability_infernal_blade_attack:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_ability_infernal_blade_attack:OnCreated( kv )
	self.ability = self:GetAbility()
	self.cast = false
	self.records = {}
end

function modifier_ability_infernal_blade_attack:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_FAIL,
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
		MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
		MODIFIER_EVENT_ON_ORDER,
	}

	return funcs
end

function modifier_ability_infernal_blade_attack:OnAttack( params )
	if params.attacker~=self:GetParent() then return end

	if self:ShouldLaunch( params.target ) then
		self.ability:UseResources( true, false, true )

		self.records[params.record] = true

		if self.ability.OnOrbFire then self.ability:OnOrbFire( params ) end
	end

	self.cast = false
end
function modifier_ability_infernal_blade_attack:GetModifierProcAttack_Feedback( params )
	if self.records[params.record] then
		if self.ability.OnOrbImpact then self.ability:OnOrbImpact( params ) end
	end
end
function modifier_ability_infernal_blade_attack:OnAttackFail( params )
	if self.records[params.record] then
		if self.ability.OnOrbFail then self.ability:OnOrbFail( params ) end
	end
end
function modifier_ability_infernal_blade_attack:OnAttackRecordDestroy( params )
	self.records[params.record] = nil
end

function modifier_ability_infernal_blade_attack:OnOrder( params )
	if params.unit~=self:GetParent() then return end

	if params.ability then
		if params.ability==self:GetAbility() then
			self.cast = true
			return
		end

		local pass = false
		local behavior = params.ability:GetBehavior()
		if self:FlagExist( behavior, DOTA_ABILITY_BEHAVIOR_DONT_CANCEL_CHANNEL ) or 
			self:FlagExist( behavior, DOTA_ABILITY_BEHAVIOR_DONT_CANCEL_MOVEMENT ) or
			self:FlagExist( behavior, DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL )
		then
			local pass = true
		end

		if self.cast and (not pass) then
			self.cast = false
		end
	else
		if self.cast then
			if self:FlagExist( params.order_type, DOTA_UNIT_ORDER_MOVE_TO_POSITION ) or
				self:FlagExist( params.order_type, DOTA_UNIT_ORDER_MOVE_TO_TARGET )	or
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

function modifier_ability_infernal_blade_attack:ShouldLaunch( target )
	if self.ability:GetAutoCastState() then
		if self.ability.CastFilterResultTarget~=CDOTA_Ability_Lua.CastFilterResultTarget then
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

function modifier_ability_infernal_blade_attack:FlagExist(a,b)
	local p,c,d=1,0,b
	while a>0 and b>0 do
		local ra,rb=a%2,b%2
		if ra+rb>1 then c=c+p end
		a,b,p=(a-ra)/2,(b-rb)/2,p*2
	end
	return c==d
end

modifier_ability_infernal_blade_stun = {}

function modifier_ability_infernal_blade_stun:IsDebuff()
	return true
end

function modifier_ability_infernal_blade_stun:IsStunDebuff()
	return true
end

function modifier_ability_infernal_blade_stun:IsPurgable()
	return true
end

function modifier_ability_infernal_blade_stun:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function modifier_ability_infernal_blade_stun:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_ability_infernal_blade_stun:GetOverrideAnimation( params )
	return ACT_DOTA_DISABLED
end

function modifier_ability_infernal_blade_stun:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_ability_infernal_blade_stun:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end