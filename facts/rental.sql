-- DROP DA TABELA FATURA CASO JÁ EXISTA
DROP TABLE IF EXISTS FT_RENTAL;

-- CRIAÇÃO DA TABELA FATO FT_RENTAL
CREATE TABLE FT_RENTAL
(
    TIME INT NOT NULL,               -- Chave Tempo
    FILM_ID INT NULL,                -- Chave do Filme
    CATEGORY_ID INT NULL,            -- Chave da Categoria
    CUSTOMER_ID INT NULL,            -- Chave do Cliente
    STAFF_ID INT NULL,               -- Chave do Funcionário
    STORE_ID INT NULL,               -- Chave da Loja
    INVENTORY_ID INT NULL,           -- Chave do Inventário
    QUANTITY INT NOT NULL,           -- Quantidade de Aluguéis
    AMOUNT DECIMAL(10, 2) NOT NULL,  -- Valor Total do Aluguel
);

-- Verificar se a Procedure já existe, se SIM, fazer o DROP e recriar
IF EXISTS (
  SELECT * 
  FROM INFORMATION_SCHEMA.ROUTINES 
  WHERE SPECIFIC_NAME = N'PROC_ETL_FT_RENTAL' 
)
  DROP PROCEDURE PROC_ETL_FT_RENTAL;

-- Criando a Procedure para popular FT_RENTAL
CREATE PROCEDURE DBO.PROC_ETL_FT_RENTAL
AS
BEGIN
  -- Variáveis de controle
  DECLARE 
    @TIME INT,
    @FILM_ID INT,
    @CATEGORY_ID INT,
    @CUSTOMER_ID INT,
    @STAFF_ID INT,
    @STORE_ID INT,
    @INVENTORY_ID INT,
    @QUANTITY INT,
    @AMOUNT DECIMAL(10, 2),
    @V_DSC_DADOS_PROCESSAMENTO VARCHAR(2000);

  -- Declaração do Cursor para capturar os dados do select
  DECLARE CUR_GET_RENTAL CURSOR FOR
  WITH TESTE AS (
    SELECT
        dt.DIM_TEMPO_SEQ_TEMPO AS TIME,
        f.FILM_ID,
        cat.CATEGORY_ID,
        r.CUSTOMER_ID,
        r.STAFF_ID,
        i.STORE_ID,
        r.INVENTORY_ID,
        COALESCE(COUNT(r.rental_id), 0) AS QUANTITY,
        COALESCE(SUM(p.amount), 0) AS AMOUNT
    FROM DIM_TEMPO dt
    LEFT JOIN RENTAL r
        ON YEAR(r.RENTAL_DATE) = dt.DIM_TEMPO_ANO
        AND (dt.DIM_TEMPO_MES IS NULL OR MONTH(r.RENTAL_DATE) = dt.DIM_TEMPO_MES)
    LEFT JOIN INVENTORY i
        ON r.INVENTORY_ID = i.INVENTORY_ID
    LEFT JOIN FILM f
        ON i.FILM_ID = f.FILM_ID
    LEFT JOIN FILM_CATEGORY fc
        ON f.FILM_ID = fc.FILM_ID
    LEFT JOIN DIM_CATEGORY cat
        ON fc.CATEGORY_ID = cat.CATEGORY_ID
    LEFT JOIN PAYMENT p
        ON r.RENTAL_ID = p.RENTAL_ID
    WHERE (dt.DIM_TEMPO_MES IS NULL AND dt.DIM_TEMPO_ANO IS NOT NULL)
       OR (dt.DIM_TEMPO_MES IS NOT NULL AND dt.DIM_TEMPO_ANO IS NOT NULL)
    GROUP BY dt.DIM_TEMPO_SEQ_TEMPO, f.FILM_ID, cat.CATEGORY_ID, r.CUSTOMER_ID, r.STAFF_ID, i.STORE_ID, r.INVENTORY_ID
  )
  SELECT TIME, FILM_ID, CATEGORY_ID, CUSTOMER_ID, STAFF_ID, STORE_ID, INVENTORY_ID, QUANTITY, AMOUNT
  FROM TESTE;

  -- Abrindo o cursor
  OPEN CUR_GET_RENTAL;
  
  -- Captura do primeiro registro
  FETCH NEXT FROM CUR_GET_RENTAL INTO @TIME, @FILM_ID, @CATEGORY_ID, @CUSTOMER_ID, @STAFF_ID, @STORE_ID, @INVENTORY_ID, @QUANTITY, @AMOUNT;

  -- Loop para processar todos os registros
  WHILE (@@FETCH_STATUS = 0)
  BEGIN
    -- Informações de processamento
    SET @V_DSC_DADOS_PROCESSAMENTO = 'TIME ' + CAST(@TIME AS VARCHAR) + ', FILM ' + ISNULL(CAST(@FILM_ID AS VARCHAR), 'NULL') 
      + ', CATEGORY ' + ISNULL(CAST(@CATEGORY_ID AS VARCHAR), 'NULL') 
      + ', CUSTOMER ' + ISNULL(CAST(@CUSTOMER_ID AS VARCHAR), 'NULL') 
      + ', STAFF ' + ISNULL(CAST(@STAFF_ID AS VARCHAR), 'NULL')
      + ', STORE ' + ISNULL(CAST(@STORE_ID AS VARCHAR), 'NULL') 
      + ', INVENTORY ' + ISNULL(CAST(@INVENTORY_ID AS VARCHAR), 'NULL');
    
    BEGIN TRANSACTION;
      -- Inserir os dados na tabela FT_RENTAL
      INSERT INTO FT_RENTAL (TIME, FILM_ID, CATEGORY_ID, CUSTOMER_ID, STAFF_ID, STORE_ID, INVENTORY_ID, QUANTITY, AMOUNT)
      VALUES (@TIME, @FILM_ID, @CATEGORY_ID, @CUSTOMER_ID, @STAFF_ID, @STORE_ID, @INVENTORY_ID, @QUANTITY, @AMOUNT);

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

    -- Capturar próximo registro
    FETCH NEXT FROM CUR_GET_RENTAL INTO @TIME, @FILM_ID, @CATEGORY_ID, @CUSTOMER_ID, @STAFF_ID, @STORE_ID, @INVENTORY_ID, @QUANTITY, @AMOUNT;
  END

  -- Fechar cursor e liberar recursos
  CLOSE CUR_GET_RENTAL;
  DEALLOCATE CUR_GET_RENTAL;
END;

-- Executar a procedure para popular a tabela FT_RENTAL
EXEC PROC_ETL_FT_RENTAL;

-- Verificar os dados inseridos
SELECT * FROM FT_RENTAL;
