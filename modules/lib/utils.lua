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

 return utils