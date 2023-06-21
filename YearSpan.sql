SET NOCOUNT ON;
DROP TABLE IF EXISTS #distinkte_relevante_ATC_koder,#distinkte_perioder,#distinkte_aar
;
--
SELECT DISTINCT atc.ATCNr
INTO #distinkte_relevante_ATC_koder
FROM Grossist_DWH.dbo.DimVareATC atc
WHERE atc.ATCNr LIKE 'J01%' AND atc.ATCNr  <> 'J01XX05' -- Vil ikke ha med metenamin
AND LEN(atc.ATCNr) = 7 -- Får ellers med to rader med kode 'J01'
;
-- SELECT TOP 20 * FROM #distinkte_relevante_ATC_koder
-- Memo til selv:For å finne tidligste hele kalenderår med dat trekkes det ut "tidligste januarmåned" .
SELECT  DISTINCT fgg.PeriodeId AS distinkte_PeriodeId,
CAST(FLOOR(fgg.PeriodeId/100) AS int) AS aar
INTO #distinkte_perioder
FROM Grossist_DWH.dbo.DimVareATC atc 
INNER JOIN  #distinkte_relevante_ATC_koder  drak ON
atc.ATCNr = drak.ATCNr 
INNER JOIN Grossist_DWH.dbo.FaktaGrossistGrunnlag fgg ON
fgg.VareNr = atc.VareNr
-- Memo til selv: Modulus 100 gir "månedsdelen" av Period
WHERE atc.VareGruppe IN ('1','2','6') AND fgg.PeriodeId % 100  IN (1,12)
;
-- DROP TABLE IF EXISTS #distinkte_perioder
-- SELECT TOP 20 *  FROM #distinkte_perioder;
--  For å få alle årene med hele kalenderår med data gjør jeg en inner join mellom januarmåneder og desembermåneder med like år
--
SELECT dp1.aar
INTO #distinkte_aar
FROM #distinkte_perioder dp1 
INNER JOIN #distinkte_perioder dp2 ON
dp1.aar = dp2.aar
WHERE (dp1.distinkte_PeriodeId % 100 = 1) AND  (dp2.distinkte_PeriodeId % 100 = 12)
ORDER BY dp1.aar
;

SET NOCOUNT OFF;
-- Trekker til slutt ut data;
-- DROP TABLE IF EXISTS #tot_dd_pr_dag_ant_innb
SELECT *
FROM #distinkte_aar
ORDER BY aar
;