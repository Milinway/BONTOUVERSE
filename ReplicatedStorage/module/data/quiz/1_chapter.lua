-- ReplicatedStorage > module(Folder) > data(Folder) > quiz(Folder) > 1_chapter(ModuleScript)

local quiz = {
	ketingting_sentence = {
		quiz_id = "ketingting_sentence",
		type = "nyusun_kata",

		title = "Susun Kata Ketingting",

		question = "Susun kalimat berikut untuk menjelaskan kapal Ketingting kepada Miss Jane!",

		question_hint = "Jelaskan kapal tradisional yang bernama Ketingting kepada Miss Jane dengan menyusun kata-kata berikut.",
		character_name = "Jane",
		character_img = "rbxassetid://JANE_IMAGE_ID", -- Image character yang bertanya

		word_bank = {
			"called",
			"boat",
			"This",
			"is",
			"Ketingting",
			"traditional",
		},

		correct_answer = {
			"This",
			"traditional",
			"boat",
			"is",
			"called",
			"Ketingting",
		},

		correct_sentence = "This traditional boat is called Ketingting.",

		success_knowledge = 62,
	},

	final_chapter_quiz = {
		quiz_id = "final_chapter_quiz",
		type = "multiple_choice",
		title = "Refleksi Akhir Bab",
		
		questions = {
			{
				id = "question_1",
				Question = "Apa saja nilai jual ekonomi dan pariwisata di Pulau Beras Basah berdasarkan cerita Kiya?",
				Hint = "Pikirkan tentang keunikan alami dan produk lokal yang ada di pulau tersebut.",
				image = "", -- Kosongkan jika tidak ada gambar atau ganti dengan asset ID
				Options = {
					"Pasir putih, Mercusuar ikonik, serta produk UMKM lokal seperti Amplang & Batik Kuntul Perak.",
					"Mal perbelanjaan mewah di tengah pulau dan wahana permainan modern.",
				},
				CorrectOption = 1, -- Indeks opsi yang benar (1 atau 2)
			},
			{
				id = "question_2",
				Question = "Dalam cerita, Kiya mengajarkan nilai apa kepada wisatawan tentang pariwisata berkelanjutan?",
				Hint = "Perhatikan pesan utama yang disampaikan Kiya tentang menjaga kelestarian lingkungan dan budaya lokal.",
				image = "",
				Options = {
					"Mengutamakan keuntungan bisnis tanpa memperhatikan lingkungan.",
					"Menjaga kelestarian alam dan budaya lokal sambil memberikan manfaat ekonomi bagi masyarakat.",
				},
				CorrectOption = 2,
			},
			{
				id = "question_3",
				Question = "Apa peran utama seorang tour guide seperti yang dipelajari dalam chapter ini?",
				Hint = "Ingat kembali tugas-tugas yang Anda lakukan sepanjang chapter ini.",
				image = "",
				Options = {
					"Hanya mengumpulkan uang dari wisatawan sebanyak mungkin.",
					"Menjadi penghubung antara wisatawan dan destinasi wisata, memberikan edukasi, dan menjaga pengalaman mereka.",
				},
				CorrectOption = 2,
			},
		},

		success_knowledge = 100,
	}
}

return quiz
