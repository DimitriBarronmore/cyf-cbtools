--[[
	Created by Dimitri Barronmore
	https://github.com/DimitriBarronmore/cyf-cbtools
--]]

local utils = {}

local function test_if_function(f)
	if (type(f) == "function") or ((getmetatable(f) or {}).__call) then
		return true
	else
		return false
	end
end

utils.waitFor = function(time, seconds)
	if time == nil then
		error("no duration given", 2)
	elseif type(time) ~= "number" then
		error("duration must be a number", 2)
	end
	local timer, complete
	if seconds == true then
		timer = Time.time
	else
		timer = 0
	end

	repeat
		if seconds == true then
			if Time.time - timer >= time then
				complete = true
			else
				coroutine.yield()
			end
		else
			timer = timer + 1
			if timer > time then
				complete = true
			else
				coroutine.yield()
			end
		end
	until complete
end

utils.waitUntil = function(cond)
	if cond == nil then error("no condition given", 2)
	elseif not test_if_function(cond) then
		error("the given condition must be a function", 2)
	end
	while true do
		local res = cond()
		if res == true then
			break
		else
			coroutine.yield()
		end
	end
end

utils.doFor = function(iterations, func)
	if iterations == nil then error("no count given", 2)
	elseif type(iterations) ~= "number" then error("count argument must be a number", 2) end

	if func == nil then error("no runner function given", 2)
	elseif not test_if_function(func) then
		error("the second argument must be a function", 2)
	end
	local t = 0
	while t < iterations do
		t = t + 1
		func()
		coroutine.yield()
	end
end

utils.doUntil = function(condition, func)
	if condition== nil then
		error("no condition provided", 2)
	elseif not test_if_function(condition) then 
		error("provided condition must be a function", 2) 
	end
	if func == nil then
		error("must provide a function to be looped", 2)
	elseif not test_if_function(func) then 
		error("the second argument must be a function", 2) 
	end

	while true do
		local res = condition()
		if res == true then
			break
		else
			func()
			coroutine.yield()
		end
	end
end

local update_queue = {}
local name_queue = {}

utils.queue = function(func, name, ...)
	if not test_if_function(func) then
		error("attempt to queue object of type " .. type(func))
	end
	if name == nil then
		for k,v in pairs(_ENV) do
			if v == func then
				name = k
			end
		end
	end
	name = name or "<unknown>"

	local co = coroutine.create(func)
	if ... then
		res, err = coroutine.resume(co, ...)
		if res == false then
			error("error while queueing coroutine " .. name .. ": \n" .. err, 2)
		end
	end
	table.insert(update_queue, co)
	table.insert(name_queue, name)
	return co
end

utils.update = function()
	local num, to_del = #update_queue, {}
	for i = 1, num do
		local co = update_queue[i]
		res, err = coroutine.resume(co)
		if res == false then
			error("error in queued coroutine " .. name_queue[i] .. ": \n" .. err, 2)
		end
		if coroutine.status(co) == "dead" then
			table.insert(to_del, i)
		end
	end
	for i = #to_del, 1, -1 do
		table.remove(update_queue, to_del[i])
		table.remove(name_queue, to_del[i])
	end
end

local looping_mt = {
	__call = function(t, ...)
		if coroutine.status(t.routine) == "dead" then
			t.routine = coroutine.create(t.method)
		end
		local res, err = coroutine.resume(t.routine, ...)
		if res == false then
			error("error with looping coroutine: \n" .. err, 2)
		end
	end
}

utils.createLooping = function(func)
	local functab = {}
	functab.method = func
	functab.routine = coroutine.create( func )
	setmetatable(functab, looping_mt)
	return functab
end



return utils