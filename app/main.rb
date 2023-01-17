def tick(args)
  labels = []
  labels << {
    x: 40.from_left,
    y: 80.from_top,
    text: "DragonRuby Touch Playground",
    size_enum: 10,
  }
  labels << {
    x: 40.from_right,
    y: 80.from_top,
    text: "#{$gtk.production ? 'prod' : 'debug'}",
    alignment_enum: 2,
    size_enum: 8,
  }

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
  args.state.swipes ||= []

  if args.inputs.mouse.down && args.inputs.mouse.inside_rect?(args.state.rect)
    args.state.rect.dragging = true
    args.state.rect.b = 150
  elsif args.inputs.mouse.up
    args.state.rect.dragging = false
    args.state.rect.b = 250
  end

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

  if args.state.rect.dragging
    args.state.rect.x = args.inputs.mouse.x - args.state.rect.w / 2
    args.state.rect.y = args.inputs.mouse.y - args.state.rect.h / 2
  end

  lines = []
  solids = []
  solids << { x: 0, y: 0, w: args.grid.w, h: args.grid.h, r: 240, g: 240, b: 240 }
  solids << args.state.rect

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
  args.outputs.background_color = [34, 34, 34]
  args.outputs.primitives << buttons.map { |b| button_for_render(b) }
  args.outputs.solids << solids
  args.outputs.lines << lines
  args.outputs.lines << lines
  args.outputs.labels << labels
end

def button_for_render(b)
  b.slice(:bg, :border, :title, :desc).values
end

def button(x:, y:, w:, h:, key:, title:, desc: nil, on_click:)
  butt = {
    key: key,
    title: {
      x: x + 20,
      y: y - 20,
      text: title,
      size_enum: 2,
    }.label!,
    bg: {
      x: x,
      y: y - h,
      w: w - 20,
      h: h,
      a: 0,
      r: 20,
      b: 200,
      g: 20,
    }.solid!,
    border: {
      x: x,
      y: y - h,
      w: w - 20,
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

  butt[:tick] = -> (args, butt) do
    if args.inputs.mouse.position.inside_rect?(butt[:border])
      butt[:bg].a = 255

      if args.inputs.mouse.click
        butt.on_click.call(args)
      end
    end
  end

  butt
end
