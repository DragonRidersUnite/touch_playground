class SkipTick < StandardError; end

def tick(args)
  # comment/uncomment this out for remote server access on device
  args.gtk.start_server! port: 9001, enable_in_prod: true
  args.state.scene ||= :menu
  send("tick_scene_#{args.state.scene}", args)
  args.outputs.background_color = [250, 250, 250]
rescue SkipTick
end


def switch_scene(args, scene)
  args.state.scene = scene
  raise SkipTick.new
end

def title(args, text, y: 32)
  {
    x: args.grid.w / 2,
    y: y.from_top,
    text: text,
    size_enum: 16,
    alignment_enum: 1,
  }
end

def tick_scene_menu(args)
  labels = []
  labels << title(args, "DragonRuby Touch Playground", y: 128)

  buttons = []
  buttons << button(
    x: 20.from_left, y: 240.from_top, w: 200, h: 80,
    key: :swipe_tester, title: "Swipe Tester",
    on_click: -> (args) { switch_scene(args, :swipe_tester) }
  )
  buttons << button(
    x: 260.from_left, y: 240.from_top, w: 200, h: 80,
    key: :drag, title: "Drag",
    on_click: -> (args) { switch_scene(args, :drag)}
  )
  buttons << button(
    x: 500.from_left, y: 240.from_top, w: 200, h: 80,
    key: :vpad, title: "VPad",
    on_click: -> (args) { switch_scene(args, :vpad)}
  )
  buttons << button(
    x: 20.from_left, y: 360.from_top, w: 200, h: 80,
    key: :multi, title: "Multi-Touch",
    on_click: -> (args) { switch_scene(args, :multi_touch)}
  )
  buttons << button(
    x: 260.from_left, y: 360.from_top, w: 200, h: 80,
    key: :waypoint, title: "Waypoint",
    on_click: -> (args) { switch_scene(args, :waypoint)}
  )
  buttons.each { |b| b[:tick].call(args, b) }
  args.outputs.primitives << buttons.map { |b| b[:render].call(b) }

  args.outputs.labels << labels
  args.outputs.sprites << { x: args.grid.w / 2 - 64, y: 132.from_top, w: 128, h: 128, path: "metadata/icon.png" }
end

def tick_scene_multi_touch(args)
  labels = []
  labels << title(args, "Multi-Touch")
  args.outputs.labels << labels

  args.state.rects ||= []

  args.inputs.touch.each do |k, v|
    rect = args.state.rects.find { |r| args.geometry.inside_rect?({w: 1, h: 1 }.merge({ x: v.x, y: v.y}), r) }
    if rect
      rect.w += 2
      rect.h += 2
      rect.x -= 1
      rect.y -= 1
    else
      args.state.rects << {
        x: v.x - 2,
        y: v.y - 2,
        w: 4,
        h: 4,
        r: rand(155) + 100,
        g: rand(155) + 100,
        b: rand(155) + 100,
      }
    end
  end

  buttons = []
  buttons << button(
    x: 20.from_left, y: 120.from_bottom, w: 200, h: 60,
    key: :reset_swipes, title: "Reset Rects",
    on_click: -> (args) { args.state.rects.clear }
  )
  buttons.each { |b| b[:tick].call(args, b) }

  args.outputs.primitives << buttons.map { |b| b[:render].call(b) }
  args.outputs.solids << args.state.rects
  tick_back_button(args)
end

def tick_scene_waypoint(args)
  labels = []
  labels << title(args, "Waypoint")
  args.outputs.labels << labels

  args.state.waypoints ||= []

  args.state.unit ||= {
    x: 300,
    y: 400,
    w: 60,
    h: 60,
    angle: 0,
    path: "sprites/circle.png",
  }

  if args.inputs.mouse.click
    args.state.waypoints << {
      x: args.inputs.mouse.x - 18,
      y: args.inputs.mouse.y - 18,
      w: 36,
      h: 36,
      r: 100,
      g: 100,
      b: 200,
      a: 50,
    }
  end

  next_waypoint = args.state.waypoints.first
  if next_waypoint
    next_waypoint.a = Math.sin(args.state.tick_count / 4) * 100 + 150

    args.state.unit.angle = opposite_angle(args.geometry.angle_from(args.state.unit, next_waypoint))
    x_vel, y_vel = vel_from_angle(args.state.unit.angle, 6)
    args.state.unit.x += x_vel
    args.state.unit.y += y_vel

    args.outputs.lines << {
      x: args.state.unit.x + 30, y: args.state.unit.y + 30,
      x2: next_waypoint.x + 18, y2: next_waypoint.y + 18,
    }

    if args.geometry.intersect_rect?(next_waypoint, args.state.unit)
      args.state.waypoints = args.state.waypoints.drop(1)
    end
  end

  args.state.waypoints.each.with_index do |w, i|
    unless i == args.state.waypoints.length - 1
      nw = args.state.waypoints[i + 1]
      args.outputs.lines << {
        x: w.x + 18, y: w.y + 18,
        x2: nw.x + 18, y2: nw.y + 18,
        a: 150,
      }
    end
  end

  args.outputs.sprites << args.state.unit
  args.outputs.solids << args.state.waypoints
  tick_back_button(args)
end

# +angle+ is expected to be in degrees with 0 being facing right
def vel_from_angle(angle, speed)
  [speed * Math.cos(deg_to_rad(angle)), speed * Math.sin(deg_to_rad(angle))]
end

# returns diametrically opposed angle
# uses degrees
def opposite_angle(angle)
  add_to_angle(angle, 180)
end

# returns a new angle from the og `angle` one summed with the `diff`
# degrees! of course
def add_to_angle(angle, diff)
  ((angle + diff) % 360).abs
end

def deg_to_rad(deg)
  (deg * Math::PI / 180).round(4)
end

def tick_scene_vpad(args)
  labels = []
  solids = []
  lines = []
  labels << title(args, "VPad")
  args.outputs.labels << labels
  tick_back_button(args)

  args.state.dragon ||= {
    x: 300,
    y: 400,
    w: 120,
    h: 120,
    angle: 0,
    path: "sprites/dragon.png",
  }
  dragon = args.state.dragon

  args.state.vstick ||= {
    x: 100,
    y: 100,
    w: 120,
    h: 120,
    path: "sprites/circle.png",
    active: false,
    left: false,
    right: false,
    down: false,
    up: false,
  }
  vstick = args.state.vstick

  args.state.button_a ||= {
    x: 200.from_right,
    y: 100,
    w: 100,
    h: 100,
    path: "sprites/button_a.png",
  }
  button_a = args.state.button_a

  if args.inputs.mouse.down && args.inputs.mouse.inside_rect?(vstick)
    vstick.active = true
  end

  if args.inputs.touch.values.any? { |t| t.inside_rect?(button_a) } ||
    args.inputs.mouse.down && args.inputs.mouse.inside_rect?(button_a)
    dragon.angle += 45
    button_a.merge!(a: 125)
  else
    button_a.merge!(a: 255)
  end

  if args.inputs.mouse.up
    vstick.active = false
    vstick.up = vstick.down = vstick.left = vstick.right = false
  end

  if vstick.active
    mouse_pos = [args.inputs.mouse.x, args.inputs.mouse.y]
    vstick_pos = [vstick.x + vstick.w / 2, vstick.y + vstick.h / 2]
    dist = args.geometry.distance(vstick_pos, mouse_pos)

    if dist > 10 # min distance threshold
      angle = args.geometry.angle_from(vstick_pos, mouse_pos)
      vstick.angle = angle + 180

      vstick.up = vstick.down = vstick.left = vstick.right = false
      if angle > 285 || angle < 5
        vstick.left = true
      elsif angle > 110 && angle < 250
        vstick.right = true
      end
      if angle >= 10 && angle <= 160
        vstick.down = true
      elsif angle >= 210 && angle <= 330
        vstick.up = true
      end

      solids << { x: mouse_pos[0] - 12, y: mouse_pos[1] - 12, w: 24, h: 24, r: 240, g: 40, b: 40 }
      lines << vstick_pos.concat(mouse_pos)
    end
  end

  speed = 8
  if args.state.vstick.up || args.inputs.up
    dragon.y += speed
  elsif args.state.vstick.down || args.inputs.down
    dragon.y -= speed
  end
  if args.state.vstick.left || args.inputs.left
    dragon.x -= speed
  elsif args.state.vstick.right || args.inputs.right
    dragon.x += speed
  end

  args.outputs.sprites << [args.state.dragon, vstick, button_a]
  args.outputs.solids << solids
  args.outputs.labels << labels
end

def tick_scene_drag(args)
  args.state.rect ||= {
    x: 200,
    y: 200,
    w: 120,
    h: 120,
    r: 100,
    g: 100,
    b: 250,
    dragging: false,
  }
  args.state.dragging ||= false

  labels = []
  labels << title(args, "Drag")

  solids = []
  solids << args.state.rect

  if args.inputs.mouse.down && args.inputs.mouse.inside_rect?(args.state.rect)
    args.state.rect.dragging = true
    args.state.rect.b = 150
  elsif args.inputs.mouse.up
    args.state.rect.dragging = false
    args.state.rect.b = 250
  end

  if args.state.rect.dragging
    args.state.rect.x = args.inputs.mouse.x - args.state.rect.w / 2
    args.state.rect.y = args.inputs.mouse.y - args.state.rect.h / 2
  end

  args.outputs.solids << solids
  args.outputs.labels << labels
  tick_back_button(args)
end

def tick_back_button(args)
  buttons = []
  buttons << button(
    x: 20.from_left, y: 20.from_top, w: 120, h: 60,
    key: :back, title: "Back",
    on_click: -> (args) { switch_scene(args, :menu) }
  )
  buttons.each { |b| b[:tick].call(args, b) }
  args.outputs.primitives << buttons.map { |b| b[:render].call(b) }
end

def button(x:, y:, w:, h:, key:, title:, desc: nil, on_click:)
  butt = {
    key: key,
    title: {
      x: x + w / 2,
      y: y - h / 3,
      text: title,
      size_enum: 2,
      alignment_enum: 1,
    }.label!,
    bg: {
      x: x,
      y: y - h,
      w: w,
      h: h,
      a: 0,
      r: 20,
      b: 200,
      g: 20,
    }.solid!,
    border: {
      x: x,
      y: y - h,
      w: w,
      h: h,
    }.border!,
  }

  if desc
    butt[:desc] = desc.split("\n").map.with_index do |d, i|
      {
        x: x + 20,
        y: y - 60 - i * 20,
        text: d,
        size_enum: 0,
      }.label!
    end
  end

  butt[:on_click] = on_click
  butt[:render] = -> (b) { b.slice(:bg, :border, :title, :desc).values }
  butt[:tick] = -> (args, butt) do
    if args.inputs.mouse.position.inside_rect?(butt[:border])
      if args.inputs.mouse.click
        butt.on_click.call(args)
      end
    end
  end

  butt
end

def tick_scene_swipe_tester(args)
  args.state.swipes ||= []

  if args.inputs.mouse.click
    args.state.swipes << {
      start_tick: args.state.tick_count,
      start_x: args.inputs.mouse.x,
      start_y: args.inputs.mouse.y,
    }
  end

  if args.inputs.mouse.up
    swipe = args.state.swipes.last
    if swipe
      swipe.merge!({
        stop_x: args.inputs.mouse.x,
        stop_y: args.inputs.mouse.y,
      })

      p1 = [swipe.start_x, swipe.start_y]
      p2 = [swipe.stop_x, swipe.stop_y]
      dist = args.geometry.distance(p1, p2)

      if dist > 50 # min distance threshold
        angle = args.geometry.angle_from(p1, p2)
        swipe.angle = angle
        swipe.dist = dist

        if angle > 315 || swipe.angle < 45
          swipe.direction = :left
        elsif angle >= 45 && angle <= 135
          swipe.direction = :down
        elsif angle > 135 && angle < 225
          swipe.direction = :right
        elsif angle >= 225 && angle <= 315
          swipe.direction = :up
        end
      else
        args.state.swipes.delete(swipe)
      end
    end
  end

  labels = []
  lines = []
  solids = []

  labels << title(args, "Swipe Tester")

  args.state.swipes.each do |s|
    solids << { x: s.start_x - 72 / 2, y: s.start_y - 72 / 2, w: 72, h: 72, r: 40, g: 240, b: 40 }
    if s.stop_x
      solids << { x: s.stop_x - 42 / 2, y: s.stop_y - 42 / 2, w: 42, h: 42, r: 240, g: 40, b: 40 }
      lines << { x: s.start_x, y: s.start_y, x2: s.stop_x, y2: s.stop_y }
      labels << { x: s.start_x, y: s.start_y, text: "dir: #{s.direction}" }
      labels << { x: s.start_x, y: s.start_y - 20, text: "dist: #{s.dist}" }
      labels << { x: s.start_x, y: s.start_y - 40, text: "angle: #{s.angle}" }
    end
  end

  buttons = []
  buttons << button(
    x: 20.from_left, y: 120.from_bottom, w: 200, h: 60,
    key: :reset_swipes, title: "Reset Swipes",
    on_click: -> (args) { args.state.swipes.clear }
  )
  buttons.each { |b| b[:tick].call(args, b) }

  args.outputs.primitives << buttons.map { |b| b[:render].call(b) }
  args.outputs.solids << solids
  args.outputs.lines << lines
  args.outputs.labels << labels

  tick_back_button(args)
end
