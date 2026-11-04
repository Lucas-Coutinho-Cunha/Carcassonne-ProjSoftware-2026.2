class_name CatalogValidator
extends RefCounted


static func validate(defs: Array[TileDef], expected_total: int = -1) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var total: int = 0
	var seen_ids: Dictionary = {}
	for def: TileDef in defs:
		total += def.count
		if seen_ids.has(def.id):
			errors.append("%s: duplicate tile id" % def.id)
		seen_ids[def.id] = true
		errors.append_array(_validate_def(def))
	if expected_total >= 0 and total != expected_total:
		errors.append("catalog has %d tiles, expected %d" % [total, expected_total])
	return errors


static func _validate_def(def: TileDef) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if def.edges.size() != 4:
		errors.append("%s: edges must have exactly 4 entries (N, E, S, W)" % def.id)
		return errors

	var claims: Array[int] = [0, 0, 0, 0]
	for i: int in def.features.size():
		var fd: Dictionary = def.features[i]
		var kind: int = fd.kind
		var sides: Array = fd.sides
		if kind == TileDef.Kind.MONASTERY:
			if not sides.is_empty():
				errors.append("%s: monastery feature %d must have no sides" % [def.id, i])
			continue
		if kind == TileDef.Kind.FIELD:
			errors.append("%s: fields are not modelled yet (feature %d)" % [def.id, i])
			continue
		if sides.is_empty():
			errors.append("%s: road/city feature %d has no sides" % [def.id, i])
		for s: int in sides:
			if s < 0 or s > 3:
				errors.append("%s: feature %d has invalid side %d" % [def.id, i, s])
				continue
			claims[s] += 1
			if def.edges[s] != kind:
				errors.append("%s: feature %d kind does not match the edge on side %d" % [def.id, i, s])

	for side: int in 4:
		var edge_kind: int = def.edges[side]
		if edge_kind == TileDef.Kind.FIELD:
			if claims[side] != 0:
				errors.append("%s: field edge on side %d is claimed by a feature" % [def.id, side])
		elif claims[side] != 1:
			errors.append("%s: road/city edge on side %d must belong to exactly one feature (has %d)" % [def.id, side, claims[side]])
	return errors
