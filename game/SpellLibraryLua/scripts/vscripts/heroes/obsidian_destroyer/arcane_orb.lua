LinkLuaModifier( "modifier_ability_arcane_orb", "heroes/obsidian_destroyer/arcane_orb", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_arcane_orb_stack", "heroes/obsidian_destroyer/arcane_orb", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_arcane_orb_orb", "heroes/obsidian_destroyer/arcane_orb", LUA_MODIFIER_MOTION_NONE )

ability_arcane_orb = {}

function ability_arcane_orb:GetIntrinsicModifierName()
	return "modifier_ability_arcane_orb_orb"
end

function ability_arcane_orb:GetProjectileName()
	return "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_arcane_orb.vpcf"
end

function ability_arcane_orb:OnOrbFire( params )
	EmitSoundOn( "Hero_ObsidianDestroyer.ArcaneOrb", self:GetCaster() )
end

function ability_arcane_orb:OnOrbImpact( params )
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor( "int_steal_duration" )
	local steal = self:GetSpecialValueFor( "int_steal" )
	local mana_pool = self:GetSpecialValueFor( "mana_pool_damage_pct" )
	local radius = self:GetSpecialValueFor( "radius" )
	local damage = caster:GetMana() * mana_pool/100
	local damageTable = {
		attacker = caster,
		damage = damage,
		damage_type = self:GetAbilityDamageType(),
		ability = self,
	}

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		params.target:GetOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		damageTable.victim = enemy
		ApplyDamage( damageTable )

		SendOverheadEventMessage(
			nil,
			OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,
			enemy,
			damageTable.damage,
			nil
		)
	end

	params.target:AddNewModifier(
		caster,
		self,
		"modifier_ability_arcane_orb",
		{
			duration = duration,
			steal = steal,
		}
	)

	caster:AddNewModifier(
		caster,
		self,
		"modifier_ability_arcane_orb",
		{
			duration = duration,
			steal = steal,
		}
	)

	EmitSoundOn( "Hero_ObsidianDestroyer.ArcaneOrb.Impact", params.target )
end

modifier_ability_arcane_orb = {}

function modifier_ability_arcane_orb:IsHidden()
	return false
end

function modifier_ability_arcane_orb:IsDebuff()
	return self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber()
end

function modifier_ability_arcane_orb:IsStunDebuff()
	return false
end

function modifier_ability_arcane_orb:IsPurgable()
	return false
end

function modifier_ability_arcane_orb:RemoveOnDeath()
	return false
end

function modifier_ability_arcane_orb:OnCreated( kv )
	self.debuff = self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber()
	self.mult = 1
	if self.debuff then
		self.mult = -1
	end

	if not IsServer() then return end

	self:AddStack( kv.steal, kv.duration )
end

function modifier_ability_arcane_orb:OnRefresh( kv )
	if not IsServer() then return end

	self:AddStack( kv.steal, kv.duration )
end

function modifier_ability_arcane_orb:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_INTELLECT_BONUS }
end

function modifier_ability_arcane_orb:GetModifierBonusStats_Intellect()
	return self.mult * self:GetStackCount()
end

function modifier_ability_arcane_orb:AddStack( value, duration )
	self:SetStackCount( self:GetStackCount() + value )

	local modifier = self:GetParent():AddNewModifier(
		self:GetCaster(),
		self:GetAbility(),
		"modifier_ability_arcane_orb_stack",
		{
			duration = duration,
			stack = value,
		}
	)

	modifier.modifier = self

	if self.debuff then
		self:GetParent():ReduceMana( value * 12 )
	end
end

function modifier_ability_arcane_orb:RemoveStack( value )
	self:SetStackCount( self:GetStackCount() - value )

	if self.debuff then
		self:GetParent():GiveMana( value * 12 )
	end

	if self:GetStackCount()<=0 then
		self:Destroy()
	end
end

modifier_ability_arcane_orb_stack = {}

function modifier_ability_arcane_orb_stack:IsHidden()
	return true
end

function modifier_ability_arcane_orb_stack:IsPurgable()
	return false
end

function modifier_ability_arcane_orb_stack:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE 
end

function modifier_ability_arcane_orb_stack:OnCreated( kv )
	if not IsServer() then return end
	self.stack = kv.stack
end

function modifier_ability_arcane_orb_stack:OnRemoved()
end

function modifier_ability_arcane_orb_stack:OnDestroy()
	if not IsServer() then return end

	if self.modifier then
		self.modifier:RemoveStack( self.stack )
	end
end

modifier_ability_arcane_orb_orb = {}

function modifier_ability_arcane_orb_orb:IsHidden()
	return true
end

function modifier_ability_arcane_orb_orb:IsDebuff()
	return false
end

function modifier_ability_arcane_orb_orb:IsPurgable()
	return false
end

function modifier_ability_arcane_orb_orb:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_ability_arcane_orb_orb:OnCreated( kv )
	self.ability = self:GetAbility()
	self.cast = false
	self.records = {}
end

function modifier_ability_arcane_orb_orb:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_FAIL,
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
		MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
		MODIFIER_EVENT_ON_ORDER,
		MODIFIER_PROPERTY_PROJECTILE_NAME,
	}
end

function modifier_ability_arcane_orb_orb:OnAttack( params )
	if params.attacker~=self:GetParent() then return end

	if self:ShouldLaunch( params.target ) then
		self.ability:UseResources( true, false, true )

		self.records[params.record] = true

		if self.ability.OnOrbFire then self.ability:OnOrbFire( params ) end
	end

	self.cast = false
end
function modifier_ability_arcane_orb_orb:GetModifierProcAttack_Feedback( params )
	if self.records[params.record] then
		if self.ability.OnOrbImpact then self.ability:OnOrbImpact( params ) end
	end
end
function modifier_ability_arcane_orb_orb:OnAttackFail( params )
	if self.records[params.record] then
		if self.ability.OnOrbFail then self.ability:OnOrbFail( params ) end
	end
end
function modifier_ability_arcane_orb_orb:OnAttackRecordDestroy( params )
	self.records[params.record] = nil
end

function modifier_ability_arcane_orb_orb:OnOrder( params )
	if params.unit~=self:GetParent() then return end

	if params.ability then
		if params.ability==self:GetAbility() then
			self.cast = true
			return
		end

		local pass = false
		local behavior = tonumber( tostring( params.ability:GetBehavior() ) )
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

function modifier_ability_arcane_orb_orb:GetModifierProjectileName()
	if not self.ability.GetProjectileName then return end

	if self:ShouldLaunch( self:GetCaster():GetAggroTarget() ) then
		return self.ability:GetProjectileName()
	end
end

function modifier_ability_arcane_orb_orb:ShouldLaunch( target )
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

function modifier_ability_arcane_orb_orb:FlagExist(a,b)
	local p,c,d=1,0,b

	while a>0 and b>0 do
		local ra,rb=a%2,b%2
		if ra+rb>1 then c=c+p end
		a,b,p=(a-ra)/2,(b-rb)/2,p*2
	end

	return c==d
end