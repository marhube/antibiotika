SET NOCOUNT ON;
DROP TABLE IF EXISTS 
#distinkte_relevante_ATC_koder,#basisuttrekk
;
--

SELECT DISTINCT atc.ATCNr
INTO #distinkte_relevante_ATC_koder
FROM Grossist_DWH.dbo.DimVareATC atc
WHERE atc.ATCNr LIKE 'J01%' AND atc.ATCNr  <> 'J01XX05' -- Vil ikke ha med metenamin
AND LEN(atc.ATCNr) = 7 -- Får ellers med to rader med kode 'J01'
;
-- SELECT TOP 20 * FROM #distinkte_relevante_ATC_koder
-- Trekker ut tidligste måned
SELECT  DISTINCT fgg.PeriodeId AS distinkte_mnd
INTO #basisuttrekk
FROM Grossist_DWH.dbo.DimVareATC atc 
INNER JOIN  #distinkte_relevante_ATC_koder  drak ON
atc.ATCNr = drak.ATCNr 
INNER JOIN Grossist_DWH.dbo.FaktaGrossistGrunnlag fgg ON
fgg.VareNr = atc.VareNr
WHERE atc.VareGruppe IN ('1','2','6')
;
-- DROP TABLE IF EXISTS #basisuttrekk
-- SELECT TOP 200 *  FROM #basisuttrekk ORDER BY distinkte_mnd;
SET NOCOUNT OFF;
-- Trekker til slutt ut data;
-- DROP TABLE IF EXISTS #tot_dd_pr_dag_ant_innb
SELECT * 
FROM #basisuttrekk 
ORDER BY distinkte_mnd
;