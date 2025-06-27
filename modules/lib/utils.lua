local utils = {}

function utils.dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. utils.dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

function utils.createNthCallFunction(n, func)
   local counter = 0 -- счётчик вызовов

   return function(...)
       counter = counter + 1
       if counter == n then
           counter = 0 -- сбрасываем счётчик
           return func(...) -- вызываем переданную функцию
       end
   end
end

function utils.get_inv(invid)
   local inv_size = inventory.size(invid)
   local res_inv = {}

   for i = 0, inv_size - 1 do
      res_inv[i] = {id = 0, count = 0}
   end

   for slot = 0, inv_size - 1 do
      local item_id, count = inventory.get(invid, slot)
      local index = slot + 1

      if item_id ~= 0 then
         local item_data = inventory.get_all_data(invid, slot)
         res_inv[index] = {
               id = item_id,
               count = count,
               meta = item_data
            }
      end
   end

   return res_inv
end

function utils.set_inv(invid, res_inv)
   for i, item in ipairs(res_inv) do
      local slot = i - 1

      if item.id ~= 0 then
         inventory.set(invid, slot, item.id, item.count)

         if item.meta then
            for name, value in pairs(item.meta) do
               inventory.set_data(invid, slot, name, value)
            end
         end
      else
         inventory.set(invid, slot, 0, 0)
      end
   end
end

function utils.lerp(cur_pos, target_pos, t)
    t = math.clamp(t, 0, 1)
    local diff = vec3.sub(target_pos, cur_pos)
    local scaledDiff = vec3.mul(diff, t)
    return vec3.add(cur_pos, scaledDiff)
end

local tickers = {}

function utils.get_tick(key)
   return tickers[key]
end

function utils.remove_tick(key)
   tickers[key] = nil
end

function utils.to_tick(func, args, key)
   if not key then
      table.insert(tickers, {func, args})
   else
      tickers[key] = {func, args}
   end
end

function utils.__tick()
   for i, ticker in pairs(tickers) do
      local func = ticker[1]
      local args = ticker[2]

      local res = func(unpack(args))
      if res == nil and type(i) == "number" then
         table.remove(tickers, i)
      elseif res == nil then
         tickers[i] = nil
      else
         ticker[2] = res
      end
   end
end


 return utils