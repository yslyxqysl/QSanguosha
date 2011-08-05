--qiaobian
sgs.ai_skill_use["@qiaobian"] = function(self, prompt)
    self:updatePlayers()
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local card = cards[1]
	
	if prompt == "@qiaobian-judge" then
		if (self.player:containsTrick("supplyshortage") and self.player:getHp() > self.player:getHandcardNum()) or
			(self.player:containsTrick("indulgence") and self.player:getHandcardNum() > self.player:getHp()-1) or
			(self.player:containsTrick("lightning") and not self:hasWizard(self.friends) and self:hasWizard(self.enemies)) or
			(self.player:containsTrick("lightning") and #self.friends > #self.enemies) then
			return "@QiaobianCard=" .. card:getEffectiveId() .."->."
		end
	end
	
	if prompt == "@qiaobian-draw" then
		self:sort(self.enemies, "handcard")
		local first, second
		if #self.enemies > 1 then
			first, second = self.enemies[1], self.enemies[2]
			if first:getHandcardNum() > 0 and second:getHandcardNum() > 0 then
				return "@QiaobianCard=" .. card:getEffectiveId() .."->".. first:objectName() .."+".. second:objectName()
			end
		elseif #self.enemies == 1 and #self.friends > 1 then
			first = self.enemies[1]
			if first:getHandcardNum() > 0 then
				return "@QiaobianCard=" .. card:getEffectiveId() .."->".. first:objectName()
			end
		end
	end
	
	if prompt == "@qiaobian-play" then
		if self.player:getHandcardNum()-2 > self.player:getHp() then return "." end
		
		self:sort(self.enemies, "hp")
		local has_armor = true
		local judge
		for _, friend in ipairs(self.friends_noself) do
			if (friend:containsTrick("lightning") and self:hasWizard(self.friends) and self:hasWizard(self.enemied)) or
				(friend:containsTrick("indulgence") and friend:getHandcardNum()-1 > friend:getHp()) or 
				friend:containsTrick("supplyshortage") then
				return "@QiaobianCard=" .. card:getEffectiveId() .."->".. friend:objectName()
			end
		end	
		
		for _, friend in ipairs(self.friends_noself) do
			if self:hasSkills(sgs.lose_equip_skill, friend) then
				return "@QiaobianCard=" .. card:getEffectiveId() .."->".. friend:objectName()
			end
			if not friend:getArmor() then has_armor = false end
		end
		
		local top_value = 0
		for _, hcard in ipairs(cards) do
			if not hcard:inherits("Jink") then
				if self:getUseValue(hcard) > top_value then	top_value = self:getUseValue(hcard) end
			end
		end
		if top_value >= 3.7 then return "." end
		
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if enemy:getArmor() and not has_armor then
				table.insert(targets, enemy)
			end
		end
		
		self:sort(targets, "defense")
		for _, target in ipairs(targets) do
			return "@QiaobianCard=" .. card:getEffectiveId() .."->".. target:objectName()
		end
	end
	
	if prompt == "@qiaobian-discard" then
		if self.player:getHandcardNum()-1 > self.player:getHp() then 
			return "@QiaobianCard=" .. card:getEffectiveId() .."->."
		end
	end
	
	return "."
end

sgs.ai_skill_playerchosen.qiaobian = function(self, targets)
	local has_delay = false;
	for _, friend in ipairs(self.friends_noself) do
		if friend:getCards("j") and friend:getCards("j"):length() > 0 then
			has_delay = true
			break
		end
	end
	
	for _, target in sgs.qlist(targets) do
		if not has_delay and self:isFriend(target) then
			return friend
		end
		if has_delay and self:isEnemy(target) then 
			return enemy
		end
	end
end

-- beige
sgs.ai_skill_invoke.beige = function(self, data)
	local damage = data:toDamage()
	return self:isFriend(damage.to)
end

-- guzheng
sgs.ai_skill_invoke.guzheng = function(self, data)
	local player = self.room:getCurrent()	
	return self:isFriend(player) or data:toInt() >= 3		
end

--zhijian
local zhijian_skill={}
zhijian_skill.name="zhijian"
table.insert(sgs.ai_skills, zhijian_skill)
zhijian_skill.getTurnUseCard = function(self)
	local equips = {}
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:getTypeId() == sgs.Card_Equip then
			table.insert(equips, card)
		end
	end
	if #equips == 0 then return end
	
	local zhijian_str = "@ZhijianCard=" .. equips[1]:getEffectiveId()
	assert(zhijian_str)
	return sgs.Card_Parse(zhijian_str)
end

sgs.ai_skill_use_func["ZhijianCard"] = function(card, use, self)
	local equips = {}
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:inherits("Armor") or card:inherits("Weapon") then
			if not self:hasSameEquip(card) then 
			else
				table.insert(equips, card)
			end
		else
			table.insert(equips, card)
		end
	end
	
	if #equips == 0 then return end
	
	local select_equip, target
	for _, friend in ipairs(self.friends_noself) do
		for _, equip in ipairs(equips) do
			if not self:hasSameEquip(equip, friend) then
				target = friend
				select_equip = equip
				break
			end
		end
		if target then break end
	end
	
	if not target then return end
	if use.to then
		use.to:append(target)
	end
	local zhijian = sgs.Card_Parse("@ZhijianCard="..select_equip:getEffectiveId())
	use.card = zhijian
end

--tuntian
sgs.ai_skill_invoke.tuntian = true

--fangquan
sgs.ai_skill_invoke.fangquan = function(self, data)
	if #self.friends == 1 then
		return false
	end

	local limit = self.player:getMaxCards()
	return self.player:getHandcardNum() <= limit
end

sgs.ai_skill_playerchosen.fangquan = function(self, targets)
	for _, target in sgs.qlist(targets) do
		if self:isFriend(target) then
			return target
		end
	end
end

--jixi
local jixi_skill={}
jixi_skill.name="jixi"
table.insert(sgs.ai_skills, jixi_skill)
jixi_skill.getTurnUseCard = function(self)
	if self.player:getPile("field"):isEmpty() or self.player:getHandcardNum()>self.player:getHp() then return end
	return sgs.Card_Parse("@JixiCard=.")
end

sgs.ai_skill_use_func["JixiCard"] = function(card, use, self)
	use.card = sgs.Card_Parse("@JixiCard=.")
end

sgs.ai_skill_playerchosen.jixi = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	
	return targets[1]
end

sgs.ai_skill_askforag.jixi = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end
	
	if #cards == 0 then return end
	
	self:sortByUseValue(cards, true)
	return cards[1]:getEffectiveId()
end

--tiaoxin
local tiaoxin_skill={}
tiaoxin_skill.name="tiaoxin"
table.insert(sgs.ai_skills, tiaoxin_skill)
tiaoxin_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("TiaoxinCard") then return end
	return sgs.Card_Parse("@TiaoxinCard=.")
end

sgs.slash_property = {}
sgs.ai_skill_use_func["TiaoxinCard"] = function(card,use,self)
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		sgs.slash_property = 
		{
			is_black = false,
			is_red = false,
			is_normal = false,
			is_fire = false,
			is_thunder = false
		}
		
		local cards = enemy:getHandcards()
		cards = sgs.QList2Table(cards)
		
		for _, card in ipairs(cards) do
			if card:inherits("Slash") then
				if card:isBlack() then sgs.slash_property["is_black"] = true end
				if card:isRed() then sgs.slash_property["is_red"] = true end
				if card:inherits("FireSlash") then sgs.slash_property["is_fire"] = true end
				if card:inherits("ThunderSlash") then sgs.slash_property["is_thunder"] = true end
				if card:inherits("NatureSlash") then sgs.slash_property["is_normal"] = true end
			end
		end
		
		local slash_useless = true
		local has_armor = self.player:getArmor()
		if has_armor then
			if self.player:getArmor():objectName() == "vine" then
				if (sgs.slash_property["is_fire"] or sgs.slash_property["is_thunder"]) then
					slash_useless = false
				end
			elseif self.player:getArmor():objectName() == "renwang_shield" then
				if sgs.slash_property["is_red"] then 
					slash_useless = false
				end
			end
		end
		
		if enemy:inMyAttackRange(self.player) and 
			(self:getSlashNumber(enemy) == 0 or slash_useless or self:getJinkNumber(self.player) > 0) then 
			table.insert(targets, enemy) 
		end
	end
		
	if #targets == 0 then return end
	
	if use.to then
		self:sort(targets, "hp")
		use.to:append(targets[1])
	end
	use.card = sgs.Card_Parse("@TiaoxinCard=.")
end
	
--zhiba
local zhiba_skill={}
zhiba_skill.name="zhiba_pindian"
table.insert(sgs.ai_skills, zhiba_skill)
zhiba_skill.getTurnUseCard = function(self)
	local lord = self.room:getLord()
	if lord:getHandcardNum() == 0 
		or self.player:getHandcardNum() == 0
		or self.player:getHandcardNum() < self.player:getHp() 
		or self.player == lord 
		or self.player:getKingdom() ~= "wu"
		or self.player:hasUsed("ZhibaCard") then 
		return 
	end
	
	local zhiba_str
	local cards = self.player:getHandcards()
	
	local max_num = 0, max_card
	local min_num = 14, min_card
	for _, hcard in sgs.qlist(cards) do
		if hcard:getNumber() > max_num then 
			max_num = hcard:getNumber() 
			max_card = hcard
		end
		
		if hcard:getNumber() <= min_num then
			if hcard:getNumber() == min_num then
				if min_card and self:getKeepValue(hcard) > self:getKeepValue(min_card) then
					min_num = hcard:getNumber() 
					min_card = hcard
				end
			else
				min_num = hcard:getNumber() 
				min_card = hcard
			end			
		end	
	end
	
	local lord_max_num = 0, lord_max_card
	local lord_min_num = 14, lord_min_card
	local lord_cards = lord:getHandcards()
	for _, lcard in sgs.qlist(lord_cards) do
		if lcard:getNumber() > lord_max_num then
			lord_max_card = lcard
			lord_max_num = lcard:getNumber()
		end
		if lcard:getNumber() < lord_min_num then
			lord_min_num = lcard:getNumber() 
			lord_min_card = lcard
		end	
	end
	
	if self:isEnemy(lord) and max_num > lord_max_num then 
		zhiba_str = "@ZhibaCard=" .. max_card:getEffectiveId() 
	end	
	if self:isFriend(lord) and min_num < lord_min_num then 
		zhiba_str = "@ZhibaCard=" .. min_card:getEffectiveId() 
	end
	
 	if not zhiba_str then return end
	
	return sgs.Card_Parse(zhiba_str)
end

sgs.ai_skill_use_func["ZhibaCard"] = function(card, use, self)
	use.card = card
	if use.to then
		use.to:append(self.room:getLord())
	end
end

sgs.ai_skill_choice["zhiba_pindian"] = function(self, choices)
	local who = self.room:getCurrent()
	if self:isEnemy(who) then return "reject"
	else return "accept"
	end
end