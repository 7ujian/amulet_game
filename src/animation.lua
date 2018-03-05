function am.animation(animation_spec)
    local inner = am.group()

    local wrapped = am.wrap(inner)

    local current = 0
    local frame_count = table.getn(animation_spec.frames)

    function wrapped:play()
        print("play animation")
        current = 0

        self:action("play", coroutine.create(function(node)
            while(true) do
                print("step frame")
                current = (current + 1)
                if(current > frame_count) then
                    current = 1
                end

                if (current <= frame_count) then
                    if (inner"sprite" ~= nil) then
                        inner:remove(inner"sprite")
                    end

                    print(current)
                    inner:append(am.sprite(animation_spec.frames[current]))
                end
                am.wait(am.delay(1/animation_spec.framerate))

            end
        end))        
    end

    function wrapped:stop()
        print("stop animation")
        self:cancel("play")
    end

    return wrapped
end