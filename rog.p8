pico-8 cartridge // http://www.pico-8.com
version 15
__lua__
-- the loop

grid_size = 8

colors = {
  gray = 5,
  pink = 8,
  yellow = 10,
  blue = 12,
  bluegray = 13
}

rooms = {}

player = {
  x = 0,
  y = 0,
  dx = 0,
  dy = 0,
  t = 0,
  max_t = 30,
  dir = 1, -- 0=left 1=right 2=up 3=down
  sprite = 1
}

dungeon = {
  o = 0, -- origin
  s = 48 -- size
}

cam = {
  x = 0,
  y = 0
}

function _init()
  create_tree()
  grow_tree()
  grow_tree()
  grow_tree()
  make_rooms()
  make_hallways()
  place_buddies()
  place_actor(player)
end

function _update()
  handle_input()
  move_player()
  cam.x = (player.x - 7) * 8
  cam.y = (player.y - 7) * 8
end

function _draw()
  cls()
  camera(cam.x, cam.y)
  draw_rooms()
  draw_hallways()
  map(0, 0, 0, 0, dungeon.s, dungeon.s)
  draw_buddies()
  draw_player()
  map(0, 0, 0, 0, dungeon.s, dungeon.s, 4)
  camera()
  draw_minimap()
end

function draw_minimap()
  --hallways
  for h in all(hallway_points) do
    pset(h[1], h[2], colors.bluegray)
  end
  --rooms
  for node in all(tree[#tree]) do
    for i=0, node.room.x1 - node.room.x do
      for j=0, node.room.y1 - node.room.y do
        pset(node.room.x + i, node.room.y + j, colors.bluegray)
      end
    end
  end
  -- player
  pset(player.x, player.y, colors.yellow)
end

function handle_input()
  if btnp(0) then
    player.dx = -1
    player.dir = 0
  elseif btnp(1) then
    player.dx = 1
    player.dir = 1
  elseif btnp(2) then
    player.dy = -1
    player.dir = 2
  elseif btnp(3) then
    player.dy = 1
    player.dir = 3
  elseif btnp(4) then _init()
  else
    -- no button pressed
    return
  end
  move_buddies()
end

function place_actor(obj)
  local room = get_random_room(tree[1][1])
  obj.x = flr(rnd(room.x1 - room.x)) + flr(room.x)
  obj.y = flr(rnd(room.y1 - room.y)) + flr(room.y)
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
  local sprite = mget(xy[1], xy[2])
  if sprite == 0 then return true end
  if fget(sprite, 0) then return true end
  return not fget(sprite, 1)
end

function draw_player()
  if player.t == player.max_t then
    player.t = 0
  end

  if player.t < player.max_t / 2 then
    if player.dir == 3 then
      player.sprite = 5
    elseif player.dir == 2 then
      player.sprite = 3
    else
      player.sprite = 1
    end
  else
    if player.dir == 3 then
      player.sprite = 6
    elseif player.dir == 2 then
      player.sprite = 4
    else
      player.sprite = 2
    end
  end

  player.t += 1

  --mset(player.x, player.y, player.sprite)
  spr(player.sprite, player.x * 8, player.y * 8, 1, 1, player.dir == 0)
end

function make_buddy(x, y, speed, sprite)
  b = {}
  b.x = x
  b.y = y
  b.speed = speed
  b.sprite = sprite
  b.t = 0
  b.max_t = 30
  return b
end

function place_buddies()
  buddies = {}
  for i=1, 10 do
    local buddy = make_buddy(0, 0, 1, 32)
    add(buddies, buddy)
    place_actor(buddy)
  end
end

function move_buddies()
  for b in all(buddies) do
    local clear_spaces = {{b.x, b.y}}
    for x in all({-1, 1}) do
      if not is_solid({b.x + 1, b.y}) then
        add(clear_spaces, {b.x + 1, b.y})
      end
    end
    for y in all({-1, 1}) do
      if not is_solid({b.x, b.y + y}) then
        add(clear_spaces, {b.x, b.y + y})
      end
    end

    -- pick a random dir to go
    local move = clear_spaces[flr(rnd(#clear_spaces)) + 1]
    b.x = move[1]
    b.y = move[2]
  end
end

function draw_buddies()
  for b in all(buddies) do
    if b.t == b.max_t then
      b.t = 0
    end

    if b.t < b.max_t / 2 then
      b.sprite = 32
    else
      b.sprite = 33
    end

    b.t += 1
    mset(b.x, b.y, b.sprite)
  end
end
-->8
-- map generation
rooms = {}

function create_tree()
  tree = {}
  nodes = {}
  local root = {
    x = dungeon.o,
    y = dungeon.o,
    w = dungeon.s,
    h = dungeon.s,
    parent = "nil"
  }
  add(tree, {root})
  add(nodes, root)
end

function grow_tree()
  local leaves = tree[#tree]
  add(tree, {})
  for node in all(leaves) do
    split_node(node)
  end
end

function split_node(node)
  n1 = {parent = node, children = {}, room = nil}
  n2 = {parent = node, children = {}, room = nil}
  local dir = flr(rnd(2))
  local limiter = 3
  if dir == 0 then -- horizontal split
    local upper_bound = flr(n1.parent.h - (n1.parent.h / limiter))
    local lower_bound = flr(n1.parent.h / limiter)
    n1.x = n1.parent.x
    n1.y = n1.parent.y
    n1.w = n1.parent.w
    n1.h = flr(rnd(upper_bound - lower_bound)) + lower_bound
    n2.x = n2.parent.x
    n2.y = n2.parent.y + n1.h
    n2.w = n2.parent.w
    n2.h = n2.parent.h - n1.h
  else -- vertical split
    local upper_bound = n1.parent.w - (n1.parent.w / limiter)
    local lower_bound = n1.parent.w / limiter
    n1.x = n1.parent.x
    n1.y = n1.parent.y
    n1.w = flr(rnd(upper_bound - lower_bound)) + lower_bound
    n1.h = n1.parent.h
    n2.x = n2.parent.x + n1.w
    n2.y = n1.y
    n2.w = n2.parent.w - n1.w
    n2.h = n2.parent.h
  end
  node.children = {n1, n2}
  add(tree[#tree], n1)
  add(tree[#tree], n2)
  add(nodes, n1)
  add(nodes, n2)
end

function get_random_room(node)
  if node.room != nil then
    return node.room
  end
  local rand = flr(rnd(2)) + 1
  return get_random_room(node.children[rand])
end

function make_rooms()
  rooms = {}
  local leaves = tree[#tree]
  for node in all(leaves) do
    local room = { c = colors.gray }

    local xmin = node.x + 1
    local xmax = node.x + node.w - flr(node.w / 2)
    if node.w < 4 then xmax = xmin end
    room.x = flr(rnd(xmax - xmin)) + xmin

    local ymin = node.y + 1
    local ymax = node.y + node.h - flr(node.h / 2)
    if node.h < 4 then ymax = ymin end
    room.y = flr(rnd(ymax - ymin)) + ymin

    local x1min = room.x + 1
    local x1max = node.x + node.w - 1
    if node.w < 4 then x1max = x1min end
    room.x1 = flr(rnd(x1max - x1min)) + x1min

    local y1min = room.y + 1
    local y1max = node.y + node.h - 1
    if node.h < 4 then y1max = y1min end
    room.y1 = flr(rnd(y1max - y1min)) + y1min

    node.room = room
    add(rooms, room)
  end
end

function draw_trasparent_map()
  for i = 0, dungeon.s do
   for j = 0, dungeon.s do
     mset(i, j, 0)
   end
  end
end

function draw_rooms()
  for i = 0, dungeon.s do
   for j = 0, dungeon.s do
     mset(i, j, 16)
   end
  end
  for room in all(rooms) do
    for i = room.x, room.x1 do
      for j = room.y, room.y1 do
        mset(i, j, 17)
        pset(i, j, colors.pink)
      end
    end
    rectfill(room.x, room.y, room.x1, room.y1, colors.pink)
  end
end

function make_hallways()
  for i = #tree - 1, 1, -1 do
    for node in all(tree[i]) do
      node.hallways = {}

      -- get the two nodes to connect
      local node1 = node.children[1]
      local node2 = node.children[2]

      local exits = flr(rnd(2)) + 1

      for i = 1, exits do
        local room1 = get_random_room(node1)
        local room2 = get_random_room(node2)

        local room1_location = get_random_point_in_room(room1)
        local room2_location = get_random_point_in_room(room2)

        -- save the hallway on the node
        if flr(rnd(2)) + 1 then -- go horizontal or vertical first
          add(node.hallways, {{room1_location[1], room1_location[2], room2_location[1], room1_location[2], true},
                             {room2_location[1], room1_location[2], room2_location[1], room2_location[2], false}})
        else
          add(node.hallways, {{room1_location[1], room1_location[2], room1_location[1], room2_location[2], false},
                             {room1_location[1], room2_location[2], room2_location[1], room2_location[2], true}})
        end
      end
      -- get a random room from each node
    end
  end
end

function draw_hallways()
  hallway_points = {}
  for node in all(nodes) do
    local hallways = node.hallways
    if hallways != nil then
      for h in all(hallways) do
        for l in all(h) do
          local step = 1
          local x1 = l[1]
          local y1 = l[2]
          local x2 = l[3]
          local y2 = l[4]
          local is_horizontal = l[5]

          if is_horizontal then
            if x1 > x2 then
              step = -1
            end
            for i = x1, x2, step do
              add(hallway_points, {i, y1})
            end
          else -- it is vertical
            if y1 > y2 then
              step = -1
            end
            for i = y1, y2, step do
              add(hallway_points, {x1, i})
            end
          end
        end
      end
    end
  end

  for h in all(hallway_points) do
    mset(h[1], h[2], 17)
  end
end

function get_random_point_in_room(room)
  return {flr(rnd(room.x1 - room.x)) + room.x,
          flr(rnd(room.y1 - room.y)) + room.y}
end
__gfx__
aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a000000a000990000000000000099000000000000009900000000000000000000000000000000000000000000000000000000000000000000000000000000000
a070070a009999000009900000999900000990000099990000099000000000000000000000000000000000000000000000000000000000000000000000000000
a000000a009040000099990000999900009999000004400000999900000000000000000000000000000000000000000000000000000000000000000000000000
a077770a009444000090400000999900009999000044440000044000000000000000000000000000000000000000000000000000000000000000000000000000
a007700a009111000094440000199100009999000011110000444400000000000000000000000000000000000000000000000000000000000000000000000000
a000000a001001000091100000100100001991000010010000199100000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaa002222000022220000222200002222000022220000222200000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c7cc7c000cccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cccccc00c7cc7c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cc77cc00cccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cc77cc00cc77cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cccccc00cccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c0000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0005050000000000000000000000000001020000000000000000000000000000040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
