-- ReplicatedStorage > module(Folder) > data(Folder) > chapter(Folder) > catalog(ModuleScript)
-- require (chapter_card(ModuleScript), catalog(ModuleScript), chapter_manager(ModuleScript), homepage(LocalScript), main_server(Scriot))
local catalog = {
	chapter_1 = {
		chapter_id = "chapter_1",
		order = 1,

		title = "Chapter 1",
		subtitle = "Menjadi Seorang Tour Guide",

		image = "rbxassetid://12345",

		scene_module = "1_chapter",
		first_sequence = "chapter_start",

		-- Ini kita tandai untuk sistem replay/loop nanti.
		replay_checkpoint = "flashback_start",
	},
}

return catalog