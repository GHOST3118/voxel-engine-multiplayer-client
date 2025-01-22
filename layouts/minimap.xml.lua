-- Параметры карты
local MAP_SIZE = 128  -- Размер области
local PIXEL_SIZE = 2  -- Размер пикселя
local MAX_HEIGHT = 256  -- Максимальная высота в мире Minecraft
local CACHE_LIFETIME = 10
local CHUNK_SIZE = 16 -- Размер чанка
local MAP_SCALE = 1.2

local MINIMAP_WIDTH = 128
local MINIMAP_HEIGHT = 128
local LOCK_ROTATION = false
local PLAYER_MARKER_RADIUS = 4
local PLAYER_MARKER_COLOR = {255, 255, 255, 255}

-- Кэш чанков
local chunk_cache = {}

-- Преобразование из RGB в HSL
local function rgb_to_hsl(r, g, b)
    r = r / 255
    g = g / 255
    b = b / 255

    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, l = 0, 0, (max + min) / 2

    if max == min then
        h = 0
        s = 0
    else
        local delta = max - min
        if max == r then
            h = (g - b) / delta
        elseif max == g then
            h = (b - r) / delta + 2
        else
            h = (r - g) / delta + 4
        end
        s = (l > 0.5) and (delta / (2 - max - min)) or (delta / (max + min))
        h = h * 60
        if h < 0 then
            h = h + 360
        end
    end

    return h, s * 100, l * 100
end


-- Преобразование из HSL в RGB
local function hsl_to_rgb(h, s, l)
    s = s / 100
    l = l / 100

    local c = (1 - math.abs(2 * l - 1)) * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = l - c / 2

    local r, g, b
    if h >= 0 and h < 60 then
        r, g, b = c, x, 0
    elseif h >= 60 and h < 120 then
        r, g, b = x, c, 0
    elseif h >= 120 and h < 180 then
        r, g, b = 0, c, x
    elseif h >= 180 and h < 240 then
        r, g, b = 0, x, c
    elseif h >= 240 and h < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end

    return math.floor((r + m) * 255), math.floor((g + m) * 255), math.floor((b + m) * 255), 255
end


-- Карта цветов блоков с более приятными цветами
local BLOCKS_COLOR_MAP = {
    ["base:dirt"] = {139, 85, 57, 255},  -- Уменьшен контраст для более натурального вида
    ["base:grass_block"] = {60, 179, 113, 255},  -- Сделан цвет травы более насыщенным
    ["base:lamp"] = {255, 248, 220, 255},  -- Немного теплее
    ["base:glass"] = {60, 179, 113, 255},  -- Светло-голубой оттенок
    ["base:planks"] = {153, 101, 21, 255},  -- Теплый цвет дерева
    ["base:wood"] = {101, 67, 33, 255},  -- Оставлен прежний, так как уже выглядит натурально
    ["base:leaves"] = {34, 139, 34, 255},  -- Более теплый зеленый
    ["base:stone"] = {169, 169, 169, 255},  -- Светлый серый
    ["base:water"] = {70, 130, 180, 128},  -- Светлый синий, с прозрачностью
    ["base:sand"] = {255, 239, 153, 255},  -- Песок теплого желтого оттенка
    ["base:bazalt"] = {80, 80, 80, 255},  -- Немного темнее
    ["base:grass"] = {60, 179, 113, 255},  -- Более яркая трава
    ["base:flower"] = {60, 179, 113, 255},  -- Розовый цвет
    ["base:brick"] = {205, 92, 92, 255},  -- Красный кирпич с более мягким оттенком
    ["base:metal"] = {211, 211, 211, 255},  -- Светлый металл
    ["base:rust"] = {183, 65, 14, 255},  -- Оставлен прежний, так как хорошо смотрится
    ["base:red_lamp"] = {255, 99, 71, 255},  -- Теплый красный для лампы
    ["base:green_lamp"] = {0, 255, 127, 255},  -- Лампа зеленая с более мягким оттенком
    ["base:blue_lamp"] = {70, 130, 180, 255},  -- Лампа голубая
    ["base:pane"] = {211, 211, 211, 100},  -- Немного светлее, с прозрачностью
    ["base:pipe"] = {169, 169, 169, 255},  -- Серый оттенок
    ["base:lightbulb"] = {255, 255, 224, 255},  -- Лампочка с мягким желтым
    ["base:torch"] = {255, 140, 0, 255},  -- Оставлен прежний, так как хорошо выглядит
    ["base:wooden_door"] = {139, 69, 19, 255},  -- Классический древесный цвет
    ["base:coal_ore"] = {54, 69, 79, 255},  -- Темный уголь
    ["base:ice"] = {176, 224, 230, 128},  -- Голубой лед
}

-- Простая функция для генерации псевдослучайного шума
local function noise(x, y, seed)
    return math.abs(math.sin(x * 12.9898 + y * 78.233 + seed) * 43758.5453 % 1)
end

local function get_block_color(block_id, y)
    local material = block.name(block_id)
    local color = BLOCKS_COLOR_MAP[material] or {0, 0, 0, 255}
    local h, s, l = rgb_to_hsl(unpack(color))

    -- Уменьшение яркости в зависимости от высоты с большим шагом
    local height_factor = (y / MAX_HEIGHT) * 50  -- Более резкое изменение
    l = l - height_factor
    if l < 0 then
        l = 0
    end

    -- Добавление фактора шума
    local noise_factor = noise(block_id, y, 12345) * 10  -- Шум от -10 до 10
    l = l + noise_factor
    if l > 100 then
        l = 100
    elseif l < 0 then
        l = 0
    end

    -- Обновляем цвет с учетом измененной насыщенности и яркости
    color = {hsl_to_rgb(h, s, l)}

    return color
end






local function draw_square(canvas, x, z, size, color)
    for i = 0, size - 1 do
        for j = 0, size - 1 do
            canvas:set(x + i, z + j, unpack(color))
        end
    end
end

-- Функция для получения самого высокого блока
local function get_highest_block(x, z)
    for y = MAX_HEIGHT - 1, 0, -1 do
        local block_id = block.get(x, y, z)
        if block_id >= 1 then
            return block_id, y
        end
    end
    return 0, 0
end


-- Генерация чанка
local function generate_chunk(chunk_x, chunk_z)
    local chunk = {}
    for dx = 0, CHUNK_SIZE - 1 do
        chunk[dx] = {}
        for dz = 0, CHUNK_SIZE - 1 do
            local x = chunk_x * CHUNK_SIZE + dx
            local z = chunk_z * CHUNK_SIZE + dz
            local block_id, heihgt = get_highest_block(x, z)
            chunk[dx][dz] = get_block_color(block_id, heihgt or 0)
        end
    end
    return chunk
end

-- Функция для проверки актуальности чанка
local function is_chunk_valid(chunk_meta)
    return chunk_meta and (os.time() - chunk_meta.timestamp) < CACHE_LIFETIME
end

-- Функция для получения чанка с ревалидацией
local function get_chunk(chunk_x, chunk_z)
    local key = string.format("%d,%d", chunk_x, chunk_z)
    local chunk_meta = chunk_cache[key]

    -- Проверка актуальности и перегенерация при необходимости
    if not is_chunk_valid(chunk_meta) then
        chunk_cache[key] = {
            data = generate_chunk(chunk_x, chunk_z),
            timestamp = os.time(), -- Обновляем метку времени
        }
    end

    return chunk_cache[key].data
end

local function draw_chunk(canvas, chunk, offset_x, offset_z, cos_rot, sin_rot)
    local chunk_center_x = CHUNK_SIZE / 2
    local chunk_center_z = CHUNK_SIZE / 2

    for dx = 0, CHUNK_SIZE - 1 do
        for dz = 0, CHUNK_SIZE - 1 do
            local color = chunk[dx][dz] or {0, 0, 0, 255}

            -- Смещение пикселя относительно центра чанка
            local rel_x = dx - chunk_center_x
            local rel_z = dz - chunk_center_z

            -- Вращение пикселя относительно центра чанка
            local rotated_x = rel_x * cos_rot - rel_z * sin_rot
            local rotated_z = rel_x * sin_rot + rel_z * cos_rot

            -- Смещение пикселя в итоговые координаты
            local final_x = offset_x + rotated_x * PIXEL_SIZE * MAP_SCALE
            local final_z = offset_z + rotated_z * PIXEL_SIZE * MAP_SCALE

            final_z = MINIMAP_HEIGHT - final_z

            -- Проверка границ и рисование
            if final_x >= 0 and final_x < MINIMAP_WIDTH and final_z >= 0 and final_z < MINIMAP_HEIGHT then
                draw_square(canvas, math.floor(final_x), math.floor(final_z), math.ceil(PIXEL_SIZE * MAP_SCALE), color)
            end
        end
    end
end

local function draw_circle(canvas, center_x, center_y, radius, color)
    for y = -radius, radius do
        for x = -radius, radius do
            -- Проверяем, находится ли точка внутри круга
            if x * x + y * y <= radius * radius then
                -- Рисуем пиксель в координатах относительно центра
                canvas:set(center_x + x, center_y + y, unpack(color))
            end
        end
    end
end


-- Функция для отображения маркера игрока
local function draw_player_marker(canvas, player_x, player_y, marker_radius, marker_color)
    -- Преобразуем координаты игрока в координаты миникарты
    local minimap_x, minimap_y = player_x, player_y -- Пример: без масштабирования
    -- Рисуем круг в качестве маркера игрока
    draw_circle(canvas, minimap_x, minimap_y, marker_radius, marker_color)
end

local function update_minimap(canvas, player_x, player_z, player_rot)
    local half_map = math.floor(MAP_SIZE / 2)
    local center_x = MINIMAP_WIDTH / 2  -- Центр миникарты по X
    local center_z = MINIMAP_HEIGHT / 2  -- Центр миникарты по Z

    local chunk_x = math.floor(player_x / CHUNK_SIZE)
    local chunk_z = math.floor(player_z / CHUNK_SIZE)

    local cos_rot = math.cos(math.rad(player_rot))
    local sin_rot = math.sin(math.rad(player_rot))

    for cx = math.floor(-half_map / CHUNK_SIZE), math.floor(half_map / CHUNK_SIZE) do
        for cz = math.floor(-half_map / CHUNK_SIZE), math.floor(half_map / CHUNK_SIZE) do
            -- Смещение чанка относительно позиции игрока
            local rel_x = (cx * CHUNK_SIZE - player_x % CHUNK_SIZE) * PIXEL_SIZE * MAP_SCALE
            local rel_z = (cz * CHUNK_SIZE - player_z % CHUNK_SIZE) * PIXEL_SIZE * MAP_SCALE

            -- Вращение относительно центра карты
            local rotated_x = rel_x * cos_rot - rel_z * sin_rot
            local rotated_z = rel_x * sin_rot + rel_z * cos_rot

            -- Смещение чанка к центру миникарты
            local offset_x = rotated_x + center_x
            local offset_z = rotated_z + center_z

            -- Получение данных чанка
            local chunk = get_chunk(chunk_x + cx, chunk_z + cz)

            -- Отрисовка чанка
            draw_chunk(canvas, chunk, offset_x, offset_z, cos_rot, sin_rot)
            draw_player_marker(canvas, center_x, center_z, PLAYER_MARKER_RADIUS, PLAYER_MARKER_COLOR)
        end
    end
    canvas:update()
end





-- Основной цикл
function on_open()
    local player_id = hud.get_player()
    MINIMAP_WIDTH = document.minimap_canvas.size[1]
    MINIMAP_HEIGHT = document.minimap_canvas.size[2]

    events.on("minimap:update", function()
        local canvas = document.minimap_canvas.data
        local x, y, z = player.get_pos(player_id)
        local yaw = player.get_rot(player_id, true)
        if LOCK_ROTATION then yaw = 180 end
        
        update_minimap(canvas, x, z, yaw)
    end)
end
