require "pl.strict"
local utils = require "pl.utils"
local lapp = require "pl.lapp"

math.randomseed(os.time())


local args = lapp [[
Runs a exam in test mode, generating "progress" savefile
-q, --questions (file-in) Questions file
-s, --save (optional string) Save file to use, if empty, does not use saving.
-n, --number (default 50) Sample up to this many questions
-e, --errors Sample only questions you have never answered correctly
-p, --previous Sample only questions you have previously answered correctly
-c, --category (default "all") Sample from a given category only. All includes all categories
]]

local questions = require("src.questions")(args["questions"], args["save"])
local exam = require("src.exam")(questions, args["save"], args)

local discard = io.read()

local input = ""
while exam:run(input) do
	input = io.read("l")
end
exam:post_finish()
exam:save(args["save"])
discard = io.read()
