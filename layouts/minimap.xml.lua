-- Функция определения цвета на основе материала блока
local function get_material_color(material)
    local colors = {
        ["base:grass"] = {r = 34, g = 139, b = 34, a = 255}, -- Зелёный для травы
        ["base:water"] = {r = 30, g = 144, b = 255, a = 255}, -- Синий для воды
        ["base:stone"] = {r = 128, g = 128, b = 128, a = 255}, -- Серый для камня
        ["base:sand"] = {r = 210, g = 180, b = 140, a = 255}, -- Бежевый для песка
        ["default"] = {r = 0, g = 0, b = 0, a = 255} -- Чёрный для неизвестных материалов
    }
    
    return colors[material] or colors["default"]
end

-- Функция отрисовки миникарты
local function draw_minimap(data, center_x, center_y, center_z, radius)
    local size = radius * 2 + 1 -- Размер области, которая будет отображаться на миникарте
    
    -- Перебор всех блоков в указанной области
    for x = -radius, radius do
        for z = -radius, radius do
            local world_x = center_x + x
            local world_z = center_z + z
            local block_id = block.get(world_x, center_y, world_z) -- Получаем ID блока
            
            if block_id ~= -1 then -- Если блок существует
                local material = block.material(block_id) -- Материал блока
                local color = get_material_color(material) -- Определяем цвет пикселя
                
                -- Вычисляем координаты пикселя на холсте
                local canvas_x = (x + radius)
                local canvas_y = (z + radius)
                
                -- Закрашиваем пиксель на холсте
                data:set(canvas_x, canvas_y, color.r, color.g, color.b, color.a)
            end
        end
    end

    data:update() -- Обновляем холст для отображения изменений
end




--- Запускает процесс отрисовки миникарты с использованием корутины
-- @param canvas объект холста
-- @param startX, startY начальные координаты карты
-- @param width, height размеры карты
-- @param scale масштаб отображения карты
-- @param get_color функция получения цвета для каждого пикселя
-- local function draw_minimap(data, startX, startY, width, height, scale, get_color)
--     local co = coroutine.create(minimap_generator)

--     local function step()
--         local status, err = coroutine.resume(co, data, startX, startY, width, height, scale, get_color)
--         if not status then
--             if err then
--                 error(err)
--             end
--             return false  -- Завершение корутины
--         end
--         return coroutine.status(co) ~= "dead"
--     end

--     -- Возвращаем функцию, которую можно вызывать в цикле обновления
--     return step
-- end

function on_open()
    local data = document["minimap_canvas"].data
    
    draw_minimap( data, 0, 0, 1, 16 )

    events.on("minimap:update", function ()
        
        
    end)
end
