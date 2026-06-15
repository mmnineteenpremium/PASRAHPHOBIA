local function choice(label, nextNode)
	return { label = label, next = nextNode }
end

local DialogueData = {
	shopkeeper = {
		displayName = "ShopKeeper",
		root = "shopkeeper_root",
		shopkeeper_root = {
			id = "shopkeeper_root",
			text = "Halo Investigator! Ada yang bisa aku bantu?",
			choices = {
				{ label = "A: Cara beli Royal Pass", next = "shopkeeper_royalpass" },
				{ label = "B: Cara membeli Cosmetic", next = "shopkeeper_cosmetic" },
				{ label = "C: Cara memakai Outfit", next = "shopkeeper_outfit" },
				{ label = "D: Cara equip Pet", next = "shopkeeper_pet" },
				{ label = "E: Rekomendasi belanja pemula", next = "shopkeeper_recommend" },
				{ label = "F: Tidak ada, terima kasih", next = "CLOSE" },
			},
		},
		shopkeeper_recommend = {
			id = "shopkeeper_recommend",
			text = "Kalau baru mulai, prioritasmu biasanya outfit yang enak dipakai, pet kalau suka teman visual, lalu kosmetik favorit. Royal Pass cocok kalau kamu mau bonus lebih lengkap.",
			choices = {
				{ label = "A: Fokus outfit dulu", next = "shopkeeper_outfit" },
				{ label = "B: Fokus pet dulu", next = "shopkeeper_pet" },
				{ label = "C: Fokus kosmetik", next = "shopkeeper_cosmetic" },
				{ label = "D: Kembali", next = "ROOT" },
			},
		},
		shopkeeper_royalpass = {
			id = "shopkeeper_royalpass",
			text = "Royal Pass bisa dibeli di menu utama! Ada dua jenis.",
			choices = {
				{ label = "A: Berapa harganya?", next = "shopkeeper_royalpass_harga" },
				{ label = "B: Apa keuntungannya?", next = "shopkeeper_royalpass_benefit" },
				{ label = "C: Bagaimana cara membeli?", next = "shopkeeper_royalpass_cara" },
				{ label = "D: Kembali", next = "ROOT" },
			},
		},
		shopkeeper_royalpass_harga = {
			id = "shopkeeper_royalpass_harga",
			text = "Royal Pass Premium tersedia di halaman Royal Pass. Cek menu utama untuk harga terbaru!",
			choices = {
				{ label = "A: Kembali ke Royal Pass", next = "shopkeeper_royalpass" },
				{ label = "B: Menu utama", next = "ROOT" },
			},
		},
		shopkeeper_royalpass_benefit = {
			id = "shopkeeper_royalpass_benefit",
			text = "Dengan Royal Pass Premium kamu dapat XP bonus, kosmetik eksklusif, dan akses kelas spesial!",
			choices = {
				{ label = "A: Kembali ke Royal Pass", next = "shopkeeper_royalpass" },
				{ label = "B: Menu utama", next = "ROOT" },
			},
		},
		shopkeeper_royalpass_cara = {
			id = "shopkeeper_royalpass_cara",
			text = "Buka menu utama -> Royal Pass -> pilih tier -> beli. Perlu Robux ya!",
			choices = {
				{ label = "A: Kembali ke Royal Pass", next = "shopkeeper_royalpass" },
				{ label = "B: Menu utama", next = "ROOT" },
			},
		},
		shopkeeper_cosmetic = {
			id = "shopkeeper_cosmetic",
			text = "Kosmetik tersedia di toko ini! Ada berbagai kategori dan tiap item biasanya punya gaya pakai yang berbeda.",
			choices = {
				{ label = "A: Apa saja kategorinya?", next = "shopkeeper_cosmetic_kategori" },
				{ label = "B: Cara membayarnya?", next = "shopkeeper_cosmetic_bayar" },
				{ label = "C: Mana yang cocok buat pemula?", next = "shopkeeper_cosmetic_recommend" },
				{ label = "D: Kembali", next = "ROOT" },
			},
		},
		shopkeeper_cosmetic_recommend = {
			id = "shopkeeper_cosmetic_recommend",
			text = "Untuk pemula, pilih item yang paling sering kamu lihat di lobby dulu: outfit, head, emote, atau pet. Jangan buru-buru beli bundle kalau belum tahu selera mainmu.",
			choices = {
				{ label = "A: Kembali ke Cosmetic", next = "shopkeeper_cosmetic" },
				{ label = "B: Rekomendasi outfit", next = "shopkeeper_outfit" },
				{ label = "C: Rekomendasi pet", next = "shopkeeper_pet" },
			},
		},
		shopkeeper_cosmetic_kategori = {
			id = "shopkeeper_cosmetic_kategori",
			text = "Ada Outfit, Head, Emote, Bundle, dan Pet! Cek menu Shop ya.",
			choices = {
				{ label = "A: Kembali ke Cosmetic", next = "shopkeeper_cosmetic" },
				{ label = "B: Menu utama", next = "ROOT" },
			},
		},
		shopkeeper_cosmetic_bayar = {
			id = "shopkeeper_cosmetic_bayar",
			text = "Bisa pakai in-game currency atau Robux tergantung itemnya.",
			choices = {
				{ label = "A: Kembali ke Cosmetic", next = "shopkeeper_cosmetic" },
				{ label = "B: Menu utama", next = "ROOT" },
			},
		},
		shopkeeper_outfit = {
			id = "shopkeeper_outfit",
			text = "Outfit yang sudah dibeli bisa langsung dipakai dari Loadout! Setelah dipakai, kamu langsung terlihat di lobby.",
			choices = {
				{ label = "A: Di mana menu Loadout?", next = "shopkeeper_outfit_lokasi" },
				{ label = "B: Cara ganti outfit?", next = "shopkeeper_outfit_cara" },
				{ label = "C: Tips memilih outfit", next = "shopkeeper_outfit_tip" },
				{ label = "D: Kembali", next = "ROOT" },
			},
		},
		shopkeeper_outfit_tip = {
			id = "shopkeeper_outfit_tip",
			text = "Pilih outfit yang masih nyaman dilihat lama-lama. Untuk pemula, warna yang jelas dan siluet yang rapi biasanya paling aman.",
			choices = {
				{ label = "A: Kembali ke Outfit", next = "shopkeeper_outfit" },
				{ label = "B: Menu utama", next = "ROOT" },
			},
		},
		shopkeeper_outfit_lokasi = {
			id = "shopkeeper_outfit_lokasi",
			text = "Menu Loadout ada di panel kiri bawah layar saat di lobby.",
			choices = {
				{ label = "A: Kembali ke Outfit", next = "shopkeeper_outfit" },
				{ label = "B: Menu utama", next = "ROOT" },
			},
		},
		shopkeeper_outfit_cara = {
			id = "shopkeeper_outfit_cara",
			text = "Buka Loadout -> pilih slot Outfit -> klik item -> Equip. Langsung aktif!",
			choices = {
				{ label = "A: Kembali ke Outfit", next = "shopkeeper_outfit" },
				{ label = "B: Menu utama", next = "ROOT" },
			},
		},
		shopkeeper_pet = {
			id = "shopkeeper_pet",
			text = "Pet bisa di-equip dari menu Loadout juga! Pet biasanya tampil di belakangmu saat di lobby.",
			choices = {
				{ label = "A: Cara equip pet?", next = "shopkeeper_pet_cara" },
				{ label = "B: Pet ikut ke match?", next = "shopkeeper_pet_match" },
				{ label = "C: Pet terlihat di lobby?", next = "shopkeeper_pet_show" },
				{ label = "D: Kembali", next = "ROOT" },
			},
		},
		shopkeeper_pet_show = {
			id = "shopkeeper_pet_show",
			text = "Biasanya pet terlihat saat kamu masih di lobby. Kalau sedang match, pet ikut disembunyikan dulu supaya tidak mengganggu flow permainan.",
			choices = {
				{ label = "A: Kembali ke Pet", next = "shopkeeper_pet" },
				{ label = "B: Menu utama", next = "ROOT" },
			},
		},
		shopkeeper_pet_cara = {
			id = "shopkeeper_pet_cara",
			text = "Buka Loadout -> tab Pet -> pilih pet -> Equip. Pet akan muncul di belakangmu!",
			choices = {
				{ label = "A: Kembali ke Pet", next = "shopkeeper_pet" },
				{ label = "B: Menu utama", next = "ROOT" },
			},
		},
		shopkeeper_pet_match = {
			id = "shopkeeper_pet_match",
			text = "Pet hanya muncul di lobby. Saat match, pet bersembunyi dulu ya!",
			choices = {
				{ label = "A: Kembali ke Pet", next = "shopkeeper_pet" },
				{ label = "B: Menu utama", next = "ROOT" },
			},
		},
	},
	investigator = {
		displayName = "Investigator",
		root = "investigator_root",
		investigator_root = {
			id = "investigator_root",
			text = "Butuh bantuan navigasi? Aku tahu setiap sudut lobby ini dan bisa kasih urutan yang paling aman buat pemain baru.",
			choices = {
				{ label = "A: Menuju Queue / Match", next = "inv_queue" },
				{ label = "B: Menuju Shop", next = "inv_shop" },
				{ label = "C: Menuju Flex Zone", next = "inv_flex" },
				{ label = "D: Menuju Party Zone", next = "inv_party" },
				{ label = "E: Menuju Daily Reward", next = "inv_daily" },
				{ label = "F: Terima kasih!", next = "CLOSE" },
			},
		},
		inv_start = {
			id = "inv_start",
			text = "Kalau kamu baru pertama kali, urutan yang aman biasanya: Guide untuk orientasi, Training untuk alat, Shop untuk loadout, lalu Queue kalau sudah siap match.",
			choices = {
				{ label = "A: Temui Guide", next = "guide_root" },
				{ label = "B: Temui Training NPC", next = "training_root" },
				{ label = "C: Temui ShopKeeper", next = "shopkeeper_root" },
				{ label = "D: Kembali", next = "ROOT" },
			},
		},
		inv_queue = {
			id = "inv_queue",
			text = "Queue Hub ada di tengah plaza utama, cari gerbang besar!",
			choices = {
				{ label = "A: Ada apa di sana?", next = "inv_queue_info" },
				{ label = "B: Cara join queue?", next = "inv_queue_cara" },
				{ label = "C: Kembali", next = "ROOT" },
			},
		},
		inv_queue_info = {
			id = "inv_queue_info",
			text = "Tempat untuk masuk antrian match, lihat room list, atau buat room sendiri.",
			choices = {
				{ label = "A: Kembali ke Queue", next = "inv_queue" },
				{ label = "B: Menu utama", next = "ROOT" },
				{ label = "C: Panduan Lobby", next = "guide_root" },
			},
		},
		inv_queue_cara = {
			id = "inv_queue_cara",
			text = "Dekati gerbang -> tekan prompt -> pilih Room Browser -> join atau buat room!",
			choices = {
				{ label = "A: Kembali ke Queue", next = "inv_queue" },
				{ label = "B: Menu utama", next = "ROOT" },
			},
		},
		inv_shop = {
			id = "inv_shop",
			text = "Shop ada di sisi timur plaza, cari lampu neon dan etalase! Dari sana kamu bisa masuk ke outfit, pet, emote, dan bundle.",
			choices = {
				{ label = "A: Ada apa di sana?", next = "inv_shop_info" },
				{ label = "B: Cara beli?", next = "inv_shop_cara" },
				{ label = "C: Kembali", next = "ROOT" },
			},
		},
		inv_shop_info = {
			id = "inv_shop_info",
			text = "Tempat beli outfit, kosmetik, emote, pet, dan bundle eksklusif.",
			choices = {
				{ label = "A: Kembali ke Shop", next = "inv_shop" },
				{ label = "B: Menu utama", next = "ROOT" },
				{ label = "C: Ketemu ShopKeeper", next = "shopkeeper_root" },
			},
		},
		inv_shop_cara = {
			id = "inv_shop_cara",
			text = "Dekati konter -> tekan prompt Open Shop -> pilih item -> beli!",
			choices = {
				{ label = "A: Kembali ke Shop", next = "inv_shop" },
				{ label = "B: Menu utama", next = "ROOT" },
			},
		},
		inv_flex = {
			id = "inv_flex",
			text = "Flex Zone ada di panggung besar sebelah barat!",
			choices = {
				{ label = "A: Ada apa di sana?", next = "inv_flex_info" },
				{ label = "B: Kapan ada spotlight?", next = "inv_flex_jadwal" },
				{ label = "C: Kembali", next = "ROOT" },
			},
		},
		inv_flex_info = {
			id = "inv_flex_info",
			text = "Panggung untuk showcase kosmetik, event, dan spotlight komunitas.",
			choices = {
				{ label = "A: Kembali ke Flex", next = "inv_flex" },
				{ label = "B: Menu utama", next = "ROOT" },
				{ label = "C: Tanya Dukun", next = "dukun_root" },
			},
		},
		inv_flex_jadwal = {
			id = "inv_flex_jadwal",
			text = "Spotlight aktif saat ada event atau owner mengaktifkannya. Cek papan pengumuman!",
			choices = {
				{ label = "A: Kembali ke Flex", next = "inv_flex" },
				{ label = "B: Menu utama", next = "ROOT" },
			},
		},
		inv_party = {
			id = "inv_party",
			text = "Party Zone ada di platform elevated dekat taman!",
			choices = {
				{ label = "A: Ada apa di sana?", next = "inv_party_info" },
				{ label = "B: Cara buat party?", next = "inv_party_cara" },
				{ label = "C: Kembali", next = "ROOT" },
			},
		},
		inv_party_info = {
			id = "inv_party_info",
			text = "Tempat kumpul bareng teman, ngobrol, dan mulai match bareng.",
			choices = {
				{ label = "A: Kembali ke Party", next = "inv_party" },
				{ label = "B: Menu utama", next = "ROOT" },
			},
		},
		inv_party_cara = {
			id = "inv_party_cara",
			text = "Dekati Party Pad -> tekan prompt -> buat atau join party -> invite teman!",
			choices = {
				{ label = "A: Kembali ke Party", next = "inv_party" },
				{ label = "B: Menu utama", next = "ROOT" },
			},
		},
		inv_daily = {
			id = "inv_daily",
			text = "Daily Reward ada di taman, cari terminal dengan cahaya hijau! Kalau kamu telat klaim, streak bisa berhenti.",
			choices = {
				{ label = "A: Ada apa di sana?", next = "inv_daily_info" },
				{ label = "B: Cara claim?", next = "inv_daily_cara" },
				{ label = "C: Kembali", next = "ROOT" },
			},
		},
		inv_daily_info = {
			id = "inv_daily_info",
			text = "Klaim reward harian tiap hari. Streak berturut-turut dapat bonus lebih besar!",
			choices = {
				{ label = "A: Kembali ke Daily", next = "inv_daily" },
				{ label = "B: Menu utama", next = "ROOT" },
				{ label = "C: Temui Penjaga Taman", next = "garden_root" },
			},
		},
		inv_daily_cara = {
			id = "inv_daily_cara",
			text = "Dekati terminal -> tekan Claim -> reward langsung masuk. Sekali per hari ya!",
			choices = {
				{ label = "A: Kembali ke Daily", next = "inv_daily" },
				{ label = "B: Menu utama", next = "ROOT" },
				{ label = "C: Baca panduan lengkap", next = "guide_root" },
			},
		},
	},
	guide = {
		displayName = "Guide",
		root = "guide_root",
		guide_root = {
			id = "guide_root",
			text = "Kalau kamu baru masuk lobby, aku bisa tunjukkan alurnya dari awal sampai paham. Aku paling cocok dipakai sebagai NPC pertama yang kamu temui.",
			choices = {
				choice("A: Mulai dari mana?", "guide_start"),
				choice("B: Zona lobby ada apa saja?", "guide_zones"),
				choice("C: Cara masuk match?", "guide_match"),
				choice("D: Siapa NPC yang harus kutanya?", "guide_npcs"),
				choice("E: Tips pemula cepat", "guide_tips"),
				choice("F: Tutup", "CLOSE"),
			},
		},
		guide_start = {
			id = "guide_start",
			text = "Pertama, pahami 4 langkah: lihat zona, pilih NPC yang tepat, buka menu yang dibutuhkan, lalu masuk match saat siap.",
			choices = {
				choice("A: Lihat zona lobby", "guide_zones"),
				choice("B: Cara masuk match", "guide_match"),
				choice("C: Urutan pemula", "inv_start"),
				choice("D: Kembali", "ROOT"),
			},
		},
		guide_zones = {
			id = "guide_zones",
			text = "Queue untuk antrian match. Shop untuk beli item. Training Zone untuk latihan tool. Garden untuk reward harian. Flex Zone untuk event. Party Zone untuk main bareng teman.",
			choices = {
				choice("A: Ke Queue / Match", "investigator_root"),
				choice("B: Ke Shop", "shopkeeper_root"),
				choice("C: Ke Training Zone", "training_root"),
				choice("D: Ke Garden", "garden_root"),
				choice("E: Kembali", "ROOT"),
			},
		},
		guide_match = {
			id = "guide_match",
			text = "Dekati prompt di queue, buka room browser, pilih room atau buat room, lalu ready. Kalau bingung lihat papan petunjuk di tengah plaza.",
			choices = {
				choice("A: Apa fungsi Queue Hub?", "guide_queue"),
				choice("B: Kembali", "ROOT"),
			},
		},
		guide_queue = {
			id = "guide_queue",
			text = "Queue Hub adalah pintu masuk utama ke match. Dari sini kamu bisa join room, bikin room, atau sekadar lihat alur permainan sebelum masuk.",
			choices = {
				choice("A: Cara join cepat?", "investigator_root"),
				choice("B: Kembali", "guide_match"),
			},
		},
		guide_npcs = {
			id = "guide_npcs",
			text = "ShopKeeper membantu belanja dan loadout. Investigator menunjuk arah lokasi. Guide bantu navigasi umum. Training NPC jelaskan tool. Penjaga Taman soal reward. Dukun jadi pusat tanya bebas.",
			choices = {
				choice("A: Temui ShopKeeper", "shopkeeper_root"),
				choice("B: Temui Investigator", "investigator_root"),
				choice("C: Temui Training NPC", "training_root"),
				choice("D: Temui Penjaga Taman", "garden_root"),
				choice("E: Temui Dukun", "dukun_root"),
				choice("F: Kembali", "ROOT"),
			},
		},
		guide_tips = {
			id = "guide_tips",
			text = "Kalau benar-benar bingung: 1) tanya Guide, 2) tanya Investigator untuk lokasi, 3) tanya Training NPC untuk alat, 4) tanya Garden untuk reward, 5) tanya Dukun untuk pertanyaan panjang. Urutan ini aman buat pemula.",
			choices = {
				choice("A: Aku mau mulai latihan", "training_root"),
				choice("B: Aku mau cari reward", "garden_root"),
				choice("C: Aku mau belanja", "shopkeeper_root"),
				choice("D: Kembali", "ROOT"),
			},
		},
	},
	training = {
		displayName = "Training",
		root = "training_root",
		training_root = {
			id = "training_root",
			text = "Mau belajar tools, evidence, atau cara aman bertahan di match? Aku bisa jelaskan satu per satu, dari yang paling dasar sampai alur lengkap.",
			choices = {
				choice("A: Tools dasar", "training_tools"),
				choice("B: Evidence dasar", "training_evidence"),
				choice("C: Cara pakai Training Zone", "training_zone"),
				choice("D: Loadout dan urutan belajar", "training_loadout"),
				choice("E: Tips aman saat ghost aktif", "training_safety"),
				choice("F: Kembali", "CLOSE"),
			},
		},
		training_tools = {
			id = "training_tools",
			text = "Mulai dari alat paling penting: senter, alat deteksi, alat komunikasi, dan alat perlindungan. Cek loadout sebelum match supaya tidak lupa bawa. Kalau ragu, latih satu alat dulu sampai paham responsnya.",
			choices = {
				choice("A: Evidence dasar", "training_evidence"),
				choice("B: Urutan belajar", "training_loadout"),
				choice("C: Kembali", "ROOT"),
			},
		},
		training_evidence = {
			id = "training_evidence",
			text = "Evidence adalah petunjuk yang ditemukan di match. Biasanya dari alat deteksi, interaksi ghost, atau tanda khusus di area investigasi. Kalau belum yakin, fokus ke satu alat dulu lalu bandingkan hasilnya.",
			choices = {
				choice("A: Tool yang paling awal dipakai", "training_tools"),
				choice("B: Kembali", "ROOT"),
			},
		},
		training_zone = {
			id = "training_zone",
			text = "Training Zone dipakai untuk latihan tanpa tekanan match. Coba aktifkan alat, amati respons, lalu ulangi sampai kamu paham ritmenya. Ini tempat paling aman untuk mencoba sesuatu yang belum pernah kamu pakai.",
			choices = {
				choice("A: Apa yang harus dilatih dulu?", "training_tools"),
				choice("B: Tips aman", "training_safety"),
				choice("C: Kembali", "ROOT"),
			},
		},
		training_loadout = {
			id = "training_loadout",
			text = "Urutan belajar yang paling stabil: 1) kenali Tool dasar, 2) pahami Evidence, 3) coba di Training Zone, 4) baru masuk Queue. Kalau kamu belum punya item, cek ShopKeeper dulu.",
			choices = {
				choice("A: Tool dasar", "training_tools"),
				choice("B: Ke ShopKeeper", "shopkeeper_root"),
				choice("C: Kembali", "ROOT"),
			},
		},
		training_safety = {
			id = "training_safety",
			text = "Jangan panik saat ghost aktif. Bawa satu alat satu waktu, simpan jalur kabur, dan jangan berdiri di titik sempit terlalu lama.",
			choices = {
				choice("A: Aku mau latihan tool", "training_tools"),
				choice("B: Aku butuh panduan lobby", "guide_root"),
				choice("C: Kembali", "ROOT"),
			},
		},
	},
	garden = {
		displayName = "Garden",
		root = "garden_root",
		garden_root = {
			id = "garden_root",
			text = "Aku menjaga jalur taman dan reward harian. Mau klaim reward, cek event, atau tahu streak? Di sini juga tempat terbaik untuk check-in harian.",
			choices = {
				choice("A: Cara claim daily reward", "garden_claim"),
				choice("B: Apa itu streak?", "garden_streak"),
				choice("C: Event dan pengumuman", "garden_event"),
				choice("D: Cara check-in harian", "garden_checkin"),
				choice("E: Di mana terminalnya?", "garden_terminal"),
				choice("F: Kembali", "CLOSE"),
			},
		},
		garden_claim = {
			id = "garden_claim",
			text = "Datang ke terminal reward harian, tekan Claim, lalu ambil hadiahmu. Biasanya hanya bisa sekali per hari dan masuk ke akunmu setelah konfirmasi.",
			choices = {
				choice("A: Cara cek streak", "garden_streak"),
				choice("B: Kembali", "ROOT"),
			},
		},
		garden_streak = {
			id = "garden_streak",
			text = "Streak artinya kamu claim berurutan tiap hari. Semakin panjang streak, semakin layak bonus yang biasanya kamu dapat.",
			choices = {
				choice("A: Claim reward", "garden_claim"),
				choice("B: Event", "garden_event"),
				choice("C: Kembali", "ROOT"),
			},
		},
		garden_event = {
			id = "garden_event",
			text = "Event diumumkan lewat papan, highlight, atau area sosial di lobby. Kalau ada spotlight, biasanya garden dan flex jadi tempat info penting juga. Cek ini kalau kamu tidak mau ketinggalan update.",
			choices = {
				choice("A: Lihat reward", "garden_claim"),
				choice("B: Kembali", "ROOT"),
			},
		},
		garden_checkin = {
			id = "garden_checkin",
			text = "Check-in harian biasanya mengikuti reward harian. Datang tiap hari supaya streak tetap hidup dan bonus tidak putus.",
			choices = {
				choice("A: Claim reward", "garden_claim"),
				choice("B: Kembali", "ROOT"),
			},
		},
		garden_terminal = {
			id = "garden_terminal",
			text = "Terminal reward ada di area garden. Ikuti jalan taman lalu cari terminal bercahaya hijau atau area claim yang ditandai.",
			choices = {
				choice("A: Cara claim", "garden_claim"),
				choice("B: Kembali", "ROOT"),
			},
		},
	},
	dukun = {
		displayName = "Dukun",
		root = "dukun_root",
		responses = {
			{
				keywords = { "daily", "checkin", "reward", "claim", "streak", "event" },
				text = "Kalau soal daily reward dan event: menuju Garden, cari terminal claim, lalu ambil reward harian. Cek streak kalau kamu klaim tiap hari. Event biasanya diumumkan lewat area garden dan flex.",
			},
			{
				keywords = { "training", "latihan", "tool", "alat", "emf", "uv", "camera", "flashlight", "salt", "book", "crucifix", "loadout" },
				text = "Kalau soal training, mulai dari alat dasar dulu. Masuk Training Zone, coba satu tool per satu, lalu pelajari responsnya. Jangan langsung bawa banyak alat kalau belum hafal fungsi masing-masing.",
			},
			{
				keywords = { "ghost", "hantu", "hunt", "evidence", "eviden", "manifest", "match", "jumpscare", "sanity" },
				text = "Kalau soal ghost dan match: fokus baca evidence, jaga jarak aman, simpan jalur kabur, dan jangan panik. Kalau masih bingung, temui Training NPC untuk latihan langkah demi langkah.",
			},
			{
				keywords = { "shop", "loadout", "outfit", "pet", "royal", "pass", "cosmetic", "class", "emote", "bundle", "head" },
				text = "Kalau soal Shop dan class: ShopKeeper jelaskan Royal Pass, kosmetik, outfit, dan pet. Guide bisa arahkan ke lokasi shop. Kalau kamu cari class khusus, cek dulu informasi entitlement yang sudah kamu miliki.",
			},
			{
				keywords = { "queue", "match", "room", "party", "lobby", "join", "start", "queue hub", "room browser" },
				text = "Kalau soal match dan queue: menuju Queue Hub di plaza utama, tekan prompt, buka room browser, lalu join atau buat room. Kalau main berkelompok, gunakan Party Zone dulu.",
			},
			{
				keywords = { "camera", "cursor", "lock", "freeze", "controls", "movement", "dialogue", "npc", "prompt" },
				text = "Kalau soal kontrol dan dialog: saat dialog aktif, player seharusnya terkunci, kamera berpindah ke side view, dan tombol prompt dipakai untuk memilih jawaban. Kalau tidak terjadi, itu berarti sistem dialog atau kamera perlu dicek ulang.",
			},
		},
		dukun_root = {
			id = "dukun_root",
			text = "Aku bisa jawab banyak hal. Kamu bisa pilih topik cepat atau ketik pertanyaan bebas di bawah.",
			choices = {
				choice("A: Tanya bebas", "dukun_ask"),
				choice("B: Topik cepat", "dukun_topics"),
				choice("C: Soal tool dan evidence", "dukun_tools"),
				choice("D: Soal reward dan event", "dukun_reward"),
				choice("E: Soal match dan party", "dukun_match"),
				choice("F: Tutup", "CLOSE"),
			},
		},
		dukun_ask = {
			id = "dukun_ask",
			text = "Ketik pertanyaanmu di bawah. Aku akan jawab berdasarkan kata kunci yang aku kenali.",
			inputMode = "freeform",
			inputPlaceholder = "Contoh: cara claim daily reward?",
			choices = {
				choice("A: Lihat topik cepat", "dukun_topics"),
				choice("B: Kembali", "ROOT"),
				choice("C: Tutup", "CLOSE"),
			},
		},
		dukun_topics = {
			id = "dukun_topics",
			text = "Pilih topik cepat agar aku jawab tanpa perlu mengetik.",
			choices = {
				choice("A: Tool dan evidence", "dukun_tools"),
				choice("B: Ghost dan match", "dukun_match"),
				choice("C: Reward dan event", "dukun_reward"),
				choice("D: Shop dan class", "dukun_shop"),
				choice("E: NPC bantuan lainnya", "guide_root"),
				choice("F: Tutup", "CLOSE"),
			},
		},
		dukun_tools = {
			id = "dukun_tools",
			text = "Tool paling aman dipahami bertahap: satu alat, satu fungsi, satu hasil. Kalau belum hafal, balik dulu ke Training Zone sebelum kamu masuk match serius.",
			choices = {
				choice("A: Tanya bebas", "dukun_ask"),
				choice("B: Training Zone", "training_root"),
				choice("C: Kembali", "ROOT"),
			},
		},
		dukun_reward = {
			id = "dukun_reward",
			text = "Daily reward, event, dan check-in semuanya berpusat di Garden. Claim tiap hari kalau mau streak tetap hidup.",
			choices = {
				choice("A: Ke Garden", "garden_root"),
				choice("B: Tanya bebas", "dukun_ask"),
				choice("C: Kembali", "ROOT"),
			},
		},
		dukun_match = {
			id = "dukun_match",
			text = "Match yang rapi dimulai dari Queue Hub. Kalau mau siap, cek juga Training Zone dan Guide dulu supaya tidak masuk match buta.",
			choices = {
				choice("A: Ke Guide", "guide_root"),
				choice("B: Ke Investigator", "investigator_root"),
				choice("C: Tanya bebas", "dukun_ask"),
				choice("D: Kembali", "ROOT"),
			},
		},
		dukun_shop = {
			id = "dukun_shop",
			text = "ShopKeeper paling tepat untuk Royal Pass, outfit, cosmetic, dan pet. Kalau kamu bingung mulai dari mana, buka Guide dulu lalu lanjut ke ShopKeeper.",
			choices = {
				choice("A: Ke ShopKeeper", "shopkeeper_root"),
				choice("B: Ke Guide", "guide_root"),
				choice("C: Tanya bebas", "dukun_ask"),
				choice("D: Kembali", "ROOT"),
			},
		},
	},
}

return DialogueData
