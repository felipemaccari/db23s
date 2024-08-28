DROP TABLE IF EXISTS DIM_ACTOR

-- CRIAÇÃO DA TABELA DE DIMENSÃO ATOR
CREATE TABLE DIM_ACTOR
(
  ACTOR_ID  INT NOT NULL,
  FIRST_NAME VARCHAR(25) NOT NULL,
  LAST_UPDATE DATETIME NOT NULL,
  CONSTRAINT PKACTOR_ID PRIMARY KEY (ACTOR_ID ASC)
);

-- Bloco utilizado para verificar se a SP já existe. Se SIM, o banco fará um DROP da SP e irá recriar.
IF EXISTS (
  SELECT * 
    FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE 1=1
     AND SPECIFIC_NAME = N'PROC_ETL_ACTOR' 
)
   DROP PROCEDURE PROC_ETL_ACTOR;

-- CREATE THE STORED PROCEDURE 
CREATE PROCEDURE DBO.PROC_ETL_ACTOR
AS
BEGIN
  -- DECLARAÇÃO DAS VARIÁVEIS DE LOG E CONTROLE
  DECLARE
    --VARIÁVEIS DE TABELA
    @V_ACTOR_ID INT,
    @V_FIRST_NAME VARCHAR(25),
    @V_LAST_UPDATE DATETIME,
    
    --VARIÁVEIS DE CONTROLE DE DADOS PROCESSADOS
    @V_DSC_DADOS_PROCESSAMENTO VARCHAR(2000);

  -- DECLARAÇÃO DO CURSOR
  DECLARE CUR_GET_ACTOR CURSOR FOR
  SELECT
    ORIGEM.ACTOR_ID,
    ORIGEM.FIRST_NAME,
    ORIGEM.LAST_UPDATE
  FROM actor AS ORIGEM
  WHERE NOT EXISTS (SELECT DIM.ACTOR_ID
                    FROM DIM_ACTOR DIM
                    WHERE ORIGEM.ACTOR_ID = DIM.ACTOR_ID);

  -- ABRE CURSOR PARA EXECUÇÃO
  OPEN CUR_GET_ACTOR;

  -- CAPTURA PRIMEIRO REGISTRO PARA INICIAR O LOOP
  FETCH NEXT FROM CUR_GET_ACTOR
  INTO
    @V_ACTOR_ID,
    @V_FIRST_NAME,
    @V_LAST_UPDATE;

  -- LOOP QUE IRÁ EXECUTAR ENQUANTO HOUVER LINHAS NO CURSOR PARA SEREM PROCESSADAS
  WHILE (@@FETCH_STATUS = 0)
  BEGIN
    -- ATRIBUI VALORES PROCESSADOS
    SET @V_DSC_DADOS_PROCESSAMENTO = 'ACTOR_ID ' + CAST(@V_ACTOR_ID AS VARCHAR) + CHAR(13) + CHAR(10) +
                                     'FIRST_NAME ' + CAST(@V_FIRST_NAME AS VARCHAR);
                                     
    BEGIN TRANSACTION;
         INSERT INTO DIM_ACTOR
         (ACTOR_ID, FIRST_NAME, LAST_UPDATE)
         VALUES
         (@V_ACTOR_ID, @V_FIRST_NAME, @V_LAST_UPDATE);
           
         -- TRATAMENTO DE ERRO
         IF @@ERROR <> 0
         BEGIN
            ROLLBACK;
            -- EXIBE QUAL FOI O ÚLTIMO REGISTRO A SER PROCESSADO
            SELECT @V_DSC_DADOS_PROCESSAMENTO;
            -- FECHA CURSOR E LIBERA RECURSO DE MEMÓRIA
            CLOSE CUR_GET_ACTOR;
            DEALLOCATE CUR_GET_ACTOR;
            -- SAI DA SP
            RETURN;
         END -- IF
    COMMIT;
    
    -- CAPTURA PRÓXIMA LINHA DE REGISTROS PARA CONTINUAR O PROCESSAMENTO SE A REGRA DO LOOP AINDA ESTIVER VALENDO
    FETCH NEXT FROM CUR_GET_ACTOR
    INTO
      @V_ACTOR_ID,
      @V_FIRST_NAME,
      @V_LAST_UPDATE;
  END -- WHILE
  
  -- FECHA CURSOR E LIBERA RECURSO DE MEMÓRIA
  CLOSE CUR_GET_ACTOR;
  DEALLOCATE CUR_GET_ACTOR;
END;


EXEC PROC_ETL_ACTOR


SELECT * FROM DIM_ACTOR