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
		Quiz = {
			{
				Question = "Apa saja nilai jual ekonomi dan pariwisata di Pulau Beras Basah berdasarkan cerita Kiya?",
				Hint = "",
				image = "",
				Options = {
					A = "Pasir putih, Mercusuar ikonik, serta produk UMKM lokal seperti Amplang & Batik Kuntul Perak.",
					B = "Mal perbelanjaan mewah di tengah pulau dan wahana permainan modern.",
				},
				CorrectOption = "A",

				success_knowledge = 100,
			},
		},
		NextScene = "next_scene_name", -- Ganti dengan scene berikutnya
	}
}

return quiz