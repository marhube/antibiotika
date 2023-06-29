SET NOCOUNT ON;
--Av en eller annen grunn så ser ikke R (RODBC) ut til å like "USE" statement 
-- og må ha "SET NOCOUNT ON" for å take scripting med hjelpetabeller
--
DROP TABLE IF EXISTS 
#distinkte_relevante_ATC_koder,#grupperte_ATC_koder,#basisuttrekk,#basisuttrekk_brutto_mnd_DDD,#basisuttrekk_dag_DDD,
#hist_fylkesfolketall,#hist_nasjonale_folketall,#tot_dd_pr_dag_ant_innb,#basisuttrekk_inndelingsgrupper
;
--
SELECT DISTINCT atc.ATCNr
INTO #distinkte_relevante_ATC_koder
FROM Grossist_DWH.dbo.DimVareATC atc
WHERE atc.ATCNr LIKE 'J01%' AND atc.ATCNr  <> 'J01XX05' -- Vil ikke ha med metenamin
AND LEN(atc.ATCNr) = 7 -- Får ellers med to rader med kode 'J01'
;
-- DROP TABLE IF EXISTS distinkte_relevante_ATC_koder
-- SELECT TOP 20 * FROM #distinkte_relevante_ATC_koder
--
SELECT atc.ATCNR, '' AS Total,
--
CASE 
	WHEN atc.ATCNr LIKE 'J01A%' THEN 'J01A tetracykliner'
	WHEN atc.ATCNr LIKE 'J01B%' THEN 'J01B amfenikoler'
	WHEN atc.ATCNr LIKE 'J01C%' THEN 'J01C penicilliner'
	WHEN atc.ATCNr LIKE 'J01D%' THEN 'J01D cefalosporiner,monobaktamer og karbapenemer'
	WHEN atc.ATCNr LIKE 'J01E%' THEN 'J01E sulfonamider og trimetoprim'
	WHEN atc.ATCNr LIKE 'J01F%' THEN 'J01F makrolider, lincosamider og streptograminer'
	WHEN atc.ATCNr LIKE 'J01G%' THEN 'J01G aminoglykosider'
	WHEN atc.ATCNr LIKE 'J01M%' THEN 'J01M quinoloner'
	WHEN atc.ATCNr LIKE 'J01X%' THEN 'J01X andre antibakterielle midler '
END AS ATC3,
--
CASE 
	WHEN (
		atc.ATCNr IN ('J01AA02','J01CA04','J01CE02') OR 
		(atc.ATCNr LIKE 'J01FA%' AND atc.ATCNr  <> 'J01FA15'  )
		) THEN 'LVI-AB'
--
	WHEN atc.ATCNr IN ('J01CA08','J01EA01','J01EE01','J01MA01','J01MA02','J01XE01') THEN  'UVI-AB'
	WHEN atc.ATCNr IN ('J01AA04','J01AA06','J01AA07') THEN 'Akne-AB'
	WHEN atc.ATCNr IN ('J01CF01','J01CF02','J01FF01')  THEN  'Hud-AB'
	ELSE 'Andre' 
--
END AS indikasjonsgruppe,
--
CASE 
	WHEN atc.ATCNr IN ('J01CE01','J01CE02') THEN 'smal'
	WHEN (
	atc.ATCNr LIKE 'J01CR%' OR atc.ATCNr LIKE 'J01DC%' OR
	atc.ATCNr LIKE 'J01DD%' OR atc.ATCNr LIKE 'J01DE%' OR
	atc.ATCNr LIKE 'J01DH%' OR atc.ATCNr LIKE 'J01DI%' OR 
	atc.ATCNr LIKE 'J01M%' OR atc.ATCNr LIKE 'J01XA%' OR 
	atc.ATCNr = 'J01XX08'
	) THEN 'bred'
	ELSE 'Andre'
END AS bred_vs_smal
--
INTO #grupperte_ATC_koder
FROM #distinkte_relevante_ATC_koder atc
;
-- DROP TABLE IF EXISTS #grupperte_ATC_koder
-- SELECT TOP 200 * FROM #grupperte_ATC_koder
--
SELECT  fgg.PeriodeId,fgg.VareNr,fgg.Kvantum AS basic_quantity,
gak.ATCNr,atc.ATCNavn,atc.DefDognDose,atc.StatFaktor,
fgg.Kvantum *  atc.StatFaktor / atc.DefDognDose AS tot_DDD
INTO #basisuttrekk
FROM Grossist_DWH.dbo.DimVareATC atc 
INNER JOIN  #grupperte_ATC_koder gak ON
atc.ATCNr = gak.ATCNr 
INNER JOIN Grossist_DWH.dbo.FaktaGrossistGrunnlag fgg ON
fgg.VareNr = atc.VareNr
WHERE atc.VareGruppe IN ('1','2','6')
;
-- DROP TABLE IF EXISTS #basisuttrekk
-- SELECT COUNT(*) FROM #basisuttrekk
-- Gjør så tellinger kun på PeriodeId og ATCNR
-- Memo til selv: Ingen av grupperingene splitter ATCnr
SELECT PeriodeId,ATCNr,SUM(tot_DDD) AS brutto_mnd_DDD
INTO #basisuttrekk_brutto_mnd_DDD
FROM #basisuttrekk
GROUP BY PeriodeId,ATCNr
;
-- DROP TABLE IF EXISTS #basisuttrekk_brutto_mnd_DDD
-- SELECT COUNT(*) AS ant_rader FROM #basisuttrekk_brutto_mnd_DDD

-- SELECT DISTINCT PeriodeId FROM #basisuttrekk_brutto_mnd_DDD ORDER BY PeriodeId
-- Deler så på antall dager i hver måned
-- Memo til selv: Fjerner nå PeriodeId som slutter på "0"
SELECT mnd_ddd.*,dp.AntallDagIMnd,dp.Aar,dp.Maaned,
mnd_ddd.brutto_mnd_DDD/CAST(dp.AntallDagIMnd AS float) AS brutto_daglig_DDD
INTO #basisuttrekk_dag_DDD
FROM #basisuttrekk_brutto_mnd_DDD mnd_ddd
INNER JOIN Grossist_DWH.dbo.DimPeriode  dp ON
mnd_ddd.PeriodeId = dp.PeriodeId
WHERE Maaned > 0
;
-- DROP TABLE IF EXISTS #basisuttrekk_dag_DDD
-- SELECT COUNT(*) AS ant_rader from #basisuttrekk_dag_DDD
-- SELECT TOP 20 * FROM #basisuttrekk_dag_DDD
-- Memo til selv: Trenger folketall fra januar samme år som "start_month"
-- For å få til det så må jeg trekke ut år fra "start_month
-- Trenger ikke PeriodeId, bare Aar

SELECT dp.Aar,fb.FylkeNr,
AntPersoner AS fylke_ant_innb,CAST(AntPersoner AS float) / CAST(1000 AS float) AS fylke_ant_tusen_innb
INTO #hist_fylkesfolketall
FROM Grossist_DWH.dbo.DimPeriode  dp
INNER JOIN Grossist_DWH.dbo.FaktaBefolkning fb ON
dp.PeriodeId = fb.PeriodeId 
WHERE  dp.Maaned = 1
ORDER BY dp.PeriodeId,fb.FylkeNr
;
--
SELECT Aar,SUM(fylke_ant_innb) AS tot_ant_innb,SUM(fylke_ant_tusen_innb) AS tot_ant_tusen_innb
INTO #hist_nasjonale_folketall
FROM #hist_fylkesfolketall
GROUP BY Aar
;
-- DROP TABLE IF EXISTS hist_nasjonale_folketall
SELECT dag_ddd.*,hnf.tot_ant_innb,hnf.tot_ant_tusen_innb,
brutto_daglig_DDD /tot_ant_tusen_innb AS DDD_1000innb_dogn
INTO #tot_dd_pr_dag_ant_innb
FROM #basisuttrekk_dag_DDD dag_ddd
INNER JOIN #hist_nasjonale_folketall hnf
ON dag_ddd.Aar = hnf.Aar
;
-- DROP TABLE IF EXISTS #basisuttrekk_dag_DDD dag_ddd
--  SELECT TOP 20 * FROM #tot_dd_pr_dag_ant_innb
-- Skal så koble på alle grupperingsmulighetene
-- 
SELECT skalert_ddd.*, gak.Total,gak.ATC3,gak.indikasjonsgruppe,gak.bred_vs_smal
INTO #basisuttrekk_inndelingsgrupper
FROM #tot_dd_pr_dag_ant_innb skalert_ddd
INNER JOIN #grupperte_ATC_koder gak ON
skalert_ddd.ATCNr = gak.ATCNr
;
-- DROP TABLE IF EXISTS #basisuttrekk_inndelingsgrupper
-- SELECT COUNT(*) AS ant_rader FROM #basisuttrekk_inndelingsgrupper;
--  SELECT TOP 20 
SET NOCOUNT OFF;
-- Trekker til slutt ut data;
-- DROP TABLE IF EXISTS #tot_dd_pr_dag_ant_innb
SELECT * 
FROM #basisuttrekk_inndelingsgrupper
ORDER BY PeriodeId,ATCNr
;
