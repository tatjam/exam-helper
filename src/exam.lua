local class = require "pl.class"
require "src.questions"
local tablex = require "pl.tablex"

class.Exam()

---@param questions Questions
---@param args table
function Exam:_init(questions, save, args)
	self.questions = questions
	self.show_result = true

	local question_number = args["number"]
	local question_pool = {}

	local category = args["category"]
	if category == "all" then
		for _, cat in pairs(self.questions.categories) do
			tablex.insertvalues(question_pool, cat)
		end 
	else
		question_pool = tablex.deepcopy(self.questions.categories[category])
	end

	self.test = {}
	self.results = {}
	print("Question pool has " .. tostring(#question_pool) .. " questions")
	-- Choose from the pool
	while #question_pool > 0 and #self.test < question_number do
		local idx = math.random(1, #question_pool)
		local question = question_pool[idx] 
		if args["errors"] then
			if question.solved then
				goto continue
			end
		elseif args["previous"] then
			if not question.solved then
				goto continue
			end 
		end
		if question.solved then
			table.insert(self.results, question)
		end
		table.insert(self.test, question)
		::continue::
		table.remove(question_pool, idx)
	end

	self.score = 0

	print("Test will contain " .. #self.test .. " questions")
	self.wait = false
end

---@param input string
function Exam:run(input)
	if self.wait then
		self.wait = false
		self.show_result = true
		return true
	end

	if self.show_result then
		-- Show the next question
		if #self.test == 0 then
			return false 
		end

		os.execute("clear")
		print("Questions remaining: " .. #self.test)
	
		local question = self.test[1] 
		self.cur_question = question
		print(question.text)
		if question.is_choice then
			for k, ans in ipairs(question.answers) do
				print(string.char(96 + k) .. "\t " .. ans.text)
			end
			print("")
			io.write("Answer > ")
		else
			print("")
			io.write("True or false? > ")

		end
		table.remove(self.test, 1)
		self.show_result = false
		return true
	else 
		local valid = false
		local correct = 0
		if self.cur_question.is_choice then
			valid = true
			local num_correct = 0
			for _, v in ipairs(self.cur_question.answers) do
				if v.correct then
					num_correct = num_correct + 1
				end
			end
			for i=1,#input do
				local var = string.byte(input, i) - 96
				if var <= 0 or var >= #self.cur_question.answers then
					valid = false
				else
					local ans = self.cur_question.answers[var]
					if ans.correct then
						correct = correct + 1.0 / num_correct
					else
						correct = correct - 1.0 / num_correct
					end
				end
			end
		else
			local inp = self.questions.is_true(input) 
			if inp ~= nil then
				valid = true
			end
			if inp == self.cur_question.result then
				correct = 1
			end
		end
		if not valid then
			print("Unable to understand your answer") 
			io.write("> ")
			return true
		else
			print("You scored " .. correct)
			self.score = self.score + correct
			if correct >= 0.9999 then
				local res = {}
				table.insert(self.results, self.cur_question)
			else
				local found = nil
				for i, v in ipairs(self.results) do
					if v == self.cur_question then
						found = i
					end	
				end
				if found then
					table.remove(self.results, found)
				end
			end
			print("")
			print("Answer: ")
			if self.cur_question.is_choice then
				for i, v in ipairs(self.cur_question.answers) do
					if v.correct then
						io.write(string.char(96 + i) .. ", ")
					end
				end
			else
				print("\t " .. tostring(self.cur_question.result))
			end
			self.show_result = true
			return true
		end
	end 
end

function Exam:post_finish()
	print("Exam finished.")
	print("You scored: " .. self.score)
end

function Exam:save(save)
	if not save then
		return
	end

	local f = io.open(save, "w+")
	if not f then
		print("Unable to open save file")
		return
	end
	for _, v in ipairs(self.results) do
		f:write(v.category .. " " .. v.idx) 
		f:write("\n")
	end
	f:close()
end

return Exam