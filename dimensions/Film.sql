DROP TABLE IF EXISTS DIM_FILM;

-- CRIAÇÃO DA TABELA DE DIMENSÃO FILME
CREATE TABLE DIM_FILM
(
  FILM_ID INT NOT NULL,
  TITLE VARCHAR(25) NOT NULL,
  RENTAL_RATE NUMERIC(4,2) NOT NULL,
  CONSTRAINT PKFILM_ID PRIMARY KEY (FILM_ID ASC)
);

-- Bloco utilizado para verificar se a SP já existe. Se SIM, o banco fará um DROP da SP e irá recriar.
IF EXISTS (
  SELECT * 
  FROM INFORMATION_SCHEMA.ROUTINES 
  WHERE SPECIFIC_NAME = N'PROC_ETL_FILM'
)
   DROP PROCEDURE PROC_ETL_FILM;

-- CREATE THE STORED PROCEDURE 
CREATE PROCEDURE DBO.PROC_ETL_FILM
AS
BEGIN
  -- Declare variables
  DECLARE
    @V_FILM_ID INT,
    @V_TITLE VARCHAR(25),
    @V_RENTAL_RATE NUMERIC(4,2),
    @V_DSC_DADOS_PROCESSAMENTO VARCHAR(2000);

  -- Declare cursor
  DECLARE CUR_GET_FILM CURSOR FOR
  SELECT
    ORIGEM.FILM_ID,
    ORIGEM.TITLE,
    ORIGEM.RENTAL_RATE
  FROM film AS ORIGEM
  WHERE NOT EXISTS (SELECT DIM.FILM_ID
                    FROM DIM_FILM DIM
                    WHERE ORIGEM.FILM_ID = DIM.FILM_ID);

  -- Open cursor
  OPEN CUR_GET_FILM;

  -- Fetch first record
  FETCH NEXT FROM CUR_GET_FILM
  INTO
    @V_FILM_ID,
    @V_TITLE,
    @V_RENTAL_RATE;

  -- Loop through the cursor
  WHILE (@@FETCH_STATUS = 0)
  BEGIN
    -- Set processing info
    SET @V_DSC_DADOS_PROCESSAMENTO = 'FILM_ID ' + CAST(@V_FILM_ID AS VARCHAR) + CHAR(13) + CHAR(10) +
                                     'TITLE ' + CAST(@V_TITLE AS VARCHAR);
                                     
    BEGIN TRANSACTION;
         INSERT INTO DIM_FILM
         (FILM_ID, TITLE, RENTAL_RATE)
         VALUES
         (@V_FILM_ID, @V_TITLE, @V_RENTAL_RATE);
           
         -- Error handling
         IF @@ERROR <> 0
         BEGIN
            ROLLBACK;
            -- Show last processed record
            SELECT @V_DSC_DADOS_PROCESSAMENTO;
            -- Close cursor and deallocate
            CLOSE CUR_GET_FILM;
            DEALLOCATE CUR_GET_FILM;
            -- Exit procedure
            RETURN;
         END
    COMMIT;
    
    -- Fetch next record
    FETCH NEXT FROM CUR_GET_FILM
    INTO
      @V_FILM_ID,
      @V_TITLE,
      @V_RENTAL_RATE;
  END
  
  -- Close cursor and deallocate
  CLOSE CUR_GET_FILM;
  DEALLOCATE CUR_GET_FILM;
END;

-- Execute stored procedure
EXEC PROC_ETL_FILM;

-- Select from DIM_FILM
SELECT * FROM DIM_FILM;
