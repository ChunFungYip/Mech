extends Control
class_name RadarDisplay

var radar_range: float = 50.0
var blips: Array[Dictionary] = []
var _elapsed: float = 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    queue_redraw()

func set_blips(new_blips: Array[Dictionary], range_m: float = 50.0) -> void:
    blips = new_blips
    radar_range = range_m
    queue_redraw()

func _process(delta: float) -> void:
    _elapsed += delta
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    var radius := minf(size.x, size.y) * 0.42
    var background := Color(0.008, 0.025, 0.035, 0.94)
    var grid := Color(0.12, 0.45, 0.46, 0.55)
    var sweep := Color(0.28, 0.96, 0.82, 0.48)

    draw_circle(center, radius + 5.0, Color(0.02, 0.12, 0.14, 0.95))
    draw_circle(center, radius, background)
    draw_arc(center, radius, 0.0, TAU, 96, grid, 2.0, true)
    draw_arc(center, radius * 0.66, 0.0, TAU, 96, Color(0.10, 0.33, 0.36, 0.42), 1.0, true)
    draw_arc(center, radius * 0.33, 0.0, TAU, 96, Color(0.10, 0.33, 0.36, 0.34), 1.0, true)
    draw_line(center - Vector2(radius, 0.0), center + Vector2(radius, 0.0), Color(0.10, 0.33, 0.36, 0.36), 1.0)
    draw_line(center - Vector2(0.0, radius), center + Vector2(0.0, radius), Color(0.10, 0.33, 0.36, 0.36), 1.0)

    var sweep_angle := fmod(_elapsed * 0.9, TAU)
    var sweep_end := center + Vector2.UP.rotated(sweep_angle) * radius
    draw_line(center, sweep_end, sweep, 2.0, true)

    for blip in blips:
        var normalized_position: Vector2 = blip.get("position", Vector2.ZERO)
        if normalized_position.length() > 1.0:
            normalized_position = normalized_position.normalized()
        var blip_position := center + normalized_position * radius * 0.90
        var kind: String = str(blip.get("kind", "heavy"))
        var color := _get_blip_color(kind)
        if kind == "boss":
            draw_circle(blip_position, 7.0, Color(0.95, 0.08, 0.08, 0.90))
            draw_arc(blip_position, 11.0 + sin(_elapsed * 5.0) * 2.0, 0.0, TAU, 32, color, 2.0, true)
        elif kind == "drone":
            var diamond := PackedVector2Array([
                blip_position + Vector2(0.0, -6.0),
                blip_position + Vector2(6.0, 0.0),
                blip_position + Vector2(0.0, 6.0),
                blip_position + Vector2(-6.0, 0.0),
            ])
            draw_colored_polygon(diamond, color)
        else:
            draw_circle(blip_position, 5.0, color)

    draw_circle(center, 4.0, Color(0.34, 1.0, 0.86, 1.0))
    draw_line(center + Vector2(0.0, -4.0), center + Vector2(0.0, -11.0), Color(0.72, 1.0, 0.88, 1.0), 2.0)

func _get_blip_color(kind: String) -> Color:
    match kind:
        "scout":
            return Color(1.0, 0.78, 0.18, 1.0)
        "drone":
            return Color(0.28, 0.82, 1.0, 1.0)
        "spider":
            return Color(0.90, 0.30, 0.90, 1.0)
        "boss":
            return Color(1.0, 0.18, 0.08, 1.0)
    return Color(1.0, 0.40, 0.16, 1.0)
