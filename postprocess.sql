WITH cumsum AS (
  SELECT id,
         (UPPER(falls) - rise) AS delta,
         (SUM(UPPER(falls) - rise) OVER (PARTITION BY loc_id ORDER BY rise ASC)) AS unix,
         (SUM(UPPER(falls) - rise) OVER (PARTITION BY loc_id, year ORDER BY rise ASC)) AS yearly
  FROM suns
) UPDATE suns SET unix_cumsum = ivlrange(cumsum.unix - cumsum.delta, cumsum.unix, '[]'), year_cumsum = ivlrange(cumsum.yearly - delta, cumsum.yearly, '[]')
  FROM cumsum
  WHERE cumsum.id = suns.id;

CREATE OR REPLACE FUNCTION sun_day(INTERVAL) RETURNS INTERVAL
  AS 'SELECT DATE_TRUNC(''hour'', $1 / 12) * 12;'
  LANGUAGE SQL
  IMMUTABLE
  RETURNS NULL ON NULL INPUT;
INSERT INTO unix_day_bases (sun_day, loc_id, ba
  se)
  SELECT sun_day_top, loc_id, rise + sun_day_top - LOWER(st0.unix_cumsum) FROM (
    SELECT s.*, sun_day(UPPER(s.unix_cumsum)) AS sun_day_top, sun_day(LOWER(s.unix_cumsum)) AS sun_day_bot FROM suns s
  ) st0
  WHERE st0.sun_day_top > st0.sun_day_bot
  ON CONFLICT (sun_day, loc_id) DO NOTHING;
INSERT INTO unix_day_bases (sun_day, loc_id, ba
  se)
  SELECT sun_day_top, loc_id, rise + sun_day_top - LOWER(st0.unix_cumsum) FROM (
    SELECT s.*, sun_day(UPPER(s.unix_cumsum)) - '12h' AS sun_day_top, sun_day(LOWER(s.unix_cumsum)) AS sun_day_bot FROM suns s
  ) st0
  WHERE st0.sun_day_top > st0.sun_day_bot
  ON CONFLICT (sun_day, loc_id) DO NOTHING;
  
-- correct for bug in astral where the noon zenith check on places on the edge of 24h night makes them considered "24h day"; i.e. do the season check
UPDATE suns SET rise = UPPER(falls) WHERE UPPER(falls) - rise = '24h' AND (loc_id < 32 AND EXTRACT(DOY FROM rise)::INT4 <@ int4range(91, 274)) OR (loc_id >= 32 AND NOT (EXTRACT(DOY FROM rise)::INT4 <@ int4range(91, 274)));