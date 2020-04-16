local m = -1

---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------

-- Standard tuning:			E2, A2, D3, G3, B3, E4
local tuning =			{	29,	34,	39,	44,	48,	53	}

-- Transpose 8 semitones to bring it within the semitone range
-- of the shells' sounds (C3 - B5).
local transposition = 8

local spacing_multiplier = 0.75

local tab =
{
	--	E	A	D	G	B	e
	------------------------------ 1
	m,
	m,
	m,
	m,
	m,
	m,
	--
	m,
	m,
	m,
	m,
	m,
	m,
	--
	m,
	m,
	m,
	m,
	m,
	m,
	--
	m,
	m,
	m,
	m,
	m,
	m,
	------------------------------ 2
	m,
	m,
	m,
	m,
	m,
	m,
	--
	m,
	m,
	m,
	m,
	m,
	m,
	--
	m,
	m,
	m,
	m,
	m,
	m,
	--
	m,
	m,
	m,
	m,
	m,
	m,
	------------------------------ 3
	{	m,	m,	m,	m,	1,	m	},
	m,
	m,
	m,
	m,
	m,
	--
	{	m,	m,	m,	m,	3,	m	},
	m,
	m,
	m,
	m,
	m,
	--
	{	m,	m,	m,	m,	4,	m	},
	m,
	m,
	m,
	m,
	m,
	--
	{	m,	m,	m,	m,	3,	m	},
	m,
	m,
	m,
	m,
	m,
	------------------------------ 4
	{	m,	m,	m,	2,	m,	m	},
	m,
	{	m,	m,	m,	3,	m,	m	},
	m,
	m,
	m,
	--
	{	m,	m,	m,	2,	m,	m	},
	m,
	m,
	m,
	m,
	m,
	--
	{	m,	m,	m,	m,	3,	m	},
	m,
	m,
	m,
	{	m,	m,	m,	m,	4,	m	},
	m,
	--
	{	m,	m,	m,	m,	3,	m	},
	m,
	m,
	m,
	m,
	m,
	------------------------------ 5
	m,
	m,
	{	m,	m,	m,	m,	11,	m	},
	m,
	{	m,	m,	m,	m,	10,	m	},
	m,
	--
	{	m,	m,	m,	m,	m,	10	},
	m,
	{	m,	m,	m,	m,	m,	11	},
	m,
	{	m,	m,	m,	m,	m,	--[[13]]m	}, -- *1
	m,
	--
	{	m,	m,	m,	m,	m,	11	},
	m,
	m,
	m,
	{	m,	m,	m,	m,	m,	10	},
	m,
	--
	{	m,	m,	m,	m,	10,	m	},
	m,
	m,
	m,
	{	m,	m,	m,	m,	11,	m	},
	m,
	------------------------------ 6
	m,
	m,
	{	m,	m,	m,	m,	13,	m	},
	m,
	m,
	m,
	--
	{	m,	m,	m,	m,	m,	9	},
	m,
	m,
	m,
	{	m,	m,	m,	m,	11,	m	},
	m,
	--
	{	m,	m,	m,	m,	10,	m	},
	m,
	m,
	m,
	m,
	m,
	--
	m,
	m,
	m,
	m,
	m,
	m,
	------------------------------ 7
	{	m,	m,	m,	m,	11,	m	},
	m,
	m,
	m,
	{	m,	m,	m,	m,	10,	m	},
	m,
	--
	{	m,	m,	m,	11,	m,	m	},
	m,
	m,
	m,
	{	m,	m,	m,	12,	m,	m	},
	m,
	--
	m,
	m,
	{	m,	m,	13,	m,	m,	m	},
	m,
	{	m,	m,	12,	m,	m,	m	},
	m,
	--
	m,
	m,
	{	m,	m,	13,	m,	m,	m	},
	m,
	{	m,	m,	12,	m,	m,	m	},
	m,
	------------------------------ 8
	{	m,	m,	11,	m,	m,	m	},
	m,
	m,
	m,
	{	m,	m,	12,	m,	m,	m	},
	m,
	--
	{	m,	m,	13,	m,	m,	m	},
	m,
	m,
	m,
	{	m,	m,	m,	10,	m,	m	},
	m,
	--
	{	m,	m,	m,	11,	m,	m	},
	m,
	m,
	m,
	m,
	m,
	--
	m,
	m,
	m,
	m,
	m,
	m,
	------------------------------
}

-- *1:	The tonal range between the highest and lowest
--		notes of this track (E2 and F5) is a total of 37
--		semitones. The range of the shells is three
--		octaves / 36 semitones, meaning we have to omit
--		either the highest or lowest note to make the
--		track fit regardless of transposition.

return { tuning = tuning, transposition = transposition, tab = tab, spacing_multiplier = spacing_multiplier }