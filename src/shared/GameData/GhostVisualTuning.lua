return {
	ghosts = {
		Pocong = {
			-- X = lebar, Y = tinggi, Z = ketebalan visual mesh utama.
			meshSize = Vector3.new(0.07, 0.06, 0.07),
			-- Naik/turunkan mesh relatif ke HumanoidRootPart.
			meshOffset = Vector3.new(0, 0.1, 0),
			-- Clamp bounding box saat model di-spawn agar asset impor tidak raksasa.
			targetBounds = Vector3.new(1.6, 3.75, 1.18),
			grounded = true,
			maxHoverHeight = 0,
		},
		Kuntilanak = {
			targetBounds = Vector3.new(3.5, 4.8, 1.8),
			maxHoverHeight = 0.05,
		},
		KuntilanakAggressive = {
			targetBounds = Vector3.new(2.2, 5.4, 1.8),
			maxHoverHeight = 0.05,
		},
		Genderuwo = {
			targetBounds = Vector3.new(3.4, 5.8, 2.6),
			grounded = true,
			maxHoverHeight = 0,
		},
		Leak = {
			targetBounds = Vector3.new(2.0, 4.8, 2.35),
			grounded = true,
			maxHoverHeight = 0,
		},
	},
}
