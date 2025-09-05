return {
  version = "1.1",
  luaversion = "5.1",
  orientation = "orthogonal",
  width = 10,
  height = 10,
  tilewidth = 64,
  tileheight = 64,
  properties = {},
  tilesets = {
    {
      name = "tiles",
      firstgid = 1,
      tilewidth = 64,
      tileheight = 64,
      spacing = 0,
      margin = 0,
      image = "../../../../tools/tiled/dont_starve/tiles.png",
      imagewidth = 512,
      imageheight = 512,
      properties = {},
      tiles = {}
    }
  },
  layers = {
    {
      type = "tilelayer",
      name = "BG_TILES",
      x = 0,
      y = 0,
      width = 10,
      height = 10,
      visible = true,
      opacity = 1,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 1, 1, 1, 1, 1, 0, 0, 0,
        1, 1, 1, 51, 51, 51, 1, 1, 1, 0,
        1, 1, 1, 51, 51, 51, 1, 1, 1, 0,
        1, 1, 51, 51, 51, 51, 51, 1, 1, 1,
        1, 51, 51, 51, 51, 51, 51, 51, 51, 1,
        1, 51, 51, 51, 51, 51, 51, 51, 51, 1,
        1, 51, 51, 51, 51, 51, 51, 51, 51, 1,
        1, 1, 51, 51, 51, 51, 51, 1, 1, 1,
        1, 1, 1, 51, 51, 51, 1, 1, 1, 0,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 0
      }
    },
    {
      type = "objectgroup",
      name = "FG_OBJECTS",
      visible = true,
      opacity = 1,
      properties = {},
      objects = {
        {
          name = "",
          type = "vault_pillar",
          shape = "rectangle",
          x = 90,
          y = 549,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.random"] = ""
          }
        },
        {
          name = "",
          type = "vault_pillar",
          shape = "rectangle",
          x = 481,
          y = 141,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.random"] = ""
          }
        },
        {
          name = "",
          type = "archive_moon_statue",
          shape = "rectangle",
          x = 181,
          y = 458,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "archive_sound_area",
          shape = "rectangle",
          x = 283,
          y = 131,
          width = 82,
          height = 125,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "archive_sound_area",
          shape = "rectangle",
          x = 170,
          y = 402,
          width = 257,
          height = 76,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "oceanwhirlbigportalexit",
          shape = "rectangle",
          x = 179,
          y = 311,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "vault_pillar",
          shape = "rectangle",
          x = 497,
          y = 543,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.random"] = ""
          }
        },
        {
          name = "",
          type = "vault_pillar",
          shape = "rectangle",
          x = 82,
          y = 147,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.random"] = ""
          }
        },
        {
          name = "",
          type = "vault_chandelier_broken",
          shape = "rectangle",
          x = 379,
          y = 302,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "vault_rune",
          shape = "rectangle",
          x = 327,
          y = 531,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "archive_moon_statue",
          shape = "rectangle",
          x = 476,
          y = 384,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "archive_moon_statue",
          shape = "rectangle",
          x = 103,
          y = 375,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "vaultmarker_lobby_center",
          shape = "rectangle",
          x = 288,
          y = 352,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "vaultmarker_lobby_to_vault",
          shape = "rectangle",
          x = 288,
          y = 96,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "vaultmarker_lobby_to_archive",
          shape = "rectangle",
          x = 544,
          y = 352,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "vault_lobby_exit",
          shape = "rectangle",
          x = 544,
          y = 352,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        }
      }
    }
  }
}
