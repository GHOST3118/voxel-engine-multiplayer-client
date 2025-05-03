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

   for slot = 0, inv_size - 1 do
      local item_id, count = inventory.get(invid, slot)

      if item_id ~= 0 then
         local item_data = inventory.get_all_data(invid, slot)
         table.insert(res_inv, {item_id, count, item_data})
      else
         table.insert(res_inv, 0)
      end
   end

   return res_inv
end

function utils.set_inv(invid, res_inv)
   for i, item in ipairs(res_inv) do
      local slot = i - 1
      if item ~= 0 then
         local item_id, count, item_data = unpack(item)

         inventory.set(invid, slot, item_id, count)

         if item_data then
            for name, value in pairs(item_data) do
               inventory.set_data(invid, slot, name, value)
            end
         end
      else
         inventory.set(invid, slot, 0, 0)
      end
   end
end


 return utils