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
	{	5,	m,	m,	m,	m,	m	},
	m,
	{	m,	m,	m,	m,	3,	3	},
	{	m,	m,	m,	m,	m,	6	},
	{	m,	m,	m,	m,	3,	3	},
	m,
	--
	{	0,	m,	m,	m,	m,	m	},
	m,
	{	m,	m,	m,	3,	3,	3	},
	m,
	{	m,	m,	m,	3,	3,	3	},
	m,
	--
	{	5,	m,	m,	m,	m,	m	},
	m,
	{	m,	m,	m,	m,	3,	3	},
	{	m,	m,	m,	m,	m,	6	},
	{	m,	m,	m,	m,	3,	3	},
	m,
	--
	{	0,	m,	m,	m,	m,	m	},
	m,
	{	m,	m,	m,	3,	3,	3	},
	m,
	{	m,	m,	m,	3,	3,	3	},
	m,
	------------------------------ 2
	{	0,	m,	m,	m,	m,	m	},
	m,
	{	m,	m,	m,	2,	3,	m	},
	{	m,	m,	m,	m,	4,	m	},
	{	m,	m,	m,	2,	3,	m	},
	m,
	--
	{	m,	0,	m,	m,	m,	m	},
	m,
	{	m,	m,	4,	2,	3,	m	},
	m,
	{	m,	m,	4,	2,	3,	m	},
	m,
	--
	{	0,	m,	m,	m,	m,	m	},
	m,
	{	m,	m,	m,	2,	3,	m	},
	{	m,	m,	m,	m,	4,	m	},
	{	m,	m,	m,	2,	3,	m	},
	m,
	--
	{	m,	0,	m,	m,	m,	m	},
	m,
	{	m,	m,	4,	2,	3,	m	},
	m,
	{	m,	m,	4,	2,	3,	m	},
	m,
	------------------------------ 3
	{	m,	3,	m,	m,	m,	m	},
	m,
	{	m,	m,	5,	5,	4,	m	},
	m,
	{	m,	m,	5,	5,	4,	m	},
	m,
	--
	{	5,	m,	m,	m,	m,	m	},
	m,
	{	m,	m,	5,	5,	4,	m	},
	m,
	{	m,	m,	5,	5,	4,	m	},
	m,
	--
	{	m,	1,	m,	m,	m,	m	},
	m,
	{	m,	m,	3,	3,	3,	m	},
	m,
	{	m,	m,	3,	3,	3,	m	},
	m,
	--
	{	3,	m,	m,	m,	m,	m	},
	m,
	{	m,	m,	3,	3,	3,	m	},
	m,
	{	m,	m,	3,	3,	3,	m	},
	m,
	------------------------------ 4
	{	m,	0,	m,	m,	m,	m	},
	m,
	{	m,	m,	4,	2,	3,	m	},
	m,
	{	m,	m,	4,	2,	3,	m	},
	m,
	--
	{	2,	m,	m,	m,	m,	m	},
	m,
	{	m,	m,	4,	2,	4,	m	},
	m,
	{	m,	m,	4,	2,	4,	m	},
	m,
	--
	{	0,	m,	m,	m,	m,	m	},
	m,
	m,
	m,
	m,
	m,
	--
	{	0,	m,	m,	m,	m,	m	}, -- *1
	m,
	m,
	m,
	m,
	m,
	------------------------------
}

-- The track then repeats once...
local duplicate = deepcopy(tab)
for i, v in ipairs(duplicate) do
	table.insert(tab, v)
end

-- ... except for the very last note (*1)
tab[#tab - 5] = m

return { tuning = tuning, transposition = transposition, tab = tab, spacing_multiplier = spacing_multiplier }