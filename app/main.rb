class SkipTick < StandardError; end

def tick(args)
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
  labels << {
    x: 32.from_right,
    y: 62.from_bottom,
    text: "#{$gtk.production ? 'prod' : 'debug'}",
    alignment_enum: 2,
    size_enum: 8,
  }

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
  buttons.each { |b| b[:tick].call(args, b) }
  args.outputs.primitives << buttons.map { |b| b[:render].call(b) }

  args.outputs.labels << labels
  args.outputs.sprites << { x: args.grid.w / 2 - 64, y: 132.from_top, w: 128, h: 128, path: "metadata/icon.png" }
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
