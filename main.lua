debug = false
canToggleDebug = true
canToggleDebugMax = 0.35
canToggleDebugTimer = canToggleDebugMax

-- Timers
-- We declare these here so we don't have to edit them multiple places
canShoot = true
canShootTimerMax = 0.35
canShootTimer = canShootTimerMax
initialCreateEnemyTimerMax = 3.5
createEnemyTimerMax = initialCreateEnemyTimerMax
createEnemyTimerDecayFactor = 0.9
createEnemyTimer = createEnemyTimerMax

-- Player Object
player = {
	x = 0,
	y = 0,
	speed = 800,
	isAlive = true,
	img = nil,
	deadImg = nil
}
score = 0

-- Image Storage
bulletImg = nil
bgImg = nil

possibleEnemyPaths = {
	'assets/@2x/andrew.png',
	'assets/@2x/zeke.png',
	'assets/@2x/ian.png',
	'assets/@2x/lev.png',
	'assets/@2x/erica.png',
	'assets/@2x/pei.png',
	'assets/@2x/dan.png',
	'assets/@2x/josh.png',
	'assets/@2x/iffy.png',
	'assets/@2x/maruska.png',
	'assets/@2x/alex.png',
	'assets/@2x/ryan.png',
	'assets/@2x/chris.png',
	'assets/@2x/caroline.png',
	'assets/@2x/rachel.png',
	'assets/@2x/mrshoes.png'
}
possibleEnemyImages = {}
enemyDeadImage = nil

-- Entity Storage
bullets = {} -- array of current bullets being drawn and updated
enemies = {} -- array of current enemies on screen


-- sounds
sounds = {
	bgMusic = nil,
	shoot = nil,
	playerHit = nil,
	enemyHit = nil
}

-- fonts
fonts = {
	game_over = nil
}

-- SNES Controller
controller = nil
axisDir1 = nil
axisDir2 = nil
axisDir3 = nil
axisDir4 = nil
axisDir5 = nil
axisDir6 = nil
axisDir7 = nil
axisDir8 = nil


-- Collision detection taken function from http://love2d.org/wiki/BoundingBox.lua
-- Returns true if two boxes overlap, false if they don't
-- x1,y1 are the left-top coords of the first box, while w1,h1 are its width and height
-- x2,y2,w2 & h2 are the same, but for the second box
function CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end

function resetPlayer()
	player.x = (love.graphics.getWidth() / 2) - (player.img:getWidth() / 2)
	player.y = love.graphics.getHeight() - player.img:getHeight()

	score = 0
	player.isAlive = true
	player.deadTime = 1000
end

function reset()
	-- remove all our bullets and enemies from screen
	bullets = {}
	enemies = {}

	-- reset timers
	canToggleDebugTimer = canToggleDebugMax
	canShootTimer = canShootTimerMax
	createEnemyTimerMax = initialCreateEnemyTimerMax
	createEnemyTimer = createEnemyTimerMax

	resetPlayer()
end

function loadController()

	local joysticks = love.joystick.getJoysticks()
	if joysticks[1] then
		controller = joysticks[1]
	end

end

function loadImages()

	player.img = love.graphics.newImage('assets/@2x/plane.png')
	player.deadImg = love.graphics.newImage('assets/shooter.png')

	for i=1, #possibleEnemyPaths do
		possibleEnemyImages[i] = love.graphics.newImage(possibleEnemyPaths[i])
	end

	enemyDeadImage = love.graphics.newImage('assets/dead.png')

	bulletImg = love.graphics.newImage('assets/bullet.png')

	bgImg = love.graphics.newImage('assets/bg-star.png')
end

function loadSounds()
	sounds.bgMusic = love.audio.newSource("assets/Music/8bit_Dungeon_Level_Video_Classica.mp3", "stream")
	sounds.bgMusic:setLooping(true)
	sounds.bgMusic:setVolume(0.6)

	sounds.shoot = love.audio.newSource("assets/sounds_effects/glass2.mp3", "static")
	sounds.playerHit = love.audio.newSource("assets/sounds_effects/Crash.mp3", "static")
	sounds.enemyHit = love.audio.newSource("assets/sounds_effects/Big Explosion Cut Off.mp3", "static")
end



function loadFonts()
	fonts.game_over = love.graphics.newFont('fonts/game_over.ttf', 128)
	love.graphics.setFont(fonts.game_over)
end

-- Loading
function love.load(arg)
	loadController()
	loadImages()
	loadSounds()
	loadFonts()
	resetPlayer()
	player.isAlive = false

	love.audio.play(sounds.bgMusic)
end


-- Updating
function love.update(dt)
	-- I always start with an easy way to exit the game
	if love.keyboard.isDown('escape') then
		love.event.push('quit')
	end

	if controller then
		axisDir1, axisDir2, axisDir3, axisDir4, axisDir5, axisDir6, axisDir7, axisDir8 = controller:getAxes()
	end

	-- Time out how far apart our shots can be.
	canToggleDebugTimer = canToggleDebugTimer - (1 * dt)
	if canToggleDebugTimer < 0 then
		canToggleDebug = true
	end

	-- Time out how far apart our shots can be.
	canShootTimer = canShootTimer - (1 * dt)
	if canShootTimer < 0 then
		canShoot = true
	end

	-- Time out enemy creation
	createEnemyTimer = createEnemyTimer - (1 * dt)
	if createEnemyTimer < 0 then
		createEnemyTimer = createEnemyTimerMax

		-- Create an enemy
		randomNumber = math.random(10, love.graphics.getWidth() - 10)

		newEnemy = { x = randomNumber, y = -10, img = possibleEnemyImages[math.random(#possibleEnemyImages)], isAlive = true }
		table.insert(enemies, newEnemy)
	end


	-- update the positions of bullets
	for i, bullet in ipairs(bullets) do
		bullet.y = bullet.y - (250 * dt)

		if bullet.y < 0 then -- remove bullets when they pass off the screen
			table.remove(bullets, i)
		end
	end

	-- update the positions of enemies
	for i, enemy in ipairs(enemies) do
		if not enemy.isAlive then
			enemy.deadTime = enemy.deadTime + 1
		end

		enemy.y = enemy.y + (200 * dt)

		if enemy.y > love.graphics.getHeight() or (not enemy.isAlive and enemy.deadTime > 10) then
			table.remove(enemies, i)
		end
	end

	-- run our collision detection
	-- Since there will be fewer enemies on screen than bullets we'll loop them first
	-- Also, we need to see if the enemies hit our player
	for i, enemy in ipairs(enemies) do
		for j, bullet in ipairs(bullets) do
			if CheckCollision(enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight(), bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight()) then
				table.remove(bullets, j)
				--table.remove(enemies, i)
				enemy.isAlive = false
				enemy.deadTime = 0
				enemy.img = enemyDeadImage
				score = score + 1
				createEnemyTimerMax = createEnemyTimerMax * createEnemyTimerDecayFactor
				sounds.enemyHit:stop()
				sounds.enemyHit:play()
			end
		end

		if CheckCollision(enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight(), player.x, player.y, player.img:getWidth(), player.img:getHeight()) 
		and player.isAlive and enemy.isAlive then
			table.remove(enemies, i)
			player.isAlive = false
			player.deadTime = 0
			sounds.playerHit:play()
		end
	end


	if love.keyboard.isDown('left','a') or (controller and axisDir4 < 0) then
		if player.x > 0 then -- binds us to the map
			player.x = player.x - (player.speed*dt)
		end
	elseif love.keyboard.isDown('right','d') or (controller and axisDir4 > 0) then
		if player.x < (love.graphics.getWidth() - player.img:getWidth()) then
			player.x = player.x + (player.speed*dt)
		end
	end

	if love.keyboard.isDown('up', 'w') or (controller and axisDir5 < 0) then
		if player.y > 0 then
			player.y = player.y - (player.speed*dt)
		end
	elseif love.keyboard.isDown('down', 's') or (controller and axisDir5 > 0) then
		if player.y < (love.graphics.getHeight() - player.img:getHeight()) then
			player.y = player.y + (player.speed*dt)
		end
	end

	if (love.keyboard.isDown(' ', 'rctrl', 'lctrl', 'ctrl') or (controller and controller:isDown("3"))) and canShoot then
		-- Create some bullets
		newBullet = { x = player.x + (player.img:getWidth()/2), y = player.y, img = bulletImg }
		table.insert(bullets, newBullet)
		sounds.shoot:stop()
	    sounds.shoot:play()
	    canShoot = false
		canShootTimer = canShootTimerMax
	end

	if (love.keyboard.isDown('p')) and canToggleDebug then
		if debug == true then
			debug = false
		else
			debug = true
		end
		canToggleDebug = false
		canToggleDebugTimer = canToggleDebugMax
	end

	if not player.isAlive then
		player.deadTime = player.deadTime + 1
		if love.keyboard.isDown('r') or (controller and controller:isDown("1")) then
			reset()
		end
	end
end

function drawBg()
	love.graphics.push()
	love.graphics.draw(bgImg, 0, 0, 0, (love.graphics.getWidth() / bgImg:getWidth()), (love.graphics.getHeight() / bgImg:getHeight()))
	love.graphics.pop()
end

-- Drawing
function love.draw(dt)

	drawBg()

	if player.isAlive then
		for i, bullet in ipairs(bullets) do
			love.graphics.draw(bullet.img, bullet.x, bullet.y)
		end

		for i, enemy in ipairs(enemies) do
			love.graphics.draw(enemy.img, enemy.x, enemy.y)
		end

		love.graphics.draw(player.img, player.x, player.y)
	else
		if player.deadTime < 30 then
			love.graphics.draw(player.deadImg, player.x, player.y)
		end
		love.graphics.print("Press 'R' (key) or the 'X' (controller button) to restart", love.graphics:getWidth()/2-170, love.graphics:getHeight()/2-10)
	end

	love.graphics.setColor(255, 255, 255)
	love.graphics.print("SCORE: " .. tostring(score), 400, 10)

	if debug then
		fps = tostring(love.timer.getFPS())
		love.graphics.print("Current FPS: "..fps, 9, 10)
	end
end
