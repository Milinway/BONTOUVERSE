-- ReplicatedStorage > module > data > dialog > 1_chapter(ModuleScript)
local dialog = {
	prolog_kelas = {
		dialog_id = "prolog_kelas",
		mode = "story_image",
		background_img = "rbxassetid://121727539628718",
		lines = {
			{
				speaker = "Bu Melinda",
				character_img = "rbxassetid://110096246970546",
				text = "Anak-anak, libur panjang tiga minggu kalian kini telah usai.",
				voice_id = "rbxassetid://131583677531641",
			},
			{
				speaker = "Bu Melinda",
				character_img = "rbxassetid://75338738902866",
				text = "Bagaimana perasaan kalian? Pasti lebih fresh ya!",
				voice_id = "rbxassetid://70657636717809",
			},
			{
				speaker = "Bu Melinda",
				character_img = "rbxassetid://110096246970546",
				text = "Ibu yakin banyak cerita seru yang sudah kalian lalui.",
				voice_id = "rbxassetid://129946273727744",
			},
			{
				speaker = "Najieb",
				character_img = "rbxassetid://118770143213452",
				text = "Ah, tidak juga kok, Bu.",
				voice_id = "rbxassetid://134228950900343",
			},
			{
				speaker = "Najieb",
				character_img = "rbxassetid://118770143213452",
				text = "Liburan kemarin kerjaan saya cuma mabar dan push rank.",
				voice_id = "rbxassetid://136456062361268",
			},
			{
				speaker = "Najieb",
				character_img = "rbxassetid://118770143213452",
				text = "Tapi tenang Bu, sekarang saya sudah Immo!",
				voice_id = "rbxassetid://70618480943731",
			},
			{
				speaker = "Najieb",
				character_img = "rbxassetid://95163968829807",
				text = "Izin, Izin~",
				voice_id = "rbxassetid://120853674899749",
			},
			{
				speaker = "Teman-teman Kelas",
				character_img = "",
				text = "AAHAHAHAHA!",
			},
			{
				speaker = "Bu Melinda",
				character_img = "rbxassetid://120899008590901",
				text = "Memang kamu ini ya Najieb, ada-ada saja tingkahmu.",
			},
			{
				speaker = "Bu Melinda",
				character_img = "rbxassetid://120899008590901",
				text = "Jangan dicontoh ya anak-anak, masa liburan dipakai main game terus.",
			},
			{
				speaker = "Bu Melinda",
				character_img = "rbxassetid://75338738902866",
				text = "Nah, kalau yang lain bagaimana? Ada yang punya pengalaman seru atau bermanfaat?",
			},
			{
				speaker = "Murid-murid",
				character_img = "",
				text = "Saya Bu! Sayaaa!",
			},
			{
				speaker = "Bu Melinda",
				character_img = "rbxassetid://110096246970546",
				text = "Wah, antusias sekali kalian! Coba Ibu tunjuk satu orang dulu ya...",
			},
			{
				speaker = "Bu Melinda",
				character_img = "rbxassetid://122152391628875",
				text = "...",
			},
			{
				speaker = "Bu Melinda",
				character_img = "rbxassetid://75338738902866",
				text = "Kamu, Windy! Silakan maju ke depan dan bagikan ceritamu.",
			},
			{
				speaker = "Windy",
				character_img = "rbxassetid://106359166145510",
				text = "Halo semuanya!",
			},
			{
				speaker = "Windy",
				character_img = "rbxassetid://124751799607169",
				text = "Kalau boleh jujur, liburanku kemarin tidak pergi ke luar kota yang jauh kok.",
			},
			{
				speaker = "Windy",
				character_img = "rbxassetid://124751799607169",
				text = "Tapi jangan salah, aku mendapat kesempatan emas untuk menjadi pemandu wisata bagi turis asing yang berkunjung ke Kota Bontang!",
			},
			{
				speaker = "Windy",
				character_img = "rbxassetid://124751799607169",
				text = "Nah, begini ceritanya...",
			},
		},
	},

	dermaga_welcome = {
		dialog_id = "dermaga_welcome",
		mode = "story_image",
		background_img = "rbxassetid://88842970506811",
		lines = {
			{
				speaker = "Windy",
				character_img = "rbxassetid://131129457535015",
				text = "Mister John, Miss Jane, welcome to Bontang!",
			},
			{
				speaker = "Windy",
				character_img = "rbxassetid://131129457535015",
				text = "Hari ini kita akan menyeberang ke surga kecil kami, yakni Pulau Beras Basah.",
			},
			{
				speaker = "Mister John",
				character_img = "rbxassetid://JOHN_IMAGE_ID",
				text = "Wow, thank you, Windy! I heard the sand there is as white as rice, is that true?",
				-- Ini adalah choice point - player bisa memilih jawaban
				choices = {
					{
						choice_id = "answer_a",
						is_correct = true,
						-- Response yang ditampilkan SETELAH player memilih choice ini
						choice_response = {
							{
								speaker = "Windy",
								character_img = "rbxassetid://131129457535015",
								text = "Yes! That's why it's called Beras Basah (Wet Rice) Island",
							},
							{
								speaker = "Mister John",
								character_img = "rbxassetid://JOHN_IMAGE_ID",
								text = "Oh wow, that sounds amazing!",
							},
							{
								speaker = "Miss Jane",
								character_img = "rbxassetid://JANE_IMAGE_ID",
								text = "I really want to see that beautiful island now!",
							},
						},
					},
					{
						choice_id = "answer_b",
						is_correct = true,
						-- Response yang ditampilkan SETELAH player memilih choice ini
						choice_response = {
							{
								speaker = "Windy",
								character_img = "rbxassetid://131129457535015",
								text = "Not just the sand, Mister! The underwater view and the iconic lighthouse are amazing too!",
							},
							{
								speaker = "Mister John",
								character_img = "rbxassetid://JOHN_IMAGE_ID",
								text = "I'd love to see the lighthouse!",
							},
							{
								speaker = "Miss Jane",
								character_img = "rbxassetid://JANE_IMAGE_ID",
								text = "That sounds like an incredible experience!",
							},
						},
					},
				},
			},
		},
	},

	kapal_intro = {
		dialog_id = "kapal_intro",
		mode = "story_image",
		background_img = "rbxassetid://111325514733517",
		lines = {
			{
				speaker = "Miss Jane",
				character_img = "rbxassetid://JANE_IMAGE_ID",
				text = "Windy, this boat looks unique. What do local people call it?",
			},
			{
				speaker = "Windy",
				character_img = "rbxassetid://131129457535015",
				text = "Sst, ayo bantu aku jelaskan ke Miss Jane tentang kapal ini!",
			},
		},
	},

	kapal_after_quiz = {
		dialog_id = "kapal_after_quiz",
		mode = "story_image",
		background_img = "rbxassetid://132270545701111",
		lines = {
			{
				speaker = "Windy",
				character_img = "rbxassetid://131129457535015",
				text = "Benar sekali! This traditional boat is called Ketingting, Miss Jane. It uses a specific long-tail motor to move through the shallow waters.",
			},
			{
				speaker = "Miss Jane",
				character_img = "rbxassetid://JANE_IMAGE_ID",
				text = "Oh, I see! Incredible. And how long does it take to reach the island?",
			},
			{
				speaker = "Windy",
				character_img = "rbxassetid://131129457535015",
				text = "It takes about 45 minutes, Mister, Miss. So you can just relax and enjoy the beautiful sea breeze and view.",
			},
			{
				speaker = "Mister John",
				character_img = "rbxassetid://JOHN_IMAGE_ID",
				text = "Splendid! Bontang feels so warm and welcoming.",
			},
		},
	},
	
	pulau_arrival1 = {
		dialog_id = "pulau_arrival1",
		mode = "story_image",
		background_img = "rbxassetid://104459813734206",
		lines = {
			{
				speaker = "Windy",
				character_img = "rbxassetid://131129457535015",
				text = "Sampai! Mr John, Miss Jane Welcome to Beras Basah!",
			},
			{
				speaker = "Miss Jane",
				character_img = "rbxassetid://KIYA_IMAGE_ID",
				text = "Oh my look at this masterpiece, this looks Awesome!",
			},
			{
				speaker = "Mister John",
				character_img = "rbxassetid://KIYA_IMAGE_ID",
				text = "What a art, ive got to take picture to this thing!",
			},
			{
				speaker = "Windy",
				character_img = "rbxassetid://131129457535015",
				text = "Hihihihi, baiklah akan kuberikan kalian beberapa free eksplor untuk bisa berkeliling sekitar Beras Basah ini!",
			},
		},
	},

	pulau_arrival2 = {
		dialog_id = "pulau_arrival2",
		mode = "story_image",
		background_img = "rbxassetid://96121074381057",
		lines = {
			{
				speaker = "Miss Jane",
				character_img = "rbxassetid://JANE_IMAGE_ID",
				text = "Oh look, the island is gorgeous! But... it is a bit sad to see some plastic bottles over there...",
			},
			{
				speaker = "Windy",
				character_img = "rbxassetid://131129457535015",
				text = "Aduh, malu-maluin nih! Sebagai pemandu yang baik, kita harus tunjukkan kalau kita peduli sama kebersihan Beras Basah. Ayo kita bersihkan!",
			},
		},
	},
	
	after_minigame3 = {
		dialog_id = "after_minigame3",
		mode = "story_image",
		background_img = "rbxassetid://96121074381057",
		lines = {
			{
				speaker = "Miss Jane",
				character_img = "rbxassetid://JANE_IMAGE_ID",
				text = "You guys are local heroes! The island looks so clean and pristine now!...",
			},
			{
				speaker = "Windy",
				character_img = "rbxassetid://131129457535015",
				text = "Ya benar, ini berkat kepedulian kita terhadap lingkungan sekitar!",
			},
			{
				speaker = "Miss Jane",
				character_img = "rbxassetid://JANE_IMAGE_ID",
				text = "Betul, betul, betul",
			},
		},
	},

	ending_kelas = {
		dialog_id = "ending_kelas",
		mode = "story_image",
		background_img = "rbxassetid://121727539628718",
		lines = {
			{
				speaker = "Windy",
				character_img = "rbxassetid://KIYA_IMAGE_ID",
				text = "...Nah, dari perjalanan hari pertama itu, aku sadar kalau turis asing itu suka banget sama Amplang Ikan kita dan kagum sama keindahan mercusuar. Kalau kita jaga wisatanya tetap bersih dan kelola dengan baik, UMKM warga lokal pasti makin laku keras dan ekonomi Bontang bakal maju!",
			},
			{
				speaker = "Bu Melinda",
				character_img = "rbxassetid://BU_MELINDA_IMAGE_ID",
				text = "Luar biasa, Windy! Cerita liburan yang sangat inspiratif dan penuh jiwa wirausaha. Nah anak-anak, dari cerita Kiya tadi, siapa yang bisa menebak apa nilai jual utama dari Pulau Beras Basah?",
			},
		},
	},
}

return dialog