pico-8 cartridge // http://www.pico-8.com
version 15
__lua__
-- the loop

grid_size = 8

colors = {
 pink = 8,
 yellow = 10,
 blue = 12
}

rooms = {}

player = {
 x = 0,
 y = 0,
 dx = 0,
 dy = 0
}

function _init()
 create_rooms(5)
 place_player()
end

function _update()
 handle_input()
 move_player()
end

function _draw()
 cls()
 draw_rooms()
 draw_player()
end

function handle_input()
 if btn(0) then player.dx = -1 end
 if btn(1) then player.dx = 1 end
 if btn(2) then player.dy = -1 end
 if btn(3) then player.dy = 1 end

 if btn(4) then _init() end
end

function place_player()
 local room_number = flr(rnd(#rooms)) + 1
 local room = rooms[room_number]
 player.x = flr(rnd(room.w - 1)) + room.x + 1
 player.y = flr(rnd(room.h - 1)) + room.y + 1
end

function move_player()
 local potential_move = {player.x + player.dx, player.y + player.dy}
 if not is_solid(potential_move) then
  if potential_move[1] > 0 then player.x += player.dx end
  if potential_move[2] > 0 then player.y += player.dy end
 end
 player.dx = 0
 player.dy = 0
end

function is_solid(xy)
 return pget(xy[1], xy[2]) == colors.pink
end

function draw_player()
 pset(player.x, player.y, colors.yellow)
end
-->8
-- map generation
rooms = {}

function create_hallway()

end

function create_rooms(n)
 rooms = {}
 for i=0, n-1 do
  while true do
   -- make a new room
   local room = {
    x = flr(rnd(48)),
    y = flr(rnd(48)),
    w = flr(rnd(12)) + 4,
    h = flr(rnd(12)) + 4
   }
   -- add it and break out if there are no collisions
   local should_create = true
   for r in all(rooms) do
    if room_collision(room, r) then
     -- there's a collision, so break early and try again
     should_create = false
     break
    end
   end
   if should_create then
    add(rooms, room)
    break
   end
  end
 end
end

function a_inside_b(r1, r2)
 return ((r1.x >= r2.x and r1.x <= r2.x+r2.w) or (r1.x+r1.w >= r2.x and r1.x+r1.w <= r2.x+r2.w)) and
        ((r1.y >= r2.y and r1.y <= r2.y+r2.h) or (r1.y+r1.h >= r2.y and r1.y+r1.h <= r2.y+r2.h))
end

function room_collision(r1, r2)
 return a_inside_b(r1, r2) or a_inside_b(r2, r1)
end

function draw_rooms()
 for room in all(rooms) do
  draw_room(room)
 end
end

function draw_room(room)
 for i=room.x, room.x+room.w do
  pset(i, room.y, colors.pink)
  pset(i, room.y+room.h, colors.pink)
 end
 for i=room.y, room.y+room.h do
  pset(room.x, i, colors.pink)
  pset(room.x+room.w, i, colors.pink)
 end
end
__gfx__
aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a070070a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a077770a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a007700a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
