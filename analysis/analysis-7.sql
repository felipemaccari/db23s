-- Análise comparativa da produtividade dos funcionários em relação aos empréstimos

-- Verifica se a procedure já existe e a remove
IF EXISTS (
  SELECT * 
  FROM INFORMATION_SCHEMA.ROUTINES 
  WHERE SPECIFIC_NAME = N'PROC_ETL_FT_RENTAL_ANALISE7' 
)
  DROP PROCEDURE PROC_ETL_FT_RENTAL_ANALISE7;

-- Cria a procedure para popular FT_RENTAL para a análise 7
CREATE PROCEDURE DBO.PROC_ETL_FT_RENTAL_ANALISE7
AS
BEGIN
  -- Declaração das variáveis
  DECLARE
    @STAFF_ID INT,
    @QUANTITY INT,
    @V_DSC_DADOS_PROCESSAMENTO VARCHAR(2000);

  -- Cursor para capturar os dados
  DECLARE CUR_GET_RENTAL CURSOR FOR
  SELECT
      r.STAFF_ID,
      COUNT(r.rental_id) AS QUANTITY
  FROM
      RENTAL r
  GROUP BY
      r.STAFF_ID;

  -- Abre o cursor
  OPEN CUR_GET_RENTAL;

  -- Captura o primeiro registro
  FETCH NEXT FROM CUR_GET_RENTAL INTO @STAFF_ID, @QUANTITY;

  -- Loop para processar todos os registros
  WHILE (@@FETCH_STATUS = 0)
  BEGIN
    -- Informações de processamento
    SET @V_DSC_DADOS_PROCESSAMENTO = 'STAFF ' + CAST(@STAFF_ID AS VARCHAR);

    BEGIN TRANSACTION;
      -- Insere os dados na FT_RENTAL
      INSERT INTO FT_RENTAL (
          TIME, FILM_ID, CATEGORY_ID, CUSTOMER_ID, STAFF_ID, STORE_ID, INVENTORY_ID, ACTOR_ID, QUANTITY, AMOUNT, STATUS_PAGAMENTO, LUCRO_PREJUIZO
      )
      VALUES (
          0, NULL, NULL, NULL, @STAFF_ID, NULL, NULL, NULL, @QUANTITY, 0.00, NULL, NULL
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
    FETCH NEXT FROM CUR_GET_RENTAL INTO @STAFF_ID, @QUANTITY;
  END

  -- Fecha o cursor e libera recursos
  CLOSE CUR_GET_RENTAL;
  DEALLOCATE CUR_GET_RENTAL;
END;

-- Executa a procedure
EXEC DBO.PROC_ETL_FT_RENTAL_ANALISE7;

-- Consulta final para retornar a produtividade dos funcionários
SELECT
    s.FIRST_NAME AS FUNCIONARIO,
    SUM(fr.QUANTITY) AS QUANTIDADE_EMPRESTIMOS
FROM
    FT_RENTAL fr
    JOIN DIM_STAFF s ON fr.STAFF_ID = s.STAFF_ID
WHERE
    fr.TIME = 0
    AND fr.FILM_ID IS NULL
    AND fr.CATEGORY_ID IS NULL
    AND fr.CUSTOMER_ID IS NULL
    AND fr.STORE_ID IS NULL
    AND fr.INVENTORY_ID IS NULL
    AND fr.ACTOR_ID IS NULL
GROUP BY
    s.FIRST_NAME
ORDER BY
    QUANTIDADE_EMPRESTIMOS DESC;

--PROVA REAL
SELECT
    s.FIRST_NAME + ' ' + s.LAST_NAME AS FUNCIONARIO,
    COUNT(r.rental_id) AS QUANTIDADE_EMPRESTIMOS_ORIGINAL
FROM
    RENTAL r
    JOIN STAFF s ON r.STAFF_ID = s.STAFF_ID
GROUP BY
    s.FIRST_NAME,
    s.LAST_NAME
ORDER BY
    FUNCIONARIO;