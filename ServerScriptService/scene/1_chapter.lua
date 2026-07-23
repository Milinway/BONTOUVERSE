-- ServerScriptService > scene > 1_chapter(ModuleScript)
local chapter = {}

chapter.chapter_id = "chapter_1"
chapter.title = "Chapter 1"
chapter.subtitle = "Menjadi Seorang Tour Guide"

chapter.sequences = {
	chapter_start = {
		{action = "homepage_hide"},
		{action = "dialog", dialog_id = "prolog_kelas"},
		{action = "fade", mode = "out", duration = 1},
		{action = "teleport", teleport = "1"},
		{action = "fade", mode = "in", duration = 1},
		{action = "checkpoint", checkpoint_id = "flashback_start"},
		{action = "dialog", dialog_id = "dermaga_welcome"},
		{action = "knowledge_set", value = 37, reason = "Player berhasil menjawab penyambutan turis di dermaga"},
		{action = "fade", mode = "out", duration = 2},
		{action = "minigame", minigame_id = "packing_local_souvenirs", on_success = {knowledge = 51},},
		{action = "fade", mode = "in", duration = 1},
		{action = "dialog", dialog_id = "kapal_intro"},
		{action = "quiz", quiz_id = "ketingting_sentence", on_success = {knowledge = 62},},
		{action = "dialog", dialog_id = "kapal_after_quiz"},
		{action = "fade", mode = "out", duration = 2},
		{action = "teleport", teleport = "3"},
		{action = "fade", mode = "in", duration = 1},
		{action = "dialog", dialog_id = "pulau_arrival"},
		{action = "minigame", minigame_id = "clean_trash", type = "clean", on_success = {knowledge = 71}},
		{action = "fade", mode = "out", duration = 1},
		{action = "dialog", dialog_id = "after_minigame3"},
		{action = "fade", mode = "in", duration = 1},
		{action = "dialog", dialog_id = "ending_kelas"},
		{action = "quiz", quiz_id = "final_chapter_quiz", on_success = {knowledge = 100}},
		{action = "ending", chapter_id = "chapter_1", chapter_name = "Chapter 1"},
	},
}

return chapter
