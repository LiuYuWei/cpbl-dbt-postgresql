SELECT "id" as id, "name", "year", "game level", "team id", "team name","g", "pa", "ab", "rbi", "r", "h", "1b", "2b", "3b", "hr", "tb", "so", "sb", "gidp", "sh", "sf", "bb", "ibb", "hbp", "cs", "go", "fo",
round("h"::decimal/"ab",3) as "avg",
round(("1b"+(2*"2b")+(3*"3b")+(4*"hr"))::decimal/"ab",3) as "slg",
round(("1b"+(2*"2b")+(3*"3b")+(4*"hr"))::decimal/"ab",3) - round("h"::decimal/"ab",3) as "isop",
round(("h"+"bb"+"hbp")::decimal / ("ab"+"bb"+"hbp"+"sf"),3) as "obp"
	FROM public.battings_cpbl
	WHERE "name"='陳金鋒'
	ORDER by "year"