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
		{action = "fade", mode = "in", duration = 1},
		{action = "checkpoint", checkpoint_id = "flashback_start"},

		-- Dialog dengan choices (player akan memilih)
		{action = "dialog", dialog_id = "dermaga_welcome"},

		-- After-choice dialog akan dimainkan otomatis sesuai pilihan player
		{action = "after_choice_dialog"},

		-- Knowledge update SETELAH after-choice dialog
		{action = "knowledge_set", value = 37, reason = "Player berhasil menjawab penyambutan turis di dermaga"},

		-- Minigame dimulai setelah semua dialog selesai
		{action = "minigame", minigame_id = "packing_local_souvenirs", on_success = {knowledge = 51}, on_fail = {knowledge = 30}},
	},
}

return chapter