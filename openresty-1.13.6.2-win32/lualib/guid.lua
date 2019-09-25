--
-- GUID Module v1.0.0
-- Creates what looks to be a GUID.
-- Probably doesn't follow the Spec. 100%, but it's super long, and I didn't have enough time to read it.
-- BUT, it creates unique IDs that look like every GUID I've ever seen.
--

local guid = {};

guid.char = {"A", "B", "C", "D", "E", "F","1","2","3","4","5","6","7","8","9"};
guid.isHyphen = {[9]=1,[14]=1,[19]=1,[24]=1};
guid.used = {};
guid.loops = 0;

math.randomseed(ngx.time());

guid.generate = function()
    guid.currentGuid = nil;
    while(true) do
    guid.loops = guid.loops +1;
    --If we can't get it in 20 tries than we have bigger problems.
    if(guid.loops > 20) then return false; end
    guid.pass = {};
        for z = 1,36 do
            if guid.isHyphen[z] then
                guid.x='-';
            else
                guid.a = math.random(1,#guid.char); -- randomly choose a character from the "guid.char" array
                guid.x = guid.char[guid.a]
            end
                table.insert(guid.pass, guid.x) -- add new index into array.
        end
        z = nil
        guid.currentGuid = tostring(table.concat(guid.pass)); -- concatenate all indicies of the array, then return concatenation.
        if not guid.used[guid.currentGuid] then

            guid.used[guid.currentGuid] = guid.currentGuid;
            return(guid.currentGuid);
        else
            --print('Duplicated a Previously Created GUID.');
        end
    end
end

return guid;