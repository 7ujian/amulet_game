function am.engine()
    local engine = {
        entities = {},
        systems = {}
    }

    engine.add_entity = function (self, entity)
        for i, system in ipairs(self.systems) do
            if (system.match_entity ~= nil and system.match_entity(entity)) then
                table.insert(system.entities, entity)
            end 
        end
    end

    engine.add_system = function (self, key, system)
        self.systems.key = system
    end

    engine.remove_system = function (self, key)
        table.remove(self.systems, key)
    end

    engine.update = function (self)
        for i, system in self.systems do
            if (system.update ~= nil) then
                for i2, entity in system.entities do
                    system.update(entity)    
                end
            end
        end
    end

    return engine
end
