cbtools = require("cbtools")

--[[ 
	Created by Dimitri Barronmore
	https://github.com/DimitriBarronmore/cyf-cbtools

	This wave uses only default assets. You can place it in your Waves folder and use it immediately.
	Consider this my version of the examples that come with CYF.

	CONCEPT:
	A warning-attack wave using the default sprites, in the style of the included example waves.
	The arena changes to a small-ish square. Think of the attack as happening in quadrants of said square.
	In a random order, corners of the square flash a warning. Once they've all flashed, continue.
	In the order of the previous flashes, dog bullets spring up in the indicated corners one at a time. 
	Each attack lasts only a couple of frames, but there's a brief overlap between each one.
--]]

-- We're going to change the wavetimer so that we know exactly when the wave ends.
old_wt = Encounter.GetVar("wavetimer")
Encounter.SetVar("wavetimer", math.huge)

-- Change the arena's size for the attack. Not too big, not too small.
-- This size means a corner is 74x74, and the offset from the center is 37
Arena.Resize(148, 148)


-- The logic for the attack must be written as a function to make use of CBTools.
-- Later in the file we'll be queuing it up as a one-shot coroutine.

-- As a bonus, this kind of structure makes it simple to assemble a large number of attacks, 
--   perhaps as libraries, and orchestate them one-by-one.

function corners_attack()
	-- Semi-randomly generate an order for the bullets.
	-- Every corner will flash twice, but the same corner cannot flash twice in a row.
	local corners_queue = {}
	local rand_count = {0,0,0,0}
	repeat
		local cor = math.random(1,4)
		if (rand_count[cor] ~= 2) and ((corners_queue[#corners_queue] or 0) ~= cor) then
			corners_queue[#corners_queue + 1] = cor
			rand_count[cor] = rand_count[cor] + 1
		end
	until #corners_queue == 8

	-- We'll create the warning logic right here to use later.
	local function flash_warning(corner)
		local flspr = CreateSprite("bullet", "BelowPlayer")
		flspr.color = {1,0.85,0}
		flspr.alpha = 0.7
		flspr.Scale(74/flspr.width,74/flspr.height)

		Audio.PlaySound("MenuConfirm", 1)

		-- Placement logic
		if corner < 3 then
			flspr.x = Arena.x - 37
		else
			flspr.x = Arena.x + 37
		end
		if corner % 2 == 0 then
			flspr.y = (Arena.y + Arena.height/2 + 5) - 37
		else 
			flspr.y = (Arena.y + Arena.height/2 + 5) + 37
		end

		-- Animate the flashes fading away
		cbtools.doUntil(function() return (flspr.alpha <= 0.01) end, function()
			flspr.alpha = flspr.alpha + (0 - flspr.alpha) / 5
		end)
		
		-- Remove the flash sprite entirely.
		flspr.Remove()		
	end

	-- And here's the logic for the bullets themselves.
	local function dog_bullet(corner)
		-- Initial yield for arguments.
		-- This will allow us to pass in the 'corner' argument
		--   using cbtools.queue() later without starting the 
		--   actual animation.
		coroutine.yield()

		local bul = CreateProjectile("bullet", 0, 0)
		bul.sprite.Scale(74/bul.sprite.height, 74/bul.sprite.width)

		Audio.PlaySound("BeginBattle2")

		-- Placement logic
		if corner < 3 then
			bul.absx = Arena.x - 37
		else
			bul.absx = Arena.x + 37
		end
		if corner % 2 == 0 then
			bul.absy = (Arena.y + Arena.height/2 + 5) - 37
		else 
			bul.absy = (Arena.y + Arena.height/2 + 5) + 37
		end

		-- Animate the bullets scaling down for a brief moment.
		cbtools.doFor(20, function()
			bul.sprite.xscale = bul.sprite.xscale + (0 - bul.sprite.xscale) / 80
			bul.sprite.yscale = bul.sprite.yscale + (0 - bul.sprite.yscale) / 80
		end)

		-- Finally, remove the bullet.
		bul.Remove()
	end

	-- This is where the real attack begins.

	-- Wait until the arena is the right size.
	-- This is a lambda function, something unique to Moonsharp.
	-- |x, y| x + y    is equivalent to    function(x, y) return x + y end
	cbtools.waitUntil( || (Arena.currentheight == 148) and (Arena.currentwidth == 148) ) 

	cbtools.waitFor(0.5, true) -- wait a moment for the player to be prepared.

	-- Queue up the warnings for each bullet.
	for i = 1, 8 do
		local cor = corners_queue[i]
		-- Since every flash needs to end before the next one will play, 
		--   we can call the flash animation as a blocking function.
		-- Until the doUntil loop exits, we don't leave the function.
		flash_warning(cor)
		-- Once the loop is over, execution resumes outside the function.
		-- We wait 15 frames before starting the next flash.
		cbtools.waitFor(15)
	end
	
	-- We wait for a moment before beginning the dangerous part.
	-- Note that this stacks with the final wait from the previous loop.
	cbtools.waitFor(.8, true)

	local active = {}
	for i = 1, 8 do
		local cor = corners_queue[i]
		-- Queue up the bullets to act simultaniously, passing in the corner.
		-- Keep in mind when the function first yields to avoid off-by-one-frame errors.
		-- The animation won't start until next frame, because it yields immediately.
		-- We also save the reference to a list so we can check on it later.
		active[i] = cbtools.queue(dog_bullet, "dog bullets", cor)
		-- Because the bullets last for 20 frames, 
		--   they'll have 5 frames of overlap.
		cbtools.waitFor(15)
	end	

	cbtools.waitUntil(function() 
		-- Because we have a lot of bullets animating simultaniously, 
		--   we want to wait until they've all finished their animations
		--   before moving on. We can do that with coroutine.status()
		local complete = true 
		for i = 1, #active do
			st = coroutine.status(active[i])
			if st ~= "dead" then
				complete = false
			end
		end
		return complete
	end)

	-- Now we simply include a one-second delay before the wave ends.
	cbtools.waitFor(1, true)
	EndWave()
end

-- Queue up the function as a coroutine, enabling all our waits and loops to work.
cbtools.queue(corners_attack)


function Update()
	-- The most important part. Ensure this runs every frame.
	cbtools.update()
end

function EndingWave()
	-- Change the wave timer back, just so we don't break anything.
	Encounter.SetVar("wavetimer", old_wt)
end