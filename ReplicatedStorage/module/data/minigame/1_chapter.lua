-- ReplicatedStorage > module(Folder) > data(Folder) > minigame(Folder) > 1_chapter(ModuleScript)
local minigame = {
	packing_local_souvenirs = {
		minigame_id = "packing_local_souvenirs",
		type = "packing_souvenir",

		title = "Packing the Local Souvenirs",
		mission = "Pilih produk lokal asli Bontang lalu cocokkan dengan deskripsi bahasa Inggris yang tepat.",

		required_correct = 3,

		products = {
			{
				product_id = "sambal_gami",
				name = "Sambal Gami Kemasan",
				image = "rbxassetid://87038616722688",
				is_correct_product = true,
				description_id = "desc_sambal_gami",
			},
			{
				product_id = "batik_kuntul_perak",
				name = "Batik Kuntul Perak",
				image = "rbxassetid://126392312306515",
				is_correct_product = true,
				description_id = "desc_batik",
			},
			{
				product_id = "amplang_ikan",
				name = "Amplang Ikan",
				image = "rbxassetid://90522691248087",
				is_correct_product = true,
				description_id = "desc_amplang",
			},
			{
				product_id = "random_1",
				name = "Produk Random",
				image = "rbxassetid://94353162856308",
				is_correct_product = false,
			},

			{
				product_id = "random_2",
				name = "Produk Random",
				image = "rbxassetid://87888366647027",
				is_correct_product = false,
			},
			{
				product_id = "random_3",
				name = "Produk Random",
				image = "rbxassetid://90720194418699",
				is_correct_product = false,
			},

			{
				product_id = "random_4",
				name = "Produk Random",
				image = "rbxassetid://125790803088540",
				is_correct_product = false,
			},
			{
				product_id = "random_5",
				name = "Produk Random",
				image = "rbxassetid://120457306281594",
				is_correct_product = false,
			},
			{
				product_id = "random_6",
				name = "Produk Random",
				image = "rbxassetid://90604918413839",
				is_correct_product = false,
			},

			{
				product_id = "random_7",
				name = "Produk Random",
				image = "rbxassetid://110208239221823",
				is_correct_product = false,
			},
			{
				product_id = "random_8",
				name = "Produk Random",
				image = "rbxassetid://138078324451174",
				is_correct_product = false,
			},
			{
				product_id = "random_9",
				name = "Produk Random",
				image = "rbxassetid://132436912317819",
				is_correct_product = false,
			},
		},

		descriptions = {
			{
				description_id = "desc_batik",
				name = "Batik Kuntul Perak",
				text = "Batik fabric featuring the iconic egret bird motif of Bontang.",
			},
			{
				description_id = "desc_amplang",
				name = "Amplang Ikan",
				text = "Savory and crunchy fish crackers made from fresh local catch.",
			},
			{
				description_id = "desc_sambal_gami",
				name = "Sambal Gami Kemasan",
				text = "Bontang's legendary chili paste, now packed safely for travel.",
			},
		},
	},
}

return minigame