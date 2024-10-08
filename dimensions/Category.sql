DROP TABLE IF EXISTS DIM_CATEGORY;

-- CRIAÇÃO DA TABELA DE DIMENSÃO CATEGORIA
CREATE TABLE DIM_CATEGORY
(
  CATEGORY_ID  INT NOT NULL,
  NAME VARCHAR(25) NOT NULL,
  LAST_UPDATE DATETIME NOT NULL,
  CONSTRAINT PKCATEGORY_ID PRIMARY KEY (CATEGORY_ID ASC)
);

-- Bloco utilizado para verificar se a SP já existe. Se SIM, o banco fará um DROP da SP e irá recriar.
IF EXISTS (
  SELECT * 
    FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE SPECIFIC_NAME = N'PROC_ETL_CATEGORY' 
)
   DROP PROCEDURE PROC_ETL_CATEGORY;

-- CREATE THE STORED PROCEDURE 
CREATE PROCEDURE DBO.PROC_ETL_CATEGORY
AS
BEGIN
  -- DECLARAÇÃO DAS VARIÁVEIS DE LOG E CONTROLE
  DECLARE
    --VARIÁVEIS DE TABELA
    @V_CATEGORY_ID INT,
    @V_NAME VARCHAR(25),
    @V_LAST_UPDATE DATETIME,
    
    --VARIÁVEIS DE CONTROLE DE DADOS PROCESSADOS
    @V_DSC_DADOS_PROCESSAMENTO VARCHAR(2000);

  -- DECLARAÇÃO DO CURSOR
  DECLARE CUR_GET_CATEGORY CURSOR FOR
  SELECT
    ORIGEM.CATEGORY_ID,
    ORIGEM.NAME,
    ORIGEM.LAST_UPDATE
  FROM category AS ORIGEM
  WHERE NOT EXISTS (SELECT DIM.CATEGORY_ID
                    FROM DIM_CATEGORY DIM
                    WHERE ORIGEM.CATEGORY_ID = DIM.CATEGORY_ID);

  -- ABRE CURSOR PARA EXECUÇÃO
  OPEN CUR_GET_CATEGORY;

  -- CAPTURA PRIMEIRO REGISTRO PARA INICIAR O LOOP
  FETCH NEXT FROM CUR_GET_CATEGORY
  INTO
    @V_CATEGORY_ID,
    @V_NAME,
    @V_LAST_UPDATE;

  -- LOOP QUE IRÁ EXECUTAR ENQUANTO HOUVER LINHAS NO CURSOR PARA SEREM PROCESSADAS
  WHILE (@@FETCH_STATUS = 0)
  BEGIN
    -- ATRIBUI VALORES PROCESSADOS
    SET @V_DSC_DADOS_PROCESSAMENTO = 'CATEGORY_ID ' + CAST(@V_CATEGORY_ID AS VARCHAR) + CHAR(13) + CHAR(10) +
                                     'NAME ' + CAST(@V_NAME AS VARCHAR);
                                     
    BEGIN TRANSACTION;
         INSERT INTO DIM_CATEGORY
         (CATEGORY_ID, NAME, LAST_UPDATE)
         VALUES
         (@V_CATEGORY_ID, @V_NAME, @V_LAST_UPDATE);
           
         -- TRATAMENTO DE ERRO
         IF @@ERROR <> 0
         BEGIN
            ROLLBACK;
            -- EXIBE QUAL FOI O ÚLTIMO REGISTRO A SER PROCESSADO
            SELECT @V_DSC_DADOS_PROCESSAMENTO;
            -- FECHA CURSOR E LIBERA RECURSO DE MEMÓRIA
            CLOSE CUR_GET_CATEGORY;
            DEALLOCATE CUR_GET_CATEGORY;
            -- SAI DA SP
            RETURN;
         END -- IF
    COMMIT;
    
    -- CAPTURA PRÓXIMA LINHA DE REGISTROS PARA CONTINUAR O PROCESSAMENTO SE A REGRA DO LOOP AINDA ESTIVER VALENDO
    FETCH NEXT FROM CUR_GET_CATEGORY
    INTO
      @V_CATEGORY_ID,
      @V_NAME,
      @V_LAST_UPDATE;
  END -- WHILE
  
  -- FECHA CURSOR E LIBERA RECURSO DE MEMÓRIA
  CLOSE CUR_GET_CATEGORY;
  DEALLOCATE CUR_GET_CATEGORY;
END;


EXEC PROC_ETL_CATEGORY


SELECT * FROM DIM_CATEGORY