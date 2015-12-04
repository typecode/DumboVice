-- Configuration
function love.conf(t)
	t.title = "DUMBO Vice" -- The title of the window the game is in (string)
	t.version = "0.9.1"         -- The LÖVE version this game was made for (string)
    t.identity = 'vice'
	--t.window.width = 1280        -- we want our game to be long and thin.
	--t.window.height = 800
    t.window.fullscreen = true
    t.window.fullscreentype = "desktop"

	-- For Windows debugging
	t.console = true
end
