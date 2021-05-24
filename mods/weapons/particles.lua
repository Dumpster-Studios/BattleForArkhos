-- Particles for BfA:
-- Author: Jordach
-- License: Reserved

particulate.register_cubic_particle(
	"weapons:block_debris",
	{
		_effect_timer = 1.5,
		_ttl = 3,
		_ttl_max = 10,
	},
	"bouncing",
	0.35,
	"debris_falling",
	{dist=16, gain=1}
)

particulate.register_cubic_particle(
	"weapons:block_debris_destroyed",
	{
		_effect_timer = 1.5,
		_ttl = 3,
		_ttl_max = 10,
	},
	"bouncing_alt",
	0.35,
	"debris_falling",
	{dist=16, gain=1}
)

particulate.register_cubic_particle(
	"weapons:smoke_particle",
	{
		_ttl = 6,
		_ttl_max = 12,
	},
	"smoke",
	1,
	"smoke",
	{dist=16, gain=1}
)

function weapons.spray_particles(pointed, nodedef, target_pos, node_destroyed)
	local destroyed = false
	if node_destroyed == nil then
	else
		destroyed = node_destroyed
	end

	local npos, npos_floor
	if pointed == nil then
		npos = table.copy(target_pos)
		npos_floor = table.copy(target_pos)
		npos_floor.x = math.floor(npos_floor.x)
		npos_floor.y = math.floor(npos_floor.y)
		npos_floor.z = math.floor(npos_floor.z)
	else
		npos = table.copy(pointed.intersection_point)
		npos_floor = table.copy(pointed.under)
	end
	
	if nodedef.tiles == nil then return end
	if nodedef._no_particles ~= nil then return end

	local tex = {}
	for ind, png in pairs(nodedef.tiles) do
		local txtr
		if destroyed then
			txtr = nodedef.tiles[ind]
		else
			txtr = weapons.create_2x2_node_texture(nodedef.tiles[ind])
		end
		tex[ind] = txtr
		if ind == #nodedef.tiles then
			local fill_val = ind
			repeat
				fill_val = fill_val + 1
				tex[fill_val] = txtr
			until #tex == 6
		end
	end

	local name = "weapons:block_debris"
	local size_min, size_max = 0.95, 1.55
	local vel_min, vel_max = -1.5, 1.5
	local del_min, del_max = 2.5, 3.75
	local nparticles = math.random(2, 3)
	local pnt = nil

	if destroyed then
		size_min = 9
		size_max = 9.5
		vel_min = -0.5
		vel_max = 0.5
		del_min = 1.75
		del_max = 2.5
		nparticles = 1
		name = name .. "_destroyed"
	else
		pnt = pointed
	end

	particulate.spawn_particles(name, nparticles,
		{
			pos = table.copy(npos),
			size_min = size_min,
			size_max = size_max,
			vel_min = vel_min,
			vel_max = vel_max,
			del_min = del_min,
			del_max = del_max,
		},
		pnt,
		tex,
		destroyed
	)
end