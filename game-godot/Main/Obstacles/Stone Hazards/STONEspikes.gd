class_name STONESpikes
extends Area2D

## Spikes are static hazards — always lethal on contact.
## When the player touches them, they lose a life and teleport to the level start.

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	# Prefer the spawn-point respawn so the player goes back to start.
	if body.has_method("take_spike_damage"):
		body.take_spike_damage()
	elif body.has_method("take_damage"):
		body.take_damage(global_position)
	else:
		push_warning("Spikes: body '%s' has no take_spike_damage() method." % body.name)
