DROP TABLE IF EXISTS DIM_TEMPO

CREATE TABLE dbo.DIM_TEMPO
(
  DIM_TEMPO_SEQ_TEMPO NUMERIC(14) PRIMARY KEY,
  DIM_TEMPO_ANO NUMERIC(4) NOT NULL,
  DIM_TEMPO_MES NUMERIC(2),
)

IF EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.ROUTINES 
    WHERE SPECIFIC_NAME = N'PROC_DIM_TEMPO'
)
    DROP PROCEDURE PROC_DIM_TEMPO;

CREATE PROCEDURE DBO.PROC_DIM_TEMPO
AS
BEGIN
    DECLARE
        -- VARIÁVEIS DE CONTROLE
        @V_DIM_TEMPO_SEQ_TEMPO NUMERIC(14),
        @V_DIM_TEMPO_ANO NUMERIC(4),
        @V_DIM_TEMPO_MES NUMERIC(2),
        @V_DATA_ATUAL DATETIME,
        @V_DATA_FINAL DATETIME,
        @V_COUNT NUMERIC(12);

    -- MENOR DATA
    SELECT @V_DATA_ATUAL = MIN(rental_date), @V_DATA_FINAL = MAX(rental_date)
    FROM dbo.rental;

    -- VE SE A DATA FINAL TEM MES COMPLETO
    SET @V_DATA_FINAL = DATEADD(MONTH, 1, @V_DATA_FINAL);

    -- ANOS
    WHILE @V_DATA_ATUAL <= @V_DATA_FINAL
    BEGIN
        SET @V_DIM_TEMPO_ANO = CAST(DATEPART(YEAR, @V_DATA_ATUAL) AS NUMERIC);
        SELECT @V_DIM_TEMPO_SEQ_TEMPO = ISNULL(MAX(DIM_TEMPO_SEQ_TEMPO), 0) + 1
        FROM DIM_TEMPO;

        -- VE SE JA EXISTE O ANO
        SELECT @V_COUNT = COUNT(*)
        FROM DIM_TEMPO
        WHERE DIM_TEMPO_ANO = @V_DIM_TEMPO_ANO
          AND DIM_TEMPO_MES IS NULL;

        IF @V_COUNT = 0
        BEGIN
            BEGIN TRANSACTION;
                INSERT INTO DBO.DIM_TEMPO
                (
                    DIM_TEMPO_SEQ_TEMPO,
                    DIM_TEMPO_ANO
                )
                VALUES
                (
                    @V_DIM_TEMPO_SEQ_TEMPO,
                    @V_DIM_TEMPO_ANO
                );
            COMMIT;
        END;

        SET @V_DATA_ATUAL = DATEADD(MONTH, 1, @V_DATA_ATUAL);
    END;

    SET @V_DATA_ATUAL = (SELECT MIN(rental_date) FROM dbo.rental);
    WHILE @V_DATA_ATUAL < @V_DATA_FINAL
    BEGIN
        -- ANO E MES
        SET @V_DIM_TEMPO_ANO = CAST(DATEPART(YEAR, @V_DATA_ATUAL) AS NUMERIC);
        SET @V_DIM_TEMPO_MES = CAST(DATEPART(MONTH, @V_DATA_ATUAL) AS NUMERIC);

        SELECT @V_DIM_TEMPO_SEQ_TEMPO = ISNULL(MAX(DIM_TEMPO_SEQ_TEMPO), 0) + 1
        FROM DIM_TEMPO;

        SELECT @V_COUNT = COUNT(*)
        FROM DIM_TEMPO
        WHERE DIM_TEMPO_ANO = @V_DIM_TEMPO_ANO
          AND DIM_TEMPO_MES = @V_DIM_TEMPO_MES;

        IF @V_COUNT = 0
        BEGIN
            BEGIN TRANSACTION;
                INSERT INTO DBO.DIM_TEMPO
                (
                    DIM_TEMPO_SEQ_TEMPO,
                    DIM_TEMPO_ANO,
                    DIM_TEMPO_MES
                )
                VALUES
                (
                    @V_DIM_TEMPO_SEQ_TEMPO,
                    @V_DIM_TEMPO_ANO,
                    @V_DIM_TEMPO_MES
                );
            COMMIT;
        END;

        SET @V_DATA_ATUAL = DATEADD(MONTH, 1, @V_DATA_ATUAL);
    END;
END;


EXEC DBO.PROC_DIM_TEMPO

SELECT * FROM DIM_TEMPO