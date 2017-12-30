pico-8 cartridge // http://www.pico-8.com
version 15
__lua__
-- the loop

grid_size = 8

colors = {
  gray = 5,
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

dungeon = {
  o = 0, -- origin
  s = 15 -- size
}

function _init()
  create_tree()
  grow_tree()
  grow_tree()
  make_rooms()
  make_hallways()
  place_player()
end

function _update()
  handle_input()
  move_player()
end

function _draw()
  cls()
  draw_rooms()
  draw_hallways()
  map()
  draw_player()
  print(player.x .. ", " .. player.y, 0, 122, colors.gray)
end

function handle_input()
  if btnp(0) then player.dx = -1 end
  if btnp(1) then player.dx = 1 end
  if btnp(2) then player.dy = -1 end
  if btnp(3) then player.dy = 1 end

  if btnp(4) then
    _init()
  end
end

function place_player()
  local room = get_random_room(tree[1][1])
  player.x = flr(rnd(room.x1 - room.x)) + room.x
  player.y = flr(rnd(room.y1 - room.y)) + room.y
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
  spr(0, player.x * 8, player.y * 8)
  pset(player.x, player.y, colors.yellow)
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

function draw_rooms()
  for i = 0, 16 do
   for j = 0, 16 do
     mset(i, j, 16)
   end
  end
  for room in all(rooms) do
    for i = room.x, room.x1 do
      for j = room.y, room.y1 do
        mset(i, j, 17)
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
              mset(i, y1, 17)
            end
          else -- it is vertical
            if y1 > y2 then
              step = -1
            end
            for i = y1, y2, step do
              mset(x1, i, 17)
            end
          end
        end

        line(h[1][1], h[1][2], h[1][3], h[1][4], colors.pink)
        line(h[2][1], h[2][2], h[2][3], h[2][4], colors.pink)
      end
    end
  end
end

function get_random_point_in_room(room)
  return {flr(rnd(room.x1 - room.x)) + room.x,
          flr(rnd(room.y1 - room.y)) + room.y}
end
__gfx__
aaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a000000aa000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a070070aa070070a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a000000aa000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a077770aa077770a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a007700aa007700a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a000000aa000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000001020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
