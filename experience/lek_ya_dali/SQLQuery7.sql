USE [ALPHA_BULK]
GO
/****** Object:  StoredProcedure [dbo].[SP_GET_CLAIM_FLAT_FILE_NEW]    Script Date: 04/12/2019 16:04:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE[dbo].[SP_GET_CLAIM_FLAT_FILE_NEW]
	-- Add the parameters for the stored procedure here
	 @inOmegaBookingFlateFile  nvarchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Company  nvarchar(50);
	DECLARE @Intermiary  nvarchar(50);
	DECLARE @Payee  nvarchar(50);
	DECLARE @Key  nvarchar(50);
	DECLARE @DocumentDate  nvarchar(50);
	DECLARE @REB  nvarchar(50);	
	DECLARE @Remark  nvarchar(50);
	DECLARE @Setlmment  nvarchar(50);
	DECLARE @Country  nvarchar(50);
	

	select	@Company = FAP.FAP_COMPANY,
			@Intermiary = FAP_INTERMEDIARY, 
			@Payee = FAP.FAP_PAYEE,
			@Key = 'A',
			@DocumentDate = null , -- BI.BDXIMP_RECEIVED_DATE,
			@REB = null,
			@Remark = null,
			@Setlmment = null,
			@Country = null

	from  CLAIM_OMEGA_BOOKING_FLAT_FILE as COBFF
	inner join CLAIM_BORDEREAUX_CONTROLS as CBC
	on COBFF.COBFF_CBC_ID = CBC.CBC_ID
	inner join BORDEREAUX_IMPORT as BI
	on BI.BDXIMP_ID = CBC.CBC_BDXIMP_ID
	inner join TPA_FACILITIES as TF
	on TF.FACI_ID = BI.BDXIMP_FACI_ID
	inner join FACILITIES_APPROUVED_PROGRAM as FAP
	on FAP.FAP_FAC_ID = TF.FACI_ID and BI.BDXIMP_PR_ID = FAP.FAP_PR_ID
	where COBFF.COBFF_ID =  @inOmegaBookingFlateFile

	DECLARE @bordereauxId as int;
	set @bordereauxId = (select top 1 CBC.CBC_BDXIMP_ID from CLAIM_BORDEREAUX_CONTROLS as CBC
													inner join Claim_OMEGA_BOOKING_FLAT_FILE as COBFF
													on COBFF.COBFF_CBC_ID = CBC.CBC_ID
													where COBFF.COBFF_ID = @inOmegaBookingFlateFile)

	if @bordereauxId is not null
	EXEC	[dbo].[SET_FLATE_FILE_UPDATE_TRANSACTION_CLAIM]
						@inBordereauxId = @bordereauxId;

	DECLARE	@return_value int

	EXEC	@return_value =[dbo].[SP_GET_CLAIM_FLAT_FILE_CREATION]
		@inOmegaBookingFlateFile =@inOmegaBookingFlateFile

	select
			OTN.OTN_TREATY_NUMBER AS omegaTreatyNumber,
			COBFFT.COFFT_UWY AS omffUwy,
			[OMFF_ENDORSEMENT_NUMBER] AS omffNt,
			[COFFT_NT] AS  omffEndorsementNumber,
			OS.OSEC_NUMBER AS omegaSection,
			[COFFT_PRMLIN_IN] AS omffPrmlinIn,
			[COFFT_TRANSACTION_CODE] AS omffTransactionCode,
			[COFFT_ACCOUNTING_YEAR]  AS omffAccountingYear,
			[COFFT_BEGINING_PERIOD] AS omffBeginingPeriod,
			[COFFT_END_PERIODE] AS omffEndPeriode,
			[COFFT_OCCURENCE_YEAR]  AS omffOccurenceYear,
			[COFFT_CURRENCY] AS omffCurrency,
			[COFFT_SIGNED_AMOUNT] AS omffSignedAmount,
			[COFFT_OSEC_ID] AS sectionId,
			@Company AS company,
			@Intermiary AS intermediary, 
			@Payee AS payee,
			@Key AS [key],
			@DocumentDate AS [documentDate],
			@REB AS reb ,
			@Remark AS remark,
			@Setlmment AS settlement,
			@Country AS country

	from [CLAIM_OMEGA_FLAT_FILE_TRANSACTIONS]  COBFFT
	inner join OMEGA_TREATY_NUMBER as OTN 
	on OTN.OTN_ID =  COBFFT.COFFT_OTN_ID
	inner join OMEGA_SECTION as OS
	on OS.OSEC_ID = COBFFT.COFFT_OSEC_ID

	where COBFFT.[COFFT_COBFF_ID] = @inOmegaBookingFlateFile
	-----	Transaction 11200000 
	----------------------
	--		----
	--		--  Claim transaction
	--		---
	--SELECT 
	--		LTRIM(RTRIM(OTN.OTN_TREATY_NUMBER)) AS omegaTreatyNumber,
	--		[dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ) AS omffUwy,
	--		1 AS omffNt,
	--		0 AS  omffEndorsementNumber,
	--		SEC.OSEC_NUMBER AS omegaSection,
	--		1 AS omffPrmlinIn,
	--		'11200000' AS omffTransactionCode,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,1,4)  AS omffAccountingYear,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffBeginingPeriod,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffEndPeriode,
	--		SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4)  AS omffOccurenceYear,
	--		CT.CLTR_ORIGINAL_CURRENCY AS omffCurrency,
	--		SUM(CT.CLTR_PAID_THIS_MONTH_INDEMNITY) AS omffSignedAmount,
	--		SEC.OSEC_ID AS SectionId
	-- FROM [dbo].CLAIM_TRANSACTIONS  AS CT
	--	inner join BORDEREAUX_IMPORT as BI
	--	on BI.BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_BORDEREAUX_CONTROLS as CBC
	--	on CBC.CBC_BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_OMEGA_BOOKING_FLAT_FILE as COBFF
	--	on COBFF.COBFF_CBC_ID = CBC.CBC_ID 
	--	inner join CLAIM_MASTER as CM
	--	on CM.CLM_ID = CT.CLTR_CLM_ID
	--	inner join POLICY_MASTER as PM
	--	on PM.POL_ID = CM.CLM_POL_ID and CT.CLTR_ORIGINAL_CURRENCY = COBFF.COBFF_CURRENCY and PM.POL_INSURING_COMPANY_ID = COBFF.[COBFF_INSURING_COMPANY_ID]
	--	INNER JOIN [dbo].OMEGA_SECTION AS SEC
	--	ON SEC.OSEC_ID = CT.CLTR_SECTION_ID
	--	INNER JOIN [dbo].OMEGA_TREATY_NUMBER AS OTN
	--	ON OTN.OTN_ID = SEC.OSEC_OTN_ID
	--	WHERE (COBFF.COBFF_ID  = @inOmegaBookingFlateFile )
	--	and CT.CLTR_SECTION_ID is not null 

	--GROUP BY OTN.OTN_TREATY_NUMBER, [dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ), SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4), SEC.OSEC_NUMBER , SEC.OSEC_ID, BI.[BDXIMP_REPORTING_DATE], SEC.OSEC_NUMBER, CT.CLTR_ORIGINAL_CURRENCY
		

	--		----
	--		--  claim transaction dimension
	--		---
	--UNION ALL

	
	--SELECT 
	--		LTRIM(RTRIM(OTN.OTN_TREATY_NUMBER)) AS omegaTreatyNumber,
	--		[dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ) AS omffUwy,
	--		1 AS omffNt,
	--		0 AS  omffEndorsementNumber,
	--		SEC.OSEC_NUMBER AS omegaSection,
	--		1 AS omffPrmlinIn,
	--		'11200000' AS omffTransactionCode,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,1,4)  AS omffAccountingYear,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffBeginingPeriod,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffEndPeriode,
	--		SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4)  AS omffOccurenceYear,
	--		CT.CLTR_ORIGINAL_CURRENCY AS omffCurrency,
	--		SUM(CTD.CTD_PAID_THIS_MONTH_INDEMNITY) AS omffSignedAmount,
	--		SEC.OSEC_ID AS SectionId
	-- FROM [dbo].CLAIM_TRANSACTIONS  AS CT
	--	inner join CLAIM_TRANSACTIONS_DIMENSIONS as CTD
	--	ON CTD.CTD_CLTR_ID = CT.CLTR_ID
	--	inner join BORDEREAUX_IMPORT as BI
	--	on BI.BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_BORDEREAUX_CONTROLS as CBC
	--	on CBC.CBC_BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_OMEGA_BOOKING_FLAT_FILE as COBFF
	--	on COBFF.COBFF_CBC_ID = CBC.CBC_ID 
	--	inner join CLAIM_MASTER as CM
	--	on CM.CLM_ID = CT.CLTR_CLM_ID
	--	inner join POLICY_MASTER as PM
	--	on PM.POL_ID = CM.CLM_POL_ID and CT.CLTR_ORIGINAL_CURRENCY = COBFF.COBFF_CURRENCY and PM.POL_INSURING_COMPANY_ID = COBFF.[COBFF_INSURING_COMPANY_ID]
	--	INNER JOIN [dbo].OMEGA_SECTION AS SEC
	--	ON SEC.OSEC_ID = CTD.CTD_SECTION_ID
	--	INNER JOIN [dbo].OMEGA_TREATY_NUMBER AS OTN
	--	ON OTN.OTN_ID = SEC.OSEC_OTN_ID
	--	WHERE (COBFF.COBFF_ID  = @inOmegaBookingFlateFile)
	--	and CTD.CTD_SECTION_ID is not null 

	--GROUP BY OTN.OTN_TREATY_NUMBER, [dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ), SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4), SEC.OSEC_NUMBER , SEC.OSEC_ID, BI.[BDXIMP_REPORTING_DATE], SEC.OSEC_NUMBER, CT.CLTR_ORIGINAL_CURRENCY
		
	--UNION ALL

	----------------------
	-----	Transaction 11200500 
	----------------------
	--		----
	--		--  Claim transaction
	--		---
	--SELECT 
	--		LTRIM(RTRIM(OTN.OTN_TREATY_NUMBER)) AS omegaTreatyNumber,
	--		[dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ) AS omffUwy,
	--		1 AS omffNt,
	--		0 AS  omffEndorsementNumber,
	--		SEC.OSEC_NUMBER AS omegaSection,
	--		1 AS omffPrmlinIn,
	--		'11200500' AS omffTransactionCode,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,1,4)  AS omffAccountingYear,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffBeginingPeriod,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffEndPeriode,
	--		SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4)  AS omffOccurenceYear,
	--		CT.CLTR_ORIGINAL_CURRENCY AS omffCurrency,
	--		SUM(CT.CLTR_PAID_THIS_MONTH_FEES) AS omffSignedAmount,
	--		SEC.OSEC_ID AS SectionId
	-- FROM [dbo].CLAIM_TRANSACTIONS  AS CT
	--	inner join BORDEREAUX_IMPORT as BI
	--	on BI.BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_BORDEREAUX_CONTROLS as CBC
	--	on CBC.CBC_BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_OMEGA_BOOKING_FLAT_FILE as COBFF
	--	on COBFF.COBFF_CBC_ID = CBC.CBC_ID 
	--	inner join CLAIM_MASTER as CM
	--	on CM.CLM_ID = CT.CLTR_CLM_ID
	--	inner join POLICY_MASTER as PM
	--	on PM.POL_ID = CM.CLM_POL_ID and CT.CLTR_ORIGINAL_CURRENCY = COBFF.COBFF_CURRENCY and PM.POL_INSURING_COMPANY_ID = COBFF.[COBFF_INSURING_COMPANY_ID]
	--	INNER JOIN [dbo].OMEGA_SECTION AS SEC
	--	ON SEC.OSEC_ID = CT.CLTR_SECTION_ID
	--	INNER JOIN [dbo].OMEGA_TREATY_NUMBER AS OTN
	--	ON OTN.OTN_ID = SEC.OSEC_OTN_ID
	--	WHERE (COBFF.COBFF_ID  = @inOmegaBookingFlateFile )
	--	and CT.CLTR_SECTION_ID is not null 

	--GROUP BY OTN.OTN_TREATY_NUMBER, [dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ),SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4), SEC.OSEC_NUMBER , SEC.OSEC_ID, BI.[BDXIMP_REPORTING_DATE], SEC.OSEC_NUMBER, CT.CLTR_ORIGINAL_CURRENCY
		

	--		----
	--		--  claim transaction dimension
	--		---
	--UNION ALL

	
	--SELECT 
	--		LTRIM(RTRIM(OTN.OTN_TREATY_NUMBER)) AS omegaTreatyNumber,
	--		[dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ) AS omffUwy,
	--		1 AS omffNt,
	--		0 AS  omffEndorsementNumber,
	--		SEC.OSEC_NUMBER AS omegaSection,
	--		1 AS omffPrmlinIn,
	--		'11200500' AS omffTransactionCode,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,1,4)  AS omffAccountingYear,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffBeginingPeriod,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffEndPeriode,
	--		SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4)  AS omffOccurenceYear,
	--		CT.CLTR_ORIGINAL_CURRENCY AS omffCurrency,
	--		SUM(CTD.CTD_PAID_THIS_MONTH_FEES) AS omffSignedAmount,
	--		SEC.OSEC_ID AS SectionId
	-- FROM [dbo].CLAIM_TRANSACTIONS  AS CT
	--	inner join CLAIM_TRANSACTIONS_DIMENSIONS as CTD
	--	ON CTD.CTD_CLTR_ID = CT.CLTR_ID
	--	inner join BORDEREAUX_IMPORT as BI
	--	on BI.BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_BORDEREAUX_CONTROLS as CBC
	--	on CBC.CBC_BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_OMEGA_BOOKING_FLAT_FILE as COBFF
	--	on COBFF.COBFF_CBC_ID = CBC.CBC_ID 
	--	inner join CLAIM_MASTER as CM
	--	on CM.CLM_ID = CT.CLTR_CLM_ID
	--	inner join POLICY_MASTER as PM
	--	on PM.POL_ID = CM.CLM_POL_ID and CT.CLTR_ORIGINAL_CURRENCY = COBFF.COBFF_CURRENCY and PM.POL_INSURING_COMPANY_ID = COBFF.[COBFF_INSURING_COMPANY_ID]
	--	INNER JOIN [dbo].OMEGA_SECTION AS SEC
	--	ON SEC.OSEC_ID = CTD.CTD_SECTION_ID
	--	INNER JOIN [dbo].OMEGA_TREATY_NUMBER AS OTN
	--	ON OTN.OTN_ID = SEC.OSEC_OTN_ID
	--	WHERE (COBFF.COBFF_ID  = @inOmegaBookingFlateFile )
	--	and CTD.CTD_SECTION_ID is not null 

	--GROUP BY OTN.OTN_TREATY_NUMBER, [dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ),SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4), SEC.OSEC_NUMBER , SEC.OSEC_ID, BI.[BDXIMP_REPORTING_DATE], SEC.OSEC_NUMBER, CT.CLTR_ORIGINAL_CURRENCY
		
	--	UNION ALL

	----------------------
	-----	Transaction 11200400 
	----------------------
	--		----
	--		--  Claim transaction
	--		---
	--SELECT 
	--		LTRIM(RTRIM(OTN.OTN_TREATY_NUMBER)) AS omegaTreatyNumber,
	--		[dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ) AS omffUwy,
	--		1 AS omffNt,
	--		0 AS  omffEndorsementNumber,
	--		SEC.OSEC_NUMBER AS omegaSection,
	--		1 AS omffPrmlinIn,
	--		'11200400' AS omffTransactionCode,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,1,4)  AS omffAccountingYear,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffBeginingPeriod,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffEndPeriode,
	--		SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4)  AS omffOccurenceYear,
	--		CT.CLTR_ORIGINAL_CURRENCY AS omffCurrency,
	--		SUM(CT.CLTR_SUBROGATION_AND_SALVAGE) AS omffSignedAmount,
	--		SEC.OSEC_ID AS SectionId
	-- FROM [dbo].CLAIM_TRANSACTIONS  AS CT
	--	inner join BORDEREAUX_IMPORT as BI
	--	on BI.BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_BORDEREAUX_CONTROLS as CBC
	--	on CBC.CBC_BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_OMEGA_BOOKING_FLAT_FILE as COBFF
	--	on COBFF.COBFF_CBC_ID = CBC.CBC_ID 
	--	inner join CLAIM_MASTER as CM
	--	on CM.CLM_ID = CT.CLTR_CLM_ID
	--	inner join POLICY_MASTER as PM
	--	on PM.POL_ID = CM.CLM_POL_ID and CT.CLTR_ORIGINAL_CURRENCY = COBFF.COBFF_CURRENCY and PM.POL_INSURING_COMPANY_ID = COBFF.[COBFF_INSURING_COMPANY_ID]
	--	INNER JOIN [dbo].OMEGA_SECTION AS SEC
	--	ON SEC.OSEC_ID = CT.CLTR_SECTION_ID
	--	INNER JOIN [dbo].OMEGA_TREATY_NUMBER AS OTN
	--	ON OTN.OTN_ID = SEC.OSEC_OTN_ID
	--	WHERE (COBFF.COBFF_ID  = @inOmegaBookingFlateFile )
	--	and CT.CLTR_SECTION_ID is not null 

	--GROUP BY OTN.OTN_TREATY_NUMBER, [dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ), SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4), SEC.OSEC_NUMBER , SEC.OSEC_ID, BI.[BDXIMP_REPORTING_DATE], SEC.OSEC_NUMBER, CT.CLTR_ORIGINAL_CURRENCY
		

	--		----
	--		--  claim transaction dimension
	--		---
	--UNION ALL

	
	--SELECT 
	--		LTRIM(RTRIM(OTN.OTN_TREATY_NUMBER)) AS omegaTreatyNumber,
	--		[dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ) AS omffUwy,
	--		1 AS omffNt,
	--		0 AS  omffEndorsementNumber,
	--		SEC.OSEC_NUMBER AS omegaSection,
	--		1 AS omffPrmlinIn,
	--		'11200400' AS omffTransactionCode,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,1,4)  AS omffAccountingYear,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffBeginingPeriod,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffEndPeriode,
	--		SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4)  AS omffOccurenceYear,
	--		CT.CLTR_ORIGINAL_CURRENCY AS omffCurrency,
	--		SUM(CTD.CTD_SUBROGATION_AND_SALVAGE) AS omffSignedAmount,
	--		SEC.OSEC_ID AS SectionId
	-- FROM [dbo].CLAIM_TRANSACTIONS  AS CT
	--	inner join CLAIM_TRANSACTIONS_DIMENSIONS as CTD
	--	ON CTD.CTD_CLTR_ID = CT.CLTR_ID
	--	inner join BORDEREAUX_IMPORT as BI
	--	on BI.BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_BORDEREAUX_CONTROLS as CBC
	--	on CBC.CBC_BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_OMEGA_BOOKING_FLAT_FILE as COBFF
	--	on COBFF.COBFF_CBC_ID = CBC.CBC_ID 
	--	inner join CLAIM_MASTER as CM
	--	on CM.CLM_ID = CT.CLTR_CLM_ID
	--	inner join POLICY_MASTER as PM
	--	on PM.POL_ID = CM.CLM_POL_ID and CT.CLTR_ORIGINAL_CURRENCY = COBFF.COBFF_CURRENCY and PM.POL_INSURING_COMPANY_ID = COBFF.[COBFF_INSURING_COMPANY_ID]
	--	INNER JOIN [dbo].OMEGA_SECTION AS SEC
	--	ON SEC.OSEC_ID = CTD.CTD_SECTION_ID
	--	INNER JOIN [dbo].OMEGA_TREATY_NUMBER AS OTN
	--	ON OTN.OTN_ID = SEC.OSEC_OTN_ID
	--	WHERE (COBFF.COBFF_ID  = @inOmegaBookingFlateFile )
	--	and CTD.CTD_SECTION_ID is not null 

	--GROUP BY OTN.OTN_TREATY_NUMBER, [dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ), SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4), SEC.OSEC_NUMBER , SEC.OSEC_ID, BI.[BDXIMP_REPORTING_DATE], SEC.OSEC_NUMBER, CT.CLTR_ORIGINAL_CURRENCY
		
	--	UNION ALL

	----------------------
	-----	Transaction 11420000 
	----------------------
	--		----
	--		--  Claim transaction
	--		---
	--SELECT 
	--		LTRIM(RTRIM(OTN.OTN_TREATY_NUMBER)) AS omegaTreatyNumber,
	--		[dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ) AS omffUwy,
	--		1 AS omffNt,
	--		0 AS  omffEndorsementNumber,
	--		SEC.OSEC_NUMBER AS omegaSection,
	--		1 AS omffPrmlinIn,
	--		'11420000' AS omffTransactionCode,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,1,4)  AS omffAccountingYear,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffBeginingPeriod,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffEndPeriode,
	--		SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4)  AS omffOccurenceYear,
	--		CT.CLTR_ORIGINAL_CURRENCY AS omffCurrency,
	--		SUM(CT.CLTR_RESERVE_INDEMNITY) AS omffSignedAmount,
	--		SEC.OSEC_ID AS SectionId
	-- FROM [dbo].CLAIM_TRANSACTIONS  AS CT
	--	inner join BORDEREAUX_IMPORT as BI
	--	on BI.BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_BORDEREAUX_CONTROLS as CBC
	--	on CBC.CBC_BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_OMEGA_BOOKING_FLAT_FILE as COBFF
	--	on COBFF.COBFF_CBC_ID = CBC.CBC_ID 
	--	inner join CLAIM_MASTER as CM
	--	on CM.CLM_ID = CT.CLTR_CLM_ID
	--	inner join POLICY_MASTER as PM
	--	on PM.POL_ID = CM.CLM_POL_ID and CT.CLTR_ORIGINAL_CURRENCY = COBFF.COBFF_CURRENCY and PM.POL_INSURING_COMPANY_ID = COBFF.[COBFF_INSURING_COMPANY_ID]
	--	INNER JOIN [dbo].OMEGA_SECTION AS SEC
	--	ON SEC.OSEC_ID = CT.CLTR_SECTION_ID
	--	INNER JOIN [dbo].OMEGA_TREATY_NUMBER AS OTN
	--	ON OTN.OTN_ID = SEC.OSEC_OTN_ID
	--	WHERE (COBFF.COBFF_ID  = @inOmegaBookingFlateFile )
	--	and CT.CLTR_SECTION_ID is not null 

	--GROUP BY OTN.OTN_TREATY_NUMBER, [dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ), SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4), SEC.OSEC_NUMBER , SEC.OSEC_ID, BI.[BDXIMP_REPORTING_DATE], SEC.OSEC_NUMBER, CT.CLTR_ORIGINAL_CURRENCY
		

	--		----
	--		--  claim transaction dimension
	--		---
	--UNION ALL

	
	--SELECT 
	--		LTRIM(RTRIM(OTN.OTN_TREATY_NUMBER)) AS omegaTreatyNumber,
	--		[dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ) AS omffUwy,
	--		1 AS omffNt,
	--		0 AS  omffEndorsementNumber,
	--		SEC.OSEC_NUMBER AS omegaSection,
	--		1 AS omffPrmlinIn,
	--		'11420000' AS omffTransactionCode,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,1,4)  AS omffAccountingYear,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffBeginingPeriod,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffEndPeriode,
	--		SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4)  AS omffOccurenceYear,
	--		CT.CLTR_ORIGINAL_CURRENCY AS omffCurrency,
	--		SUM(CTD.CTD_RESERVE_INDEMNITY) AS omffSignedAmount,
	--		SEC.OSEC_ID AS SectionId
	-- FROM [dbo].CLAIM_TRANSACTIONS  AS CT
	--	inner join CLAIM_TRANSACTIONS_DIMENSIONS as CTD
	--	ON CTD.CTD_CLTR_ID = CT.CLTR_ID
	--	inner join BORDEREAUX_IMPORT as BI
	--	on BI.BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_BORDEREAUX_CONTROLS as CBC
	--	on CBC.CBC_BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_OMEGA_BOOKING_FLAT_FILE as COBFF
	--	on COBFF.COBFF_CBC_ID = CBC.CBC_ID 
	--	inner join CLAIM_MASTER as CM
	--	on CM.CLM_ID = CT.CLTR_CLM_ID
	--	inner join POLICY_MASTER as PM
	--	on PM.POL_ID = CM.CLM_POL_ID and CT.CLTR_ORIGINAL_CURRENCY = COBFF.COBFF_CURRENCY and PM.POL_INSURING_COMPANY_ID = COBFF.[COBFF_INSURING_COMPANY_ID]
	--	INNER JOIN [dbo].OMEGA_SECTION AS SEC
	--	ON SEC.OSEC_ID = CTD.CTD_SECTION_ID
	--	INNER JOIN [dbo].OMEGA_TREATY_NUMBER AS OTN
	--	ON OTN.OTN_ID = SEC.OSEC_OTN_ID
	--	WHERE (COBFF.COBFF_ID  = @inOmegaBookingFlateFile )
	--	and CTD.CTD_SECTION_ID is not null 

	--GROUP BY OTN.OTN_TREATY_NUMBER, [dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ), SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4), SEC.OSEC_NUMBER , SEC.OSEC_ID, BI.[BDXIMP_REPORTING_DATE], SEC.OSEC_NUMBER, CT.CLTR_ORIGINAL_CURRENCY
		
	--	UNION ALL

	----------------------
	-----	Transaction 11420500 
	----------------------
	--		----
	--		--  Claim transaction
	--		---
	--SELECT 
	--		LTRIM(RTRIM(OTN.OTN_TREATY_NUMBER)) AS omegaTreatyNumber,
	--		[dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ) AS omffUwy,
	--		1 AS omffNt,
	--		0 AS  omffEndorsementNumber,
	--		SEC.OSEC_NUMBER AS omegaSection,
	--		1 AS omffPrmlinIn,
	--		'11420500' AS omffTransactionCode,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,1,4)  AS omffAccountingYear,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffBeginingPeriod,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffEndPeriode,
	--		SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4)  AS omffOccurenceYear,
	--		CT.CLTR_ORIGINAL_CURRENCY AS omffCurrency,
	--		SUM(CT.CLTR_RESERVE_FEES) AS omffSignedAmount,
	--		SEC.OSEC_ID AS SectionId
	-- FROM [dbo].CLAIM_TRANSACTIONS  AS CT
	--	inner join BORDEREAUX_IMPORT as BI
	--	on BI.BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_BORDEREAUX_CONTROLS as CBC
	--	on CBC.CBC_BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_OMEGA_BOOKING_FLAT_FILE as COBFF
	--	on COBFF.COBFF_CBC_ID = CBC.CBC_ID 
	--	inner join CLAIM_MASTER as CM
	--	on CM.CLM_ID = CT.CLTR_CLM_ID
	--	inner join POLICY_MASTER as PM
	--	on PM.POL_ID = CM.CLM_POL_ID and CT.CLTR_ORIGINAL_CURRENCY = COBFF.COBFF_CURRENCY and PM.POL_INSURING_COMPANY_ID = COBFF.[COBFF_INSURING_COMPANY_ID]
	--	INNER JOIN [dbo].OMEGA_SECTION AS SEC
	--	ON SEC.OSEC_ID = CT.CLTR_SECTION_ID
	--	INNER JOIN [dbo].OMEGA_TREATY_NUMBER AS OTN
	--	ON OTN.OTN_ID = SEC.OSEC_OTN_ID
	--	WHERE (COBFF.COBFF_ID  = @inOmegaBookingFlateFile )
	--	and CT.CLTR_SECTION_ID is not null 

	--GROUP BY OTN.OTN_TREATY_NUMBER,[dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ),  SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4), SEC.OSEC_NUMBER , SEC.OSEC_ID, BI.[BDXIMP_REPORTING_DATE], SEC.OSEC_NUMBER, CT.CLTR_ORIGINAL_CURRENCY
		

	--		----
	--		--  claim transaction dimension
	--		---
	--UNION ALL

	
	--SELECT 
	--		LTRIM(RTRIM(OTN.OTN_TREATY_NUMBER)) AS omegaTreatyNumber,
	--		[dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ) AS omffUwy,
	--		1 AS omffNt,
	--		0 AS  omffEndorsementNumber,
	--		SEC.OSEC_NUMBER AS omegaSection,
	--		1 AS omffPrmlinIn,
	--		'11420500' AS omffTransactionCode,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,1,4)  AS omffAccountingYear,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffBeginingPeriod,
	--		SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffEndPeriode,
	--		SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4)  AS omffOccurenceYear,
	--		CT.CLTR_ORIGINAL_CURRENCY AS omffCurrency,
	--		SUM(CTD.CTD_RESERVE_FEES) AS omffSignedAmount,
	--		SEC.OSEC_ID AS SectionId
	-- FROM [dbo].CLAIM_TRANSACTIONS  AS CT
	--	inner join CLAIM_TRANSACTIONS_DIMENSIONS as CTD
	--	ON CTD.CTD_CLTR_ID = CT.CLTR_ID
	--	inner join BORDEREAUX_IMPORT as BI
	--	on BI.BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_BORDEREAUX_CONTROLS as CBC
	--	on CBC.CBC_BDXIMP_ID = CT.CLTR_BORDEREAU_ID
	--	inner join CLAIM_OMEGA_BOOKING_FLAT_FILE as COBFF
	--	on COBFF.COBFF_CBC_ID = CBC.CBC_ID 
	--	inner join CLAIM_MASTER as CM
	--	on CM.CLM_ID = CT.CLTR_CLM_ID
	--	inner join POLICY_MASTER as PM
	--	on PM.POL_ID = CM.CLM_POL_ID and CT.CLTR_ORIGINAL_CURRENCY = COBFF.COBFF_CURRENCY and PM.POL_INSURING_COMPANY_ID = COBFF.[COBFF_INSURING_COMPANY_ID]
	--	INNER JOIN [dbo].OMEGA_SECTION AS SEC
	--	ON SEC.OSEC_ID = CTD.CTD_SECTION_ID
	--	INNER JOIN [dbo].OMEGA_TREATY_NUMBER AS OTN
	--	ON OTN.OTN_ID = SEC.OSEC_OTN_ID
	--	WHERE (COBFF.COBFF_ID  = @inOmegaBookingFlateFile )
	--	and CTD.CTD_SECTION_ID is not null 

	--GROUP BY OTN.OTN_TREATY_NUMBER, [dbo].[GET_SCOR_UWY_FOR_TREATY_BY_INCEPTION_DATE](PM.POL_INCEPTION_DATE,OTN.OTN_TREATY_NUMBER ), SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4), SEC.OSEC_NUMBER , SEC.OSEC_ID, BI.[BDXIMP_REPORTING_DATE], SEC.OSEC_NUMBER, CT.CLTR_ORIGINAL_CURRENCY
		
--	UNION ALL
----------------------
--	---	Transaction 11420400 
--	--------------------
--			----
--			--  Claim transaction
--			---
--	SELECT 
--			LTRIM(RTRIM(OTN.OTN_TREATY_NUMBER)) AS omegaTreatyNumber,
--			SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4) AS omffUwy,
--			1 AS omffNt,
--			0 AS  omffEndorsementNumber,
--			SEC.OSEC_NUMBER AS omegaSection,
--			1 AS omffPrmlinIn,
--			'11420400' AS omffTransactionCode,
--			SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,1,4)  AS omffAccountingYear,
--			SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffBeginingPeriod,
--			SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffEndPeriode,
--			SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4)  AS omffOccurenceYear,
--			CT.CLTR_ORIGINAL_CURRENCY AS omffCurrency,
--			SUM(CT.CLTR_RECOVERIES_RESERVE) AS omffSignedAmount,
--			SEC.OSEC_ID AS SectionId
--	 FROM [dbo].CLAIM_TRANSACTIONS  AS CT
--		inner join BORDEREAUX_IMPORT as BI
--		on BI.BDXIMP_ID = CT.CLTR_BORDEREAU_ID
--		inner join CLAIM_BORDEREAUX_CONTROLS as CBC
--		on CBC.CBC_BDXIMP_ID = CT.CLTR_BORDEREAU_ID
--		inner join CLAIM_OMEGA_BOOKING_FLAT_FILE as COBFF
--		on COBFF.COBFF_CBC_ID = CBC.CBC_ID 
--		inner join CLAIM_MASTER as CM
--		on CM.CLM_ID = CT.CLTR_CLM_ID
--		inner join POLICY_MASTER as PM
--		on PM.POL_ID = CM.CLM_POL_ID and CT.CLTR_ORIGINAL_CURRENCY = COBFF.COBFF_CURRENCY and PM.POL_INSURING_COMPANY_ID = COBFF.[COBFF_INSURING_COMPANY_ID]
--		INNER JOIN [dbo].OMEGA_SECTION AS SEC
--		ON SEC.OSEC_ID = CT.CLTR_SECTION_ID
--		INNER JOIN [dbo].OMEGA_TREATY_NUMBER AS OTN
--		ON OTN.OTN_ID = SEC.OSEC_OTN_ID
--		WHERE (COBFF.COBFF_ID  = @inOmegaBookingFlateFile )
--		and CT.CLTR_SECTION_ID is not null 

--	GROUP BY OTN.OTN_TREATY_NUMBER, SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4), SEC.OSEC_NUMBER , SEC.OSEC_ID, BI.[BDXIMP_REPORTING_DATE], SEC.OSEC_NUMBER, CT.CLTR_ORIGINAL_CURRENCY
		

--			----
--			--  claim transaction dimension
--			---
--	UNION ALL

	
--	SELECT 
--			LTRIM(RTRIM(OTN.OTN_TREATY_NUMBER)) AS omegaTreatyNumber,
--			SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4) AS omffUwy,
--			1 AS omffNt,
--			0 AS  omffEndorsementNumber,
--			SEC.OSEC_NUMBER AS omegaSection,
--			1 AS omffPrmlinIn,
--			'11420400' AS omffTransactionCode,
--			SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,1,4)  AS omffAccountingYear,
--			SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffBeginingPeriod,
--			SUBSTRING(CAST(BI.[BDXIMP_REPORTING_DATE] AS nvarchar) ,6,2) AS omffEndPeriode,
--			SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4)  AS omffOccurenceYear,
--			CT.CLTR_ORIGINAL_CURRENCY AS omffCurrency,
--			SUM(CTD.CTD_RECOVERIES_RESERVE) AS omffSignedAmount,
--			SEC.OSEC_ID AS SectionId
--	 FROM [dbo].CLAIM_TRANSACTIONS  AS CT
--		inner join CLAIM_TRANSACTIONS_DIMENSIONS as CTD
--		ON CTD.CTD_CLTR_ID = CT.CLTR_ID
--		inner join BORDEREAUX_IMPORT as BI
--		on BI.BDXIMP_ID = CT.CLTR_BORDEREAU_ID
--		inner join CLAIM_BORDEREAUX_CONTROLS as CBC
--		on CBC.CBC_BDXIMP_ID = CT.CLTR_BORDEREAU_ID
--		inner join CLAIM_OMEGA_BOOKING_FLAT_FILE as COBFF
--		on COBFF.COBFF_CBC_ID = CBC.CBC_ID 
--		inner join CLAIM_MASTER as CM
--		on CM.CLM_ID = CT.CLTR_CLM_ID
--		inner join POLICY_MASTER as PM
--		on PM.POL_ID = CM.CLM_POL_ID and CT.CLTR_ORIGINAL_CURRENCY = COBFF.COBFF_CURRENCY and PM.POL_INSURING_COMPANY_ID = COBFF.[COBFF_INSURING_COMPANY_ID]
--		INNER JOIN [dbo].OMEGA_SECTION AS SEC
--		ON SEC.OSEC_ID = CTD.CTD_SECTION_ID
--		INNER JOIN [dbo].OMEGA_TREATY_NUMBER AS OTN
--		ON OTN.OTN_ID = SEC.OSEC_OTN_ID
--		WHERE (COBFF.COBFF_ID  = @inOmegaBookingFlateFile )
--		and CTD.CTD_SECTION_ID is not null 

--	GROUP BY OTN.OTN_TREATY_NUMBER, SUBSTRING(CAST(PM.POL_INCEPTION_DATE AS nvarchar) ,1,4), SEC.OSEC_NUMBER , SEC.OSEC_ID, BI.[BDXIMP_REPORTING_DATE], SEC.OSEC_NUMBER, CT.CLTR_ORIGINAL_CURRENCY

END	
--		SELECT 
--			'TR0009391'	 AS omegaTreatyNumber,
--			2016 AS omffUwy,
--			1 AS omffNt,
--			0 AS  omffEndorsementNumber,
--			3 AS omegaSection,
--			1 AS omffPrmlinIn,
--			'11200000' AS omffTransactionCode,
--			2018  AS omffAccountingYear,
--			5 AS omffBeginingPeriod,
--			5 AS omffEndPeriode,
--			2016  AS omffOccurenceYear,
--			'USD' AS omffCurrency,
--			0 AS omffSignedAmount,
--			'1' AS omffSectionId
	

	
		

--			----
--			--  claim transaction dimension
	
	 

		
--	UNION ALL

--	--------------------
--	---	Transaction 11200500 
--	--------------------
--			----
--			--  Claim transaction
--			---
--	SELECT 
--			'TR0009391'	 AS omegaTreatyNumber,
--			2016 AS omffUwy,
--			1 AS omffNt,
--			0 AS  omffEndorsementNumber,
--			3 AS omegaSection,
--			1 AS omffPrmlinIn,
--			'11200500' AS omffTransactionCode,
--			2018  AS omffAccountingYear,
--			5 AS omffBeginingPeriod,
--			5 AS omffEndPeriode,
--			2016  AS omffOccurenceYear,
--			'usd' AS omffCurrency,
--			0 AS omffSignedAmount,
--			'1' AS omffSectionId
	
--		UNION ALL
--	--------------------
--	---	Transaction 11200400 
--	--------------------
--			----
--			--  Claim transaction
--			---
--	SELECT 
--			'TR0009391'	 AS omegaTreatyNumber,
--			2016 AS omffUwy,
--			1 AS omffNt,
--			0 AS  omffEndorsementNumber,
--			3 AS omegaSection,
--			1 AS omffPrmlinIn,
--			'11200400' AS omffTransactionCode,
--			2018  AS omffAccountingYear,
--			5 AS omffBeginingPeriod,
--			5 AS omffEndPeriode,
--			2016  AS omffOccurenceYear,
--			'usd' AS omffCurrency,
--			0 AS omffSignedAmount,
--			'1' AS omffSectionId
	 
--UNION ALL
--	--------------------
--	---	Transaction 11420000 
--	--------------------
--			----
--			--  Claim transaction
--			---
--	SELECT 
--			'TR0009391'	 AS omegaTreatyNumber,
--			2016 AS omffUwy,
--			1 AS omffNt,
--			0 AS  omffEndorsementNumber,
--			3 AS omegaSection,
--			1 AS omffPrmlinIn,
--			'11420000' AS omffTransactionCode,
--			2018  AS omffAccountingYear,
--			5 AS omffBeginingPeriod,
--			5 AS omffEndPeriode,
--			2016  AS omffOccurenceYear,
--			'usd' AS omffCurrency,
--			0 AS omffSignedAmount,
--			'1' AS omffSectionId
	
		
--UNION ALL
--	--------------------
--	---	Transaction 11420500 
--	--------------------
--			----
--			--  Claim transaction
--			---
--	SELECT 
--			'TR0009391'	 AS omegaTreatyNumber,
--			2016 AS omffUwy,
--			1 AS omffNt,
--			0 AS  omffEndorsementNumber,
--			3 AS omegaSection,
--			1 AS omffPrmlinIn,
--			'11420500' AS omffTransactionCode,
--			2018  AS omffAccountingYear,
--			5 AS omffBeginingPeriod,
--			5 AS omffEndPeriode,
--			2016  AS omffOccurenceYear,
--			'usd' AS omffCurrency,
--			0 AS omffSignedAmount,
--			'1' AS omffSectionId
	
--	UNION ALL	
--	--------------------
--	---	Transaction 11420400 
--	--------------------
--			----
--			--  Claim transaction
--			---
--	SELECT 
--			'TR0009391'	 AS omegaTreatyNumber,
--			2016 AS omffUwy,
--			1 AS omffNt,
--			0 AS  omffEndorsementNumber,
--			3 AS omegaSection,
--			1 AS omffPrmlinIn,
--			'11420400' AS omffTransactionCode,
--			2018  AS omffAccountingYear,
--			5 AS omffBeginingPeriod,
--			5 AS omffEndPeriode,
--			2016  AS omffOccurenceYear,
--			'usd' AS omffCurrency,
--			0 AS omffSignedAmount,
--			'1' AS omffSectionId
	
					   