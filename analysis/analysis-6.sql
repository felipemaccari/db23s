-- Análise de volume de empréstimos por clientes, permitindo uma visão por localidade do cliente e tempo

-- Verifica se a procedure já existe e a remove
IF EXISTS (
  SELECT * 
  FROM INFORMATION_SCHEMA.ROUTINES 
  WHERE SPECIFIC_NAME = N'PROC_ETL_FT_RENTAL_ANALISE6' 
)
  DROP PROCEDURE PROC_ETL_FT_RENTAL_ANALISE6;

-- Cria a procedure para popular FT_RENTAL para a análise 6
CREATE PROCEDURE DBO.PROC_ETL_FT_RENTAL_ANALISE6
AS
BEGIN
  -- Declaração das variáveis
  DECLARE
    @TIME INT,
    @CUSTOMER_ID INT,
    @CITY VARCHAR(50),
    @QUANTITY INT,
    @V_DSC_DADOS_PROCESSAMENTO VARCHAR(2000);

  -- Cursor para capturar os dados
  DECLARE CUR_GET_RENTAL CURSOR FOR
  SELECT
      dt.DIM_TEMPO_SEQ_TEMPO AS TIME,
      r.CUSTOMER_ID,
      c.CITY,
      COUNT(r.rental_id) AS QUANTITY
  FROM
      RENTAL r
      JOIN DIM_CUSTOMER c ON r.CUSTOMER_ID = c.CUSTOMER_ID
      JOIN DIM_TEMPO dt ON YEAR(r.RENTAL_DATE) = dt.DIM_TEMPO_ANO
                        AND MONTH(r.RENTAL_DATE) = dt.DIM_TEMPO_MES
  GROUP BY
      dt.DIM_TEMPO_SEQ_TEMPO,
      r.CUSTOMER_ID,
      c.CITY;

  -- Abre o cursor
  OPEN CUR_GET_RENTAL;

  -- Captura o primeiro registro
  FETCH NEXT FROM CUR_GET_RENTAL INTO @TIME, @CUSTOMER_ID, @CITY, @QUANTITY;

  -- Loop para processar todos os registros
  WHILE (@@FETCH_STATUS = 0)
  BEGIN
    -- Informações de processamento
    SET @V_DSC_DADOS_PROCESSAMENTO = 'TIME ' + CAST(@TIME AS VARCHAR) + ', CUSTOMER ' + CAST(@CUSTOMER_ID AS VARCHAR) 
                                   + ', CITY ' + CAST(@CITY AS VARCHAR);

    BEGIN TRANSACTION;
      -- Insere os dados na FT_RENTAL
      INSERT INTO FT_RENTAL (
          TIME, FILM_ID, CATEGORY_ID, CUSTOMER_ID, STAFF_ID, STORE_ID, INVENTORY_ID, ACTOR_ID, QUANTITY, AMOUNT, STATUS_PAGAMENTO, LUCRO_PREJUIZO
      )
      VALUES (
          @TIME, NULL, NULL, @CUSTOMER_ID, NULL, NULL, NULL, NULL, @QUANTITY, 0.00, NULL, NULL
      );

      -- Tratamento de erro
      IF @@ERROR <> 0
      BEGIN
        ROLLBACK;
        SELECT @V_DSC_DADOS_PROCESSAMENTO;
        CLOSE CUR_GET_RENTAL;
        DEALLOCATE CUR_GET_RENTAL;
        RETURN;
      END
    COMMIT;

    -- Captura o próximo registro
    FETCH NEXT FROM CUR_GET_RENTAL INTO @TIME, @CUSTOMER_ID, @CITY, @QUANTITY;
  END

  -- Fecha o cursor e libera recursos
  CLOSE CUR_GET_RENTAL;
  DEALLOCATE CUR_GET_RENTAL;
END;

-- Executa a procedure
EXEC DBO.PROC_ETL_FT_RENTAL_ANALISE6;

-- Consulta final para retornar o volume de empréstimos por cliente, localidade e tempo
SELECT
    c.FIRST_NAME + ' ' + c.LAST_NAME AS CLIENTE,
    c.CITY AS CIDADE,
    dt.DIM_TEMPO_ANO AS ANO,
    dt.DIM_TEMPO_MES AS MES,
    SUM(fr.QUANTITY) AS QUANTIDADE_EMPRESTIMOS
FROM
    FT_RENTAL fr
    JOIN DIM_CUSTOMER c ON fr.CUSTOMER_ID = c.CUSTOMER_ID
    JOIN DIM_TEMPO dt ON fr.TIME = dt.DIM_TEMPO_SEQ_TEMPO
WHERE
    fr.FILM_ID IS NULL
    AND fr.CATEGORY_ID IS NULL
    AND fr.STAFF_ID IS NULL
    AND fr.STORE_ID IS NULL
    AND fr.INVENTORY_ID IS NULL
    AND fr.ACTOR_ID IS NULL
GROUP BY
    c.FIRST_NAME,
    c.LAST_NAME,
    c.CITY,
    dt.DIM_TEMPO_ANO,
    dt.DIM_TEMPO_MES
ORDER BY
    dt.DIM_TEMPO_ANO,
    dt.DIM_TEMPO_MES,
    QUANTIDADE_EMPRESTIMOS DESC;