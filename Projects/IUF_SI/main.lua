-- DAN ODIN, 2 AUG, FALLING IN LÖVE WITH SPACE

function love.load()
    math.randomseed(os.time())
    love.window.setTitle("IUF: Space Impact")
    love.window.setMode(800, 600)
    initGame()
end
function initGame()
    player = {
        x = 50, y = 300,
        Movement = {speed = 200},
        Combat = {health = 100, 
                  shield = 1, 
                  max_shield = 3,  
                  damage = 10, 
                  fire_rate = 0.1, 
                  last_shot = 0}
    }
    enemies = {}
    bullets = {}
    powerups = {}
    particles = {}
    spawner = {
        timer = 120,
        wave = 1,
        last_spawn = 0,
        scaling_timer = 60
    }
    ENEMY_WEIGHTS = {
        {type="shooter", prob=0.6},
        {type="diver", prob=0.3},
        {type="targetor", prob=0.1}
    }
    SHOOTER_FIRE_RATES = {1.5, 0.8, 0.45}
    game_state = "playing"
    coins = 0
    high_score = 0
    upgrade_feedback = {
        timer = 0,
        message = "" 
    }
    respawn_feedback = {timer = 0}
    restart_feedback = {timer = 0}
end
function updatePlayer(dt)
    if love.keyboard.isDown("up") then player.y = math.max(0, player.y - player.Movement.speed * dt) end
    if love.keyboard.isDown("down") then player.y = math.min(568, player.y + player.Movement.speed * dt) end
    if love.keyboard.isDown("left") then player.x = math.max(0, player.x - player.Movement.speed * dt) end
    if love.keyboard.isDown("right") then player.x = math.min(768, player.x + player.Movement.speed * dt) end
    if love.keyboard.isDown("space") and love.timer.getTime() - player.Combat.last_shot > player.Combat.fire_rate then
        firePlayerBullet()
        player.Combat.last_shot = love.timer.getTime()
    end
end
function firePlayerBullet()
    table.insert(bullets, {
        x = player.x + 32,
        y = player.y + 12,
        Projectile = {
            speed = 400,
            damage = player.Combat.damage,
            is_enemy = false
        }
    })
end
function updateBullets(dt)
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        bullet.x = bullet.x + (bullet.Projectile.is_enemy and -bullet.Projectile.speed or bullet.Projectile.speed) * dt
        if bullet.x < -50 or bullet.x > 850 then
            table.remove(bullets, i)
        end
    end
end
function updateEnemies(dt)
    if not enemies then enemies = {} end
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        enemy.x = enemy.x - enemy.Movement.speed * dt
        if enemy.Movement.type == "targetor" then
            local dy = player.y - enemy.y
            enemy.y = enemy.y + math.min(math.max(dy * 150 * dt, -150 * dt), 150 * dt)
            enemy.y = math.max(50, math.min(550, enemy.y))
        else
            enemy.y = math.max(50, math.min(550, enemy.y + (enemy.Movement.y_speed or 0) * dt))
        end
        if enemy.Combat.fire_rate > 0 and love.timer.getTime() - enemy.Combat.last_shot > enemy.Combat.fire_rate then
            fireEnemyBullet(enemy)
            enemy.Combat.last_shot = love.timer.getTime()
        end
        if enemy.x < -50 then
            table.remove(enemies, i)
        end
    end
end
function fireEnemyBullet(enemy)
    local bullet_speed = 300
    if spawner.wave == 2 then
        bullet_speed = bullet_speed * 1.15
    elseif spawner.wave >= 3 then
        bullet_speed = bullet_speed * 1.3225
    end
    table.insert(bullets, {
        x = enemy.x - 24,
        y = enemy.y + 12,
        Projectile = {
            speed = bullet_speed,
            damage = 10,
            is_enemy = true
        }
    })
end
function updatePowerups(dt)
    for i = #powerups, 1, -1 do
        local powerup = powerups[i]
        if powerup.Powerup.type == "coin" then
            powerup.life = powerup.life - dt
            if powerup.life <= 0 then
                table.remove(powerups, i)
            else
                powerup.x = powerup.x + math.cos(powerup.angle) * powerup.speed * dt
                powerup.y = powerup.y + math.sin(powerup.angle) * powerup.speed * dt
            end
        else
            powerup.x = powerup.x - powerup.Movement.speed * dt
            if powerup.x < -50 then
                table.remove(powerups, i)
            end
        end
    end
end
function updateParticles(dt)
    for i = #particles, 1, -1 do
        local particle = particles[i]
        particle.life = particle.life - dt
        if particle.life <= 0 then
            table.remove(particles, i)
        else
            local angle = particle.angle
            particle.x = particle.x + math.cos(angle) * particle.speed * dt
            particle.y = particle.y + math.sin(angle) * particle.speed * dt
            particle.color[2] = 0.5 + (particle.life / 0.8) * 0.5
        end
    end
end
function updateSpawner(dt)
    spawner.last_spawn = spawner.last_spawn + dt
    if spawner.last_spawn > 2 then
        spawnEnemy()
        spawner.last_spawn = 0
    end
end
function spawnEnemy()
    local r = math.random()
    local cumulative = 0
    local enemy_type = "shooter"
    for _, weight in ipairs(ENEMY_WEIGHTS) do
        cumulative = cumulative + weight.prob
        if r < cumulative then
            enemy_type = weight.type
            break
        end
    end
    local health = math.random(10, 100)
    local base_speed = enemy_type == "shooter" and 100 or enemy_type == "diver" and 250 or 200
    if spawner.wave == 2 then
        base_speed = base_speed * 1.15
    elseif spawner.wave >= 3 then
        base_speed = base_speed * 1.3225
    end
    table.insert(enemies, {
        x = 850,
        y = math.random(50, 550),
        Movement = {
            type = enemy_type,
            speed = base_speed,
            y_speed = enemy_type == "shooter" and math.random(20, 50) * (math.random(0, 1) == 0 and 1 or -1) or 0
        },
        Combat = {
            initial_health = health,
            health = health,
            damage = enemy_type == "shooter" and 10 or enemy_type == "diver" and 20 or 15,
            fire_rate = enemy_type == "shooter" and SHOOTER_FIRE_RATES[math.min(spawner.wave, 3)] or 0,
            last_shot = 0
        }
    })
end
function checkCollisions()
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        local bx, by = bullet.x, bullet.y
        if bullet.Projectile.is_enemy then
            if checkCollision(bx, by, player.x + 16, player.y + 16, 8, 32) then
                table.remove(bullets, i)
                if player.Combat.shield > 0 then
                    player.Combat.shield = player.Combat.shield - 1
                else
                    player.Combat.health = math.max(0, player.Combat.health - bullet.Projectile.damage)
                end
            end
        else
            for j = #enemies, 1, -1 do
                local enemy = enemies[j]
                if checkCollision(bx, by, enemy.x + 12, enemy.y + 12, 8, 24) then
                    table.remove(bullets, i)
                    enemy.Combat.health = enemy.Combat.health - bullet.Projectile.damage
                    if enemy.Combat.health <= 0 then
                        createExplosion(enemy.x, enemy.y)
                        spawnPowerups(enemy)
                        if enemy.Movement.type == "shooter" then
                            high_score = high_score + 50
                        elseif enemy.Movement.type == "diver" then
                            high_score = high_score + 20
                        elseif enemy.Movement.type == "targetor" then
                            high_score = high_score + 120
                        end
                        table.remove(enemies, j)
                    end
                    break
                end
            end
        end
    end
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        if checkCollision(enemy.x + 12, enemy.y + 12, player.x + 16, player.y + 16, 24, 32) then
            if player.Combat.shield > 0 then
                player.Combat.shield = player.Combat.shield - 1
            else
                player.Combat.health = math.max(0, player.Combat.health - enemy.Combat.damage)
            end
            createExplosion(enemy.x, enemy.y)
            spawnPowerups(enemy)
            if enemy.Movement.type == "shooter" then
                high_score = high_score + 50
            elseif enemy.Movement.type == "diver" then
                high_score = high_score + 20
            elseif enemy.Movement.type == "targetor" then
                high_score = high_score + 120
            end
            table.remove(enemies, i)
        end
    end
    for i = #powerups, 1, -1 do
        local powerup = powerups[i]
        local px, py = player.x + 16, player.y + 16
        if math.abs(powerup.x + 8 - px) < 24 and math.abs(powerup.y + 8 - py) < 24 then
            if powerup.Powerup.type == "coin" then
                coins = coins + powerup.Powerup.value
            elseif powerup.Powerup.type == "health" then
                player.Combat.health = math.min(100, player.Combat.health + powerup.Powerup.value)
            elseif powerup.Powerup.type == "shield" then
                player.Combat.shield = math.min(3, player.Combat.shield + powerup.Powerup.value)
            end
            table.remove(powerups, i)
        end
    end
    if player.Combat.health <= 0 then
        game_state = "gameover"
    end
end
function checkCollision(x1, y1, x2, y2, size1, size2)
    return math.abs(x1 - x2) < (size1 + size2) / 2 and math.abs(y1 - y2) < (size1 + size2) / 2
end
function spawnPowerups(enemy)
    if math.random() < 0.6 then
        local num_items = enemy.Combat.initial_health >= 100 and 5 or 2
        local powerup_type = enemy.Movement.type == "shooter" and "coin" or enemy.Movement.type == "diver" and "shield" or "health"
        local powerup_value = powerup_type == "coin" and 10 or powerup_type == "health" and 25 or 1
        for i = 1, num_items do
            local powerup = {
                x = enemy.x,
                y = enemy.y,
                Powerup = {type = powerup_type, value = powerup_value}
            }
            if powerup_type == "coin" then
                powerup.angle = math.random() * 2 * math.pi
                powerup.speed = math.random(50, 100)
                powerup.life = 8
            else
                powerup.Movement = {speed = 100}
            end
            table.insert(powerups, powerup)
        end
    end
end
function createExplosion(x, y)
    for i = 1, 20 do
        table.insert(particles, {
            x = x,
            y = y,
            color = {1, 0.5, 0},
            life = 0.8,
            speed = math.random(100, 250),
            angle = math.random() * 2 * math.pi,
            size = math.random(4, 8)
        })
    end
end
function applyWaveScaling()
    if spawner.wave == 3 then
        ENEMY_WEIGHTS = {
            {type="shooter", prob=0.65},
            {type="diver", prob=0.25},
            {type="targetor", prob=0.1}
        }
    end
end
function checkWaveTransition(dt)
    spawner.timer = spawner.timer - dt
    spawner.scaling_timer = spawner.scaling_timer - dt
    if spawner.scaling_timer <= 0 then
        spawner.scaling_timer = 60
    end
    if spawner.timer <= 0 then
        game_state = "upgrade"
        spawner.timer = 30
        spawner.scaling_timer = 60
        high_score = high_score + 150
    end
end
function updateUpgradeState(dt)
    spawner.timer = spawner.timer - dt
    if spawner.timer <= 0 then
        if spawner.wave < 3 then  
            spawner.wave = spawner.wave + 1
        end
        spawner.timer = 120
        game_state = "playing"
        applyWaveScaling()
        clearEnemies()
    end
end
function updateUpgradeFeedback(dt)
    upgrade_feedback.timer = upgrade_feedback.timer - dt
    if upgrade_feedback.timer <= 0 then
        spawner.wave = spawner.wave + 1
        spawner.timer = 120
        spawner.scaling_timer = 60
        game_state = "playing"
        applyWaveScaling()
        clearEnemies()
        upgrade_feedback.timer = 0
        upgrade_feedback.message = ""
    end
end
function updateRespawnFeedback(dt)
    respawn_feedback.timer = respawn_feedback.timer - dt
    if respawn_feedback.timer <= 0 then
        game_state = "playing"
        respawn_feedback.timer = 0
    end
end
function updateRestartFeedback(dt)
    restart_feedback.timer = restart_feedback.timer - dt
    if restart_feedback.timer <= 0 then
        initGame()
        game_state = "playing"
        restart_feedback.timer = 0
    end
end
function clearEnemies()
    for i = #enemies, 1, -1 do
        table.remove(enemies, i)
    end
end
function love.update(dt)
    if game_state == "playing" then
        updatePlayer(dt)
        updateBullets(dt)
        updateEnemies(dt)
        updatePowerups(dt)
        updateParticles(dt)
        updateSpawner(dt)
        checkCollisions()
        checkWaveTransition(dt)
    elseif game_state == "upgrade" then
        updateUpgradeState(dt) 
    elseif game_state == "upgrade_feedback" then
        updateUpgradeFeedback(dt)
    elseif game_state == "respawn_feedback" then
        updateRespawnFeedback(dt)
    elseif game_state == "restart_feedback" then
        updateRestartFeedback(dt)
   
    end
end
function drawGameWorld()
    love.graphics.rectangle("fill", player.x, player.y, 32, 32)
    for _, enemy in ipairs(enemies) do
        love.graphics.setColor(enemy.Movement.type == "shooter" and {1, 0, 0} or enemy.Movement.type == "diver" and {0.5, 0, 0.5} or {1, 0, 1})
        love.graphics.rectangle("fill", enemy.x, enemy.y, 24, 24)
    end
    for _, bullet in ipairs(bullets) do
        love.graphics.setColor(bullet.Projectile.is_enemy and {1, 0.5, 0} or {0, 1, 0})
        love.graphics.rectangle("fill", bullet.x, bullet.y, 8, 8)
    end
    for _, powerup in ipairs(powerups) do
        if powerup.Powerup.type == "coin" then
            love.graphics.setColor(1, 1, 0)
            love.graphics.circle("fill", powerup.x + 8, powerup.y + 8, 8)
        elseif powerup.Powerup.type == "health" then
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle("fill", powerup.x, powerup.y, 16, 8)
        elseif powerup.Powerup.type == "shield" then
            love.graphics.setColor(0, 1, 0)
            love.graphics.rectangle("fill", powerup.x, powerup.y, 16, 16)
        end
    end
    for _, particle in ipairs(particles) do
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], particle.life / 0.8)
        love.graphics.circle("fill", particle.x, particle.y, particle.size)
    end
    love.graphics.setColor(1, 1, 1)
end
function drawHUD()
    love.graphics.print("HEALTH: " .. player.Combat.health, 10, 10)
    love.graphics.print("SHIELD: " .. player.Combat.shield .. "/" .. player.Combat.max_shield, 10, 30)
    love.graphics.print("WAVE: " .. spawner.wave .. "/3", 350, 10)
    love.graphics.print(string.format("TIME: %d:%02d", math.floor(spawner.timer / 60), math.floor(spawner.timer % 60)), 350, 30)
    love.graphics.print(string.format("HI: %05d", high_score), 700, 10)
    love.graphics.print("COINS: " .. coins, 700, 30)
end
function drawGameOver()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("GAME OVER", 300, 300)
    love.graphics.print(string.format("IMPACT %05d", high_score), 300, 320)
    love.graphics.print("[Z] Restart [M] Respawn (20 coins)", 300, 340)
end
function drawUpgradeMenu()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("WAVE " .. spawner.wave .. " COMPLETE", 300, 300)
    love.graphics.print("[UPGRADE - 100 COINS]", 300, 350)
    love.graphics.print("[S] Shield (+1, max "..(player.Combat.max_shield+1)..")", 300, 370)
    love.graphics.print("[D] Damage (+10%)", 300, 390)
    love.graphics.print("[F] Speed (+15%)", 300, 410)
    love.graphics.print("[C] Continue without upgrading", 300, 430)
end
function drawUpgradeFeedback()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1, 1, 1)
    if upgrade_feedback.timer > 3 then
        love.graphics.print("UPGRADE APPLIED!", 300, 300)
    elseif upgrade_feedback.timer > 2 then
        love.graphics.print("STARTING WAVE 3", 300, 300)
    elseif upgrade_feedback.timer > 1 then
        love.graphics.print("STARTING WAVE 2", 300, 300)
    elseif upgrade_feedback.timer > 0 then
        love.graphics.print("STARTING WAVE 1", 300, 300)
    else
        love.graphics.print("READY!", 300, 300)
    end
end
function drawRespawnFeedback()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1, 1, 1)
    if respawn_feedback.timer > 3 then
        love.graphics.print("RESPAWNING IN 3", 300, 300)
    elseif respawn_feedback.timer > 2 then
        love.graphics.print("RESPAWNING IN 2", 300, 300)
    elseif respawn_feedback.timer > 1 then
        love.graphics.print("RESPAWNING IN 1", 300, 300)
    else
        love.graphics.print("READY!", 300, 300)
    end
end
function drawRestartFeedback()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("RESTARTED!!", 300, 300)
end
function love.keypressed(key)
    if game_state == "upgrade" then
        if key == "c" then 
            game_state = "upgrade_feedback"
            upgrade_feedback.timer = 2
            upgrade_feedback.message = "CONTINUING TO NEXT WAVE"
        elseif coins >= 100 then
            handleUpgrade(key)
        end
    elseif game_state == "gameover" then
        if key == "z" then
            game_state = "restart_feedback"
            restart_feedback.timer = 1
        elseif key == "m" and coins >= 20 then
            coins = coins - 20
            player.Combat.health = 80
            player.Combat.shield = math.min(3, player.Combat.shield + 2)
            game_state = "respawn_feedback"
            respawn_feedback.timer = 4
        end
    end
end
function handleUpgrade(key)
    if key == "s" and player.Combat.shield < 3 then
        player.Combat.shield = player.Combat.shield + 1
        player.Combat.max_shield = player.Combat.max_shield + 1 
        coins = coins - 100
        game_state = "upgrade_feedback"
        upgrade_feedback.timer = 4
        upgrade_feedback.message = "SHIELD UPGRADED!"
    elseif key == "d" then
        player.Combat.damage = player.Combat.damage * 1.1
        coins = coins - 100
        game_state = "upgrade_feedback"
        upgrade_feedback.timer = 4
        upgrade_feedback.message = "DAMAGE UPGRADED!"
    elseif key == "f" then
        player.Movement.speed = player.Movement.speed * 1.15
        coins = coins - 100
        game_state = "upgrade_feedback"
        upgrade_feedback.timer = 4
        upgrade_feedback.message = "SPEED UPGRADED!"
    end
end
function love.draw()
    drawGameWorld()
    drawHUD()
    if game_state == "upgrade" then
        drawUpgradeMenu()
    elseif game_state == "gameover" then
        drawGameOver()
    elseif game_state == "upgrade_feedback" then
        drawUpgradeFeedback()
    elseif game_state == "respawn_feedback" then
        drawRespawnFeedback()
    elseif game_state == "restart_feedback" then
        drawRestartFeedback()
    end
end