local class = require "pl.class"
local pretty = require "pl.pretty"
local sip = require "pl.sip"

local true_strings = {"True", "true", "TRUE", "T", "V", "VERDADERO", "Verdadero", "verdadero"}
local false_strings = {"False", "false", "FALSE", "F", "FALSO", "Falso", "falso"}

function is_true(sstr)
	for _, str in ipairs(true_strings) do 
		if str == sstr then
			return true
		end
	end
	for _, str in ipairs(false_strings) do 
		if str == sstr then
			return false
		end
	end

	return nil
end

---@class Questions
local Questions = class()

Questions.is_true = is_true

---@param file file*
---@param save string
function Questions:_init(file, save)
	
	local value = file:read("l")
	local category_matcher = sip.compile("# $v{cat}", {})
	local answer_matcher = sip.compile(" $v{name} <$v{val}> $r{text}", {})
	local tf_matcher = sip.compile(" $v{name} ", {})

	local save_matcher = sip.compile(" $v{cat} $d{idx} ")
	
	assert(category_matcher)
	assert(answer_matcher)
	assert(tf_matcher)
	assert(save_matcher)

	self.categories = {}

	local category = "root"
	self.categories[category] = {}

	local question = {}
	local in_question = false
	local total = 0

	local i = 1
	while value do
		local tb = {}
		if in_question then
			if answer_matcher(value, tb) then
				question.is_choice = true
				local answer = {}
				answer.true_or_false = false
				answer.text = tb.text
				answer.correct = is_true(tb.val)
				assert(answer.correct ~= nil)
				table.insert(question.answers, answer)
			elseif tf_matcher(value, tb) then
				local val = is_true(tb.name)
				if val ~= nil then
					assert(not question.is_choice)
					question.result = is_true(tb.name)
				else
					in_question = false
					question.idx = i
					question.category = category
					table.insert(self.categories[category], question)
					i = i + 1
				end
			else
				in_question = false
				question.idx = i
				question.category = category
				table.insert(self.categories[category], question)
				i = i + 1
			end
		end

		if not in_question then
			if category_matcher(value, tb) then
				print("Loaded category " .. category .. " with " .. 
					tostring(#self.categories[category]) .. " questions")
				total = total + #self.categories[category]
				category = tb.cat
				self.categories[category] = {}
				i = 1
			else
				question = {}
				question.text = value
				question.answers = {}
				question.is_choice = false
				in_question = true
			end
		end
		value = file:read("l")
	end
	print("Loaded category " .. category .. " with " .. 
		tostring(#self.categories[category]) .. " questions")
	total = total + #self.categories[category]

	file:close()

	if save then
		local savef = io.open(save, "r")
			if savef then
			-- Load the savefile for answered questions
			value = savef:read("l")
			local count = 0
			for k, v in pairs(self.categories) do
				print(k .. " has " .. #v .. " questions")
			end
			while value do
				local tb = {}
				if save_matcher(value, tb) then
					if self.categories[tb.cat] == nil then
						print("Wrong save file used, aborting")
						goto abort
					end
					self.categories[tb.cat][tb.idx].solved = true
					count = count + 1
				end
				
				value = savef:read("l")
			end

			print("You have already solved: " .. tostring(count) .. " questions out of " .. 
					total .. " (" .. tostring(count / total * 100.0) .. "%)")
			::abort::
			savef:close()
		else 
			print("You have solved no questions out of " .. total)
		end
	else
		print("Saving disabled. You have solved no questions out of " .. total)
	end

end

return Questions