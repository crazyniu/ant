extends Node
## Cosmetic-only motion: stable hit rectangles, cancellable tracks, no game callbacks.
const PRESS_DURATION := .065
const RELEASE_DURATION := .15
const MODAL_DURATION := .22
const CLOSE_DURATION := .12
const REST_META := &"ui_motion_rest"
const TRANSFORM_META := &"ui_motion_transform"
const ALPHA_META := &"ui_motion_alpha"
var retired_modals: Array[Control] = []

func bind_button(button: Button) -> void:
	if button.has_meta(&"ui_motion_bound"):return
	button.set_meta(&"ui_motion_bound",true)
	button.button_down.connect(_button_pose.bind(button,true))
	button.button_up.connect(_button_pose.bind(button,false))
	button.mouse_exited.connect(_button_pose.bind(button,false))
	button.focus_exited.connect(_button_pose.bind(button,false))

func _rest(target: Control) -> Dictionary:
	if not target.has_meta(REST_META):
		target.set_meta(REST_META,{"position":target.position,"scale":target.scale,"pivot":target.pivot_offset,"alpha":target.modulate.a})
	return target.get_meta(REST_META)

func _cancel(target: Control, key: StringName) -> void:
	if not target.has_meta(key):return
	var tween:Tween=target.get_meta(key)
	if tween!=null and tween.is_valid():tween.kill()
	target.remove_meta(key)

func _track(target: Control, key: StringName) -> Tween:
	_cancel(target,key)
	var tween:=target.create_tween()
	target.set_meta(key,tween)
	return tween

func _button_art(button: Button) -> Array[Control]:
	var targets:Array[Control]=[]
	var bounds:=Rect2(button.position,button.size).grow(2)
	for child in button.get_parent().get_children():
		if not child is Control or child is BaseButton or child is Range or not child.visible:continue
		var target:=child as Control
		# Art remains a sibling, preserving existing node paths and input geometry.
		var rest:Dictionary=target.get_meta(REST_META,{"position":target.position})
		var art_bounds:=Rect2(rest.position,target.size)
		if bounds.encloses(art_bounds):targets.append(target)
	return targets

func _button_pose(button: Button, down: bool) -> void:
	if not is_instance_valid(button) or not button.is_inside_tree():return
	if down and button.disabled:return
	for target in _button_art(button):
		var rest:=_rest(target)
		var tween:=_track(target,TRANSFORM_META)
		# Pivot around the whole button, not every letter/icon separately.
		_set_pivot(target,button.position+button.size*.5-rest.position)
		var duration:=PRESS_DURATION if down else RELEASE_DURATION
		tween.set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(target,"scale",rest.scale*(.96 if down else 1.0),duration)
		tween.tween_property(target,"position",rest.position+Vector2(0,1.5 if down else 0),duration)
		# Never change modulate: disabled/used tool tint remains authoritative.
		if not down:tween.chain().tween_callback(_restore_transform.bind(target))

func _set_pivot(target: Control, pivot: Vector2) -> void:
	# Mid-reveal presses must not jump when switching from modal to button pivot.
	target.position+=(target.pivot_offset-pivot)*(Vector2.ONE-target.scale)
	target.pivot_offset=pivot

func _restore_transform(target: Control) -> void:
	if not is_instance_valid(target):return
	var rest:=_rest(target)
	target.position=rest.position;target.scale=rest.scale;target.pivot_offset=rest.pivot

func prepare_modal(overlay: Control, center: Vector2) -> void:
	discard_retired()
	overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	overlay.set_meta(&"ui_modal_active",true)
	overlay.set_meta(&"ui_modal_center",center)
	overlay.child_entered_tree.connect(_modal_child_added.bind(overlay,center))

func _modal_child_added(node: Node, overlay: Control, center: Vector2) -> void:
	if not overlay.get_meta(&"ui_modal_active",false) or not node is Control:return
	if node is BaseButton or node is Range:return
	var target:=node as Control
	if target.name=="ModalShade":
		_fade_in(target,.16)
		return
	var emblem:bool="Emblem" in target.name
	_reveal(target,center,Vector2(0,12),.975,MODAL_DURATION,.025 if emblem else 0.0)

func _fade_in(target: Control, duration: float, delay: float=0.0) -> void:
	var rest:=_rest(target)
	target.modulate.a=0.0
	var fade:=_track(target,ALPHA_META)
	fade.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade.tween_property(target,"modulate:a",rest.alpha,duration).set_delay(delay)

func _reveal(target: Control, center: Vector2, offset: Vector2, from_scale: float, duration: float, delay: float=0.0) -> void:
	var rest:=_rest(target)
	var tween:=_track(target,TRANSFORM_META)
	target.pivot_offset=center-rest.position
	target.position=rest.position+offset;target.scale=rest.scale*from_scale
	tween.set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(target,"position",rest.position,duration).set_delay(delay)
	tween.tween_property(target,"scale",rest.scale,duration).set_delay(delay)
	tween.chain().tween_callback(_restore_transform.bind(target))
	_fade_in(target,minf(duration,.16),delay)

func reveal_hint(target: Control) -> void:
	# One short entrance. Existing owner still decides hint lifetime and game state.
	if not is_instance_valid(target):return
	_reveal(target,target.position+target.size*.5,Vector2(0,5),.985,.18)

func close_modal(overlay: Control) -> void:
	if not is_instance_valid(overlay):return
	discard_retired()
	overlay.set_meta(&"ui_modal_active",false)
	overlay.name="ClosingModal"
	_cancel_tree(overlay)
	_disable_input(overlay)
	retired_modals.append(overlay)
	for child in overlay.get_children():
		if not child is Control or child is BaseButton or child is Range or child.name=="ModalShade":continue
		var target:=child as Control
		var rest:=_rest(target)
		var tween:=_track(target,TRANSFORM_META)
		_set_pivot(target,Vector2(overlay.get_meta(&"ui_modal_center",overlay.size*.5))-rest.position)
		tween.set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(target,"position",rest.position+Vector2(0,6),CLOSE_DURATION)
		tween.tween_property(target,"scale",rest.scale*.985,CLOSE_DURATION)
	var fade:=_track(overlay,ALPHA_META)
	fade.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade.tween_property(overlay,"modulate:a",0.0,CLOSE_DURATION)
	fade.tween_callback(_finish_close.bind(overlay))

func _disable_input(node: Node) -> void:
	if node is Control:
		node.mouse_filter=Control.MOUSE_FILTER_IGNORE
		node.focus_mode=Control.FOCUS_NONE
	if node is BaseButton:
		node.disabled=true
		# A retired page cannot call navigation or spend a tool even if an old
		# reference emits pressed while its cosmetic fade is still visible.
		for connection in node.pressed.get_connections():node.pressed.disconnect(connection.callable)
	for child in node.get_children():_disable_input(child)

func _cancel_tree(node: Node) -> void:
	if node is Control:
		_cancel(node,TRANSFORM_META);_cancel(node,ALPHA_META)
	for child in node.get_children():_cancel_tree(child)

func _finish_close(overlay: Control) -> void:
	retired_modals.erase(overlay)
	if is_instance_valid(overlay):
		if overlay.get_parent():overlay.get_parent().remove_child(overlay)
		overlay.queue_free()

func discard_modal(overlay: Control) -> void:
	if not is_instance_valid(overlay):return
	overlay.set_meta(&"ui_modal_active",false)
	_cancel_tree(overlay);_disable_input(overlay)
	_finish_close(overlay)

func discard_retired() -> void:
	for overlay in retired_modals.duplicate():discard_modal(overlay)
	retired_modals.clear()
