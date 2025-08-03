-- DAN ODIN, 2 AUG, FALLING IN LÖVE WITH SPACE
function love.load()
    math.randomseed(os.time())
    love.window.setTitle("IUF: Space Impact")
    love.window.setMode(800, 600)
    initGame()
end
function initGame()
    player = {
        x = 50,
        y = 300,
        Movement = {
            speed = 200
        },
        Combat = {
            health = 100,
            shield = 1,
            max_shield = 3,
            damage = 10,
            fire_rate = 0.1,
            last_shot = 0
        }
    }
    enemies = {}
    bullets = {}
    powerups = {}
    particles = {}
    spawner = {
        timer = 120, -- WAVE TIME
        wave = 1,
        last_spawn = 0,
        scaling_timer = 60
    }
    boss = {
        x = 340,
        y = -200,
        width = 120,
        height = 120,
        health = 1000,
        max_health = 1000,
        state = "entering",
        timer = 0,
        move_speed = 100,
        move_y = 1,
        fire_cooldown = 0,
        last_direction_change = 0,
        rage_mode = false,
        charging = false,
        retreating = false,
        charge_timer = 0,
        charge_target_x = 0,
        first_defeat = true,
        diver_mode = false,
        diver_target_x = 0,
        diver_target_y = 0,
        diver_returning = false
    }
    ENEMY_WEIGHTS = {{
        type = "shooter",
        prob = 0.6
    }, {
        type = "diver",
        prob = 0.3
    }, {
        type = "targetor",
        prob = 0.1
    }}
    BOSS_ENEMY_WEIGHTS = {{
        type = "shooter",
        prob = 0.54
    }, {
        type = "diver",
        prob = 0.27
    }, {
        type = "targetor",
        prob = 0.09
    }}
    SHOOTER_FIRE_RATES = {1.5, 0.8, 0.75, 0.67, 0.45}
    BOSS_TIMINGS = {
        intro_phases = {2, 1.5, 3},
        fight_duration = 30,
        retreat_cooldown = 30,
        second_attempt_duration = 60,
        health_regen = 5000,
        direction_change_interval = 2,
        charge_cooldown = 5,
        charge_duration = 3,
        retreat_speed = 80,
        normal_fire_rate = 1.5,
        rage_fire_rate = 0.8,
        special_shot_chance = 0.3
    }
    BULLET_TYPES = {
        normal = {
            speed = 200,
            damage = 30,
            size = {15, 8}
        },
        special = {
            speed = 250,
            damage = 5,
            split_count = 10,
            split_angle_spread = math.pi / 2
        }
    }
    game_state = "main_menu"
    coins = 0
    high_score = 0
    boss_intro_timer = 0
    boss_fight_timer = 0
    boss_flee_timer = 0
    victory_timer = 0
    coin_collection_timer = 0
    victory_options_shown = false
    upgrade_feedback = {
        timer = 0,
        message = ""
    }
    respawn_feedback = {
        timer = 0
    }
    restart_feedback = {
        timer = 0
    }
end
function updatePlayer(dt)
    if love.keyboard.isDown("up") then
        player.y = math.max(0, player.y - player.Movement.speed * dt)
    end
    if love.keyboard.isDown("down") then
        player.y = math.min(568, player.y + player.Movement.speed * dt)
    end
    if love.keyboard.isDown("left") then
        player.x = math.max(0, player.x - player.Movement.speed * dt)
    end
    if love.keyboard.isDown("right") then
        player.x = math.min(768, player.x + player.Movement.speed * dt)
    end
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
function createSmallExplosion(x, y)
    for i = 1, 10 do
        table.insert(particles, {
            x = x,
            y = y,
            color = {1, 0.8, 0},
            life = 0.4,
            speed = math.random(50, 150),
            angle = math.random() * 2 * math.pi,
            size = math.random(2, 5)
        })
    end
    -- AUDIO: ANGEL HUNTER EXPLOSION REMINDER
end
function createHitEffect(x, y)
    for i = 1, 5 do
        table.insert(particles, {
            x = x,
            y = y,
            color = {1, 1, 1},
            life = 0.3,
            speed = math.random(50, 100),
            angle = math.random() * 2 * math.pi,
            size = math.random(1, 3)
        })
    end
end
function updateBullets(dt)
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        if bullet.angle then
            bullet.x = bullet.x + math.cos(bullet.angle) * bullet.Projectile.speed * dt
            bullet.y = bullet.y + math.sin(bullet.angle) * bullet.Projectile.speed * dt
        else
            bullet.x = bullet.x + (bullet.Projectile.is_enemy and -bullet.Projectile.speed or bullet.Projectile.speed) *
                           dt
        end
        if bullet.special and math.random() < 0.02 then
            createSmallExplosion(bullet.x, bullet.y)
            local pattern = math.random() < 0.5 and "circular" or "random"
            for j = 1, BULLET_TYPES.special.split_count do
                local angle
                if pattern == "circular" then
                    angle = (j - 1) * (2 * math.pi / BULLET_TYPES.special.split_count)
                else
                    angle = math.random() * 2 * math.pi
                end
                table.insert(bullets, {
                    x = bullet.x,
                    y = bullet.y,
                    Projectile = {
                        speed = BULLET_TYPES.special.speed,
                        damage = BULLET_TYPES.special.damage,
                        is_enemy = true
                    },
                    angle = angle,
                    mini = true
                })
            end
            table.remove(bullets, i)
        elseif bullet.x < -50 or bullet.x > 850 then
            table.remove(bullets, i)
        end
    end
end
function updateEnemies(dt)
    if not enemies then
        enemies = {}
    end
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
    elseif spawner.wave == 3 then
        bullet_speed = bullet_speed * 1.32
    elseif spawner.wave == 4 then
        bullet_speed = bullet_speed * 1.52
    elseif spawner.wave >= 5 then
        bullet_speed = bullet_speed * 1.74
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
            particle.color[2] = particle.color[2] - (particle.color[2] - 0.5) * dt / particle.life
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
    local weights = game_state == "boss_fleeing" and BOSS_ENEMY_WEIGHTS or ENEMY_WEIGHTS
    local r = math.random()
    local cumulative = 0
    local enemy_type = "shooter"
    for _, weight in ipairs(weights) do
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
    elseif spawner.wave == 3 then
        base_speed = base_speed * 1.32
    elseif spawner.wave == 4 then
        base_speed = base_speed * 1.52
    elseif spawner.wave >= 5 then
        base_speed = base_speed * 1.75
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
            fire_rate = enemy_type == "shooter" and SHOOTER_FIRE_RATES[math.min(spawner.wave, 5)] or 0,
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
                createHitEffect(bx, by)
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
                    createHitEffect(bx, by)
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

            if (game_state == "boss_fight" or game_state == "boss_fleeing") and
                checkCollision(bx, by, boss.x + boss.width / 2, boss.y + boss.height / 2, 8,
                    math.min(boss.width, boss.height)) then
                createHitEffect(bx, by)
                table.remove(bullets, i)
                boss.health = boss.health - bullet.Projectile.damage
                -- AUDIO: BOSS HIT REMINDER
                if boss.health <= 0 then
                    boss.state = "defeated"
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
    if game_state == "boss_fight" and
        checkCollision(boss.x + boss.width / 2, boss.y + boss.height / 2, player.x + 16, player.y + 16,
            math.min(boss.width, boss.height), 32) then
        if player.Combat.shield > 0 then
            player.Combat.shield = player.Combat.shield - 1
        else
            player.Combat.health = math.max(0, player.Combat.health - 50)
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
                player.Combat.shield = math.min(player.Combat.max_shield, player.Combat.shield + powerup.Powerup.value)
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
        local powerup_type =
            enemy.Movement.type == "shooter" and "coin" or enemy.Movement.type == "diver" and "shield" or "health"
        local powerup_value = powerup_type == "coin" and 10 or powerup_type == "health" and 25 or 1
        for i = 1, num_items do
            local powerup = {
                x = enemy.x + math.random(-20, 20),
                y = enemy.y + math.random(-20, 20),
                Powerup = {
                    type = powerup_type,
                    value = powerup_value
                }
            }
            if powerup_type == "coin" then
                powerup.angle = math.random() * 2 * math.pi
                powerup.speed = math.random(50, 100)
                powerup.life = 8
            else
                powerup.Movement = {
                    speed = 100
                }
            end
            table.insert(powerups, powerup)
        end
    end
end
function spawnVictoryCoins()
    for i = 1, 100 do
        local value = math.random() < 0.5 and 2 or math.random() < 0.5 and 5 or 10
        table.insert(powerups, {
            x = math.random(0, 800),
            y = math.random(0, 600),
            Powerup = {
                type = "coin",
                value = value
            },
            angle = math.random() * 2 * math.pi,
            speed = math.random(50, 100),
            life = 8
        })
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
function createGiantExplosion(x, y)
    for i = 1, 50 do
        table.insert(particles, {
            x = x + math.random(-60, 60),
            y = y + math.random(-60, 60),
            color = {1, 0.5, 0},
            life = 1.2,
            speed = math.random(150, 300),
            angle = math.random() * 2 * math.pi,
            size = math.random(6, 12)
        })
    end
    -- AUDIO: BOSS DEFEAT REMINDER
end
function applyWaveScaling()
    if spawner.wave == 3 then
        ENEMY_WEIGHTS = {{
            type = "shooter",
            prob = 0.65
        }, {
            type = "diver",
            prob = 0.25
        }, {
            type = "targetor",
            prob = 0.1
        }}
    elseif spawner.wave == 4 then
        ENEMY_WEIGHTS = {{
            type = "shooter",
            prob = 0.7
        }, {
            type = "diver",
            prob = 0.2
        }, {
            type = "targetor",
            prob = 0.1
        }}
    elseif spawner.wave >= 5 then
        ENEMY_WEIGHTS = {{
            type = "shooter",
            prob = 0.75
        }, {
            type = "diver",
            prob = 0.15
        }, {
            type = "targetor",
            prob = 0.1
        }}
    end
end
function checkWaveTransition(dt)
    spawner.timer = spawner.timer - dt
    spawner.scaling_timer = spawner.scaling_timer - dt
    if spawner.scaling_timer <= 0 then
        spawner.scaling_timer = 60
    end
    if spawner.timer <= 0 then
        if spawner.wave >= 5 then
            game_state = "boss_intro"
            boss_intro_timer = 6.5
        else
            game_state = "upgrade"
            spawner.timer = 120
            spawner.scaling_timer = 60
            high_score = high_score + 150
        end
    end
end
function updateBoss(dt)
    boss.timer = boss.timer + dt
    boss.fire_cooldown = boss.fire_cooldown - dt
    if boss.state == "entering" then
        boss.y = boss.y + 100 * dt
        boss.x = boss.x + 150 * dt
        if boss.x >= 680 then
            boss.state = "normal"
            boss.timer = 0
            boss.x = 680
            boss.y = math.max(50, math.min(480, boss.y))
            -- AUDIO: ENTRANCE REMINDER
        end
    elseif boss.state == "normal" or boss.state == "rage" then
        if love.timer.getTime() - boss.last_direction_change > BOSS_TIMINGS.direction_change_interval then
            boss.move_y = math.random() > 0.5 and 1 or -1
            boss.last_direction_change = love.timer.getTime()
        end
        boss.y = boss.y + boss.move_speed * boss.move_y * dt
        if boss.timer > BOSS_TIMINGS.charge_cooldown and not boss.charging then
            boss.charging = true
            boss.charge_timer = 0
            boss.charge_target_x = math.min(player.x - 50, 600)
        end
        if boss.charging then
            boss.charge_timer = boss.charge_timer + dt
            boss.x = boss.x + 200 * dt
            if boss.x >= boss.charge_target_x or boss.charge_timer > BOSS_TIMINGS.charge_duration then
                boss.charging = false
                boss.retreating = true
            end
        elseif boss.retreating then
            boss.x = boss.x - BOSS_TIMINGS.retreat_speed * dt
            if boss.x <= 100 then
                boss.retreating = false
                boss.timer = 0
            end
        end
        if boss.fire_cooldown <= 0 then
            fireBossBullet()
            boss.fire_cooldown = boss.state == "rage" and BOSS_TIMINGS.rage_fire_rate or BOSS_TIMINGS.normal_fire_rate
            -- AUDIO: NORMAL FIRE REMINDER
        end
        if not boss.rage_mode and boss.health <= 500 then
            boss.rage_mode = true
            boss.state = "rage"
            boss.move_speed = 150
            -- AUDIO: RAGE ACTIVATION REMINDER
        end
        if not boss.diver_mode and boss.health <= 200 then
            boss.diver_mode = true
            boss.state = "diver"
            boss.diver_target_x = player.x
            boss.diver_target_y = player.y
            boss.diver_returning = false
            -- AUDIO: DIVER MODE REMINDER
        end
    elseif boss.state == "diver" then
        if not boss.diver_returning then
            local dx = boss.diver_target_x - boss.x
            local dy = boss.diver_target_y - boss.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 1 then
                boss.x = boss.x + (dx / dist) * 250 * dt
                boss.y = boss.y + (dy / dist) * 250 * dt
            end
            if boss.x <= 0 then
                boss.diver_returning = true
                boss.diver_target_x = 680
                boss.diver_target_y = math.random(50, 480)
            end
        else
            local dx = boss.diver_target_x - boss.x
            local dy = boss.diver_target_y - boss.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 1 then
                boss.x = boss.x + (dx / dist) * 400 * dt
                boss.y = boss.y + (dy / dist) * 400 * dt
            else
                boss.diver_returning = false
                boss.diver_target_x = player.x
                boss.diver_target_y = player.y
            end
        end
        if boss.fire_cooldown <= 0 then
            fireBossBullet()
            boss.fire_cooldown = boss.rage_mode and BOSS_TIMINGS.rage_fire_rate or BOSS_TIMINGS.normal_fire_rate
            -- AUDIO: NORMAL FIRE REMINDER
        end
    elseif boss.state == "fleeing" then
        boss.x = boss.x + 200 * dt
        if boss.x > 800 then
            boss.state = "offscreen"
            boss.x = -200
            boss.y = math.random(100, 400)
            if not boss.first_defeat then
                boss.move_speed = boss.move_speed * 1.1
                BOSS_TIMINGS.normal_fire_rate = BOSS_TIMINGS.normal_fire_rate * 0.9
            end
        end
    elseif boss.state == "offscreen" then
        boss_flee_timer = boss_flee_timer - dt
        if boss_flee_timer <= 0 then
            boss.state = "entering"
            boss.x = 340
            boss.y = -200
            game_state = "boss_fight"
            boss_fight_timer = BOSS_TIMINGS.second_attempt_duration
            if boss.first_defeat then
                boss.first_defeat = false
            else
                boss.health = BOSS_TIMINGS.health_regen
            end
            -- AUDIO: ENTRANCE REMINDER
        end
    elseif boss.state == "defeated" then
        createGiantExplosion(boss.x, boss.y)
        spawnVictoryCoins()
        high_score = high_score + (boss.first_defeat and 6878 or 3333)
        game_state = "coin_collection"
        coin_collection_timer = 30
        victory_options_shown = false
    end
    if boss.state == "normal" or boss.state == "rage" or boss.state == "diver" then
        boss.x = math.max(0, math.min(680, boss.x))
        boss.y = math.max(50, math.min(480, boss.y))
    end
end
function fireBossBullet()
    local bullet = {
        x = boss.x,
        y = boss.y + boss.height / 2,
        Projectile = {
            speed = BULLET_TYPES.normal.speed,
            damage = BULLET_TYPES.normal.damage,
            is_enemy = true
        }
    }
    if boss.rage_mode and math.random() < BOSS_TIMINGS.special_shot_chance then
        bullet.special = true
        bullet.Projectile.speed = BULLET_TYPES.special.speed
        bullet.Projectile.damage = BULLET_TYPES.normal.damage
        -- AUDIO: ANGEL HUNTER LAUNCH REMINDER
    end
    table.insert(bullets, bullet)
end
function updateUpgradeState(dt)
    spawner.timer = spawner.timer - dt
    if spawner.timer <= 0 then
        if spawner.wave < 5 then
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
        if spawner.wave < 5 then
            spawner.wave = spawner.wave + 1
        end
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
    if game_state == "main_menu" or game_state == "credits" then
        return
    elseif game_state == "playing" then
        updatePlayer(dt)
        updateBullets(dt)
        updateEnemies(dt)
        updatePowerups(dt)
        updateParticles(dt)
        updateSpawner(dt)
        checkCollisions()
        checkWaveTransition(dt)
    elseif game_state == "boss_intro" then
        boss_intro_timer = boss_intro_timer - dt
        if boss_intro_timer <= 0 then
            game_state = "boss_fight"
            boss_fight_timer = BOSS_TIMINGS.fight_duration
        end
    elseif game_state == "boss_fight" then
        if boss_fight_timer > 0 then
            boss_fight_timer = math.max(0, boss_fight_timer - dt)
        end
        updatePlayer(dt)
        updateBullets(dt)
        updateEnemies(dt)
        updatePowerups(dt)
        updateParticles(dt)
        updateSpawner(dt)
        updateBoss(dt)
        checkCollisions()
        if boss_fight_timer <= 0 and boss.state ~= "defeated" then
            boss.state = "fleeing"
            game_state = "boss_fleeing"
            boss_flee_timer = BOSS_TIMINGS.retreat_cooldown
        end
    elseif game_state == "boss_fleeing" then
        boss_flee_timer = boss_flee_timer - dt
        updatePlayer(dt)
        updateBullets(dt)
        updateEnemies(dt)
        updatePowerups(dt)
        updateParticles(dt)
        updateSpawner(dt)
        checkCollisions()
        updateBoss(dt)
    elseif game_state == "coin_collection" then
        coin_collection_timer = coin_collection_timer - dt
        updatePlayer(dt)
        updatePowerups(dt)
        updateParticles(dt)
        checkCollisions()
        if coin_collection_timer <= 0 then
            game_state = "boss_victory"
            victory_timer = 5
        end
    elseif game_state == "boss_victory" then
        victory_timer = victory_timer - dt
        updatePowerups(dt)
        updateParticles(dt)
        checkCollisions()
        if victory_timer <= 0 then
            victory_options_shown = true
        end
    elseif game_state == "upgrade" then
        updateUpgradeState(dt)
    elseif game_state == "upgrade_feedback" then
        updateUpgradeFeedback(dt)
    elseif game_state == "respawn_feedback" then
        updateRespawnFeedback(dt)
    elseif game_state == "restart_feedback" then
        updateRestartFeedback(dt)
    elseif game_state == "paused" then
        return
    end
end
function drawGameWorld()
    love.graphics.rectangle("fill", player.x, player.y, 32, 32)
    for _, enemy in ipairs(enemies) do
        love.graphics.setColor(enemy.Movement.type == "shooter" and {1, 0, 0} or enemy.Movement.type == "diver" and
                                   {0.5, 0, 0.5} or {1, 0, 1})
        love.graphics.rectangle("fill", enemy.x, enemy.y, 24, 24)
    end
    if game_state == "boss_fight" or game_state == "boss_fleeing" then
        local r, g, b = 0.8, 0.1, 0.1
        if boss.rage_mode then
            r, g, b = 1, 0.5, 0
        end
        if boss.diver_mode then
            r, g, b = 0.5, 0, 0.5
        end
        if boss.charging then
            local pulse = 0.5 + math.sin(love.timer.getTime() * 5) * 0.5
            love.graphics.setColor(r, g * pulse, b * pulse)
        else
            love.graphics.setColor(r, g, b)
        end
        love.graphics.rectangle("fill", boss.x, boss.y, boss.width, boss.height)
    end
    for _, bullet in ipairs(bullets) do
        if bullet.special then
            love.graphics.setColor(1, 0.8, 0)
            love.graphics.circle("fill", bullet.x, bullet.y, 10)
        elseif bullet.mini then
            love.graphics.setColor(1, 0.8, 0)
            love.graphics.circle("fill", bullet.x, bullet.y, 5)
        else
            love.graphics.setColor(bullet.Projectile.is_enemy and {1, 0.2, 0.2} or {0, 1, 0})
            love.graphics.rectangle("fill", bullet.x, bullet.y,
                bullet.Projectile.is_enemy and BULLET_TYPES.normal.size[1] or 8,
                bullet.Projectile.is_enemy and BULLET_TYPES.normal.size[2] or 8)
        end
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
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3],
            particle.life / math.max(0.3, particle.life))
        love.graphics.circle("fill", particle.x, particle.y, particle.size)
    end
    love.graphics.setColor(1, 1, 1)
end
function drawHUD()
    love.graphics.print("HEALTH: " .. player.Combat.health, 10, 10)
    love.graphics.print("SHIELD: " .. player.Combat.shield .. "/" .. player.Combat.max_shield, 10, 30)
    if game_state == "playing" or game_state == "upgrade" then
        love.graphics.print("WAVE: " .. spawner.wave .. "/5", 350, 10)
    elseif game_state == "boss_fight" then
        love.graphics.print("BOSS FIGHT", 350, 10)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("F A L L E N  G A L A X Y: " .. boss.health .. "/" .. boss.max_health, 300, 570)
    elseif game_state == "boss_fleeing" then
        love.graphics.print("BOSS FLEEING", 350, 10)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("F A L L E N  G A L A X Y: " .. boss.health .. "/" .. boss.max_health, 300, 570)
    elseif game_state == "coin_collection" then
        love.graphics.print("COIN COLLECTION", 350, 10)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("F A L L E N  G A L A X Y: DEFEATED", 300, 570)
    end
    love.graphics.print(string.format("TIME: %d:%02d",
        math.floor(
            (game_state == "boss_fight" and boss_fight_timer or game_state == "boss_fleeing" and boss_flee_timer or
                game_state == "coin_collection" and coin_collection_timer or spawner.timer) / 60),
        math.floor(
            (game_state == "boss_fight" and boss_fight_timer or game_state == "boss_fleeing" and boss_flee_timer or
                game_state == "coin_collection" and coin_collection_timer or spawner.timer) % 60)), 350, 30)
    love.graphics.print(string.format("HI: %05d", high_score), 700, 10)
    love.graphics.print("COINS: " .. coins, 700, 30)
end
function drawMainMenu()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("INTO UNKNOWN FIELDS", 300, 260)
    love.graphics.print("<----Space Impact---->", 300, 280)
    love.graphics.print("[P] Play", 300, 320)
    love.graphics.print("[H] High Scores", 300, 350)
    love.graphics.print("[C] Credits", 300, 380)
    love.graphics.print("[Q] Quit", 300, 410)
end
function drawGameOver()
    local respawn_cost = 20 + (spawner.wave - 1) * 30
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("GAME OVER", 300, 300)
    love.graphics.print(string.format("IMPACT %05d", high_score), 300, 320)
    love.graphics.print("[Z] Restart [M] Respawn (" .. respawn_cost .. " coins)", 300, 340)
end
function drawUpgradeMenu()
    local upgrade_cost = 100 + (spawner.wave - 1) * 30
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("WAVE " .. spawner.wave .. " COMPLETE", 300, 300)
    love.graphics.print("[UPGRADE - " .. upgrade_cost .. " COINS]", 300, 350)
    love.graphics.print("[S] Shield (+1, max " .. (player.Combat.max_shield + 1) .. ")", 300, 370)
    love.graphics.print("[D] Damage (+10%)", 300, 390)
    love.graphics.print("[F] Speed (+15%)", 300, 410)
    love.graphics.print("[C] Continue without upgrading", 300, 430)
end
function drawPaused()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("GAME PAUSED", 300, 300)
    love.graphics.print(string.format("CURRENT IMPACT: %05d", high_score), 300, 320)
    love.graphics.print("[R] Resume", 300, 340)
end
function drawBossIntro()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1, 1, 1)
    if boss_intro_timer > 4.5 then
        love.graphics.print("GET READY", 300, 300)
    elseif boss_intro_timer > 3 then
        love.graphics.print("FOR", 300, 300)
    else
        love.graphics.print("THE FALLEN GALAXY", 300, 300)
    end
end
function drawBossVictory()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("VICTORY!! YOU HAVE IMPACTED SPACE AND ERASED THE FALLEN GALAXY", 200, 300)
    if victory_options_shown then
        love.graphics.print("CONTINUE? [Y] Yes [N] No", 300, 340)
    end
end
function drawCredits()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("THANK YOU FOR PLAYING", 300, 280)
    love.graphics.print(string.format("FINAL IMPACT SCORE: %05d", high_score), 300, 300)
    love.graphics.print("CREDITS DEVELOPER DAN ODIN", 300, 320)
    love.graphics.print("RESTART? [Y]Yes [N]No", 300, 340)
end
function drawUpgradeFeedback()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1, 1, 1)
    if upgrade_feedback.timer > 3 then
        love.graphics.print(upgrade_feedback.message, 300, 300)
    elseif upgrade_feedback.timer > 2 then
        love.graphics.print("STARTING NEXT WAVE IN 3 ", 300, 300)
    elseif upgrade_feedback.timer > 1 then
        love.graphics.print("STARTING NEXT WAVE IN 2", 300, 300)
    elseif upgrade_feedback.timer > 0 then
        love.graphics.print("STARTING NEXT WAVE IN 1", 300, 300)
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
    local upgrade_cost = 100 + (spawner.wave - 1) * 30
    local respawn_cost = 20 + (spawner.wave - 1) * 30
    if game_state == "main_menu" then
        if key == "p" then
            initGame()
            game_state = "playing"
        elseif key == "h" then
            game_state = "credits"
        elseif key == "c" then
            game_state = "credits"
        elseif key == "t" then
            initGame()
            spawner.wave = 5
            spawner.timer = 0
            game_state = "playing"
        elseif key == "q" then
            love.event.quit()
        end
    elseif game_state == "playing" and key == "escape" then
        game_state = "paused"
    elseif game_state == "paused" and key == "r" then
        game_state = "playing"
    elseif game_state == "upgrade" then
        if key == "c" then
            game_state = "upgrade_feedback"
            upgrade_feedback.timer = 4
            upgrade_feedback.message = "CONTINUING TO NEXT WAVE"
        elseif coins >= upgrade_cost then
            handleUpgrade(key)
        end
    elseif game_state == "gameover" then
        if key == "z" then
            game_state = "restart_feedback"
            restart_feedback.timer = 1
        elseif key == "m" and coins >= respawn_cost then
            coins = coins - respawn_cost
            player.Combat.health = 80
            player.Combat.shield = math.min(player.Combat.max_shield, player.Combat.shield + 2)
            game_state = "respawn_feedback"
            respawn_feedback.timer = 4
        end
    elseif game_state == "boss_victory" and victory_options_shown then
        if key == "y" then
            spawner.wave = 1
            spawner.timer = 120
            spawner.scaling_timer = 60
            game_state = "playing"
            applyWaveScaling()
            clearEnemies()
            boss = {
                x = 340,
                y = -200,
                width = 120,
                height = 120,
                health = 10000,
                max_health = 10000,
                state = "entering",
                timer = 0,
                move_speed = 100,
                move_y = 1,
                fire_cooldown = 0,
                last_direction_change = 0,
                rage_mode = false,
                charging = false,
                retreating = false,
                charge_timer = 0,
                charge_target_x = 0,
                first_defeat = true,
                diver_mode = false,
                diver_target_x = 0,
                diver_target_y = 0,
                diver_returning = false
            }
        elseif key == "n" then
            game_state = "credits"
        end
    elseif game_state == "credits" then
        if key == "y" then
            initGame()
            game_state = "playing"
        elseif key == "n" then
            game_state = "main_menu"
        end
    end
end
function handleUpgrade(key)
    local upgrade_cost = 100 + (spawner.wave - 1) * 30
    if key == "s" and player.Combat.max_shield < 5 then
        player.Combat.shield = math.min(player.Combat.max_shield + 1, player.Combat.shield + 1)
        player.Combat.max_shield = player.Combat.max_shield + 1
        coins = coins - upgrade_cost
        game_state = "upgrade_feedback"
        upgrade_feedback.timer = 6
        upgrade_feedback.message = "SHIELD UPGRADED!"
    elseif key == "d" then
        player.Combat.damage = player.Combat.damage * 1.1
        coins = coins - upgrade_cost
        game_state = "upgrade_feedback"
        upgrade_feedback.timer = 6
        upgrade_feedback.message = "DAMAGE UPGRADED!"
    elseif key == "f" then
        player.Movement.speed = player.Movement.speed * 1.15
        coins = coins - upgrade_cost
        game_state = "upgrade_feedback"
        upgrade_feedback.timer = 6
        upgrade_feedback.message = "SPEED UPGRADED!"
    end
end
function love.draw()
    if game_state == "main_menu" then
        drawMainMenu()
    elseif game_state == "credits" then
        drawCredits()
    else
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
        elseif game_state == "paused" then
            drawPaused()
        elseif game_state == "boss_intro" then
            drawBossIntro()
        elseif game_state == "boss_victory" then
            drawBossVictory()
        end
    end
end
