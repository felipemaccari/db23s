-- DROP TABLE IF EXISTS DIM_ADDRESS;
DROP TABLE IF EXISTS DIM_ADDRESS;

-- CRIAÇÃO DA TABELA DE DIMENSÃO ENDEREÇO
CREATE TABLE DIM_ADDRESS
(
  ADDRESS_ID INT IDENTITY(1,1) NOT NULL,  -- ID incremental
  ADDRESS VARCHAR(50) NOT NULL,           -- Endereço
  CONSTRAINT PKADDRESS_ID PRIMARY KEY (ADDRESS_ID ASC)
);

-- Bloco utilizado para verificar se a SP já existe. Se SIM, o banco fará um DROP da SP e irá recriar.
IF EXISTS (
  SELECT * 
  FROM INFORMATION_SCHEMA.ROUTINES 
  WHERE SPECIFIC_NAME = N'PROC_ETL_ADDRESS' 
)
  DROP PROCEDURE PROC_ETL_ADDRESS;

-- CREATE THE STORED PROCEDURE 
CREATE PROCEDURE DBO.PROC_ETL_ADDRESS
AS
BEGIN
  -- DECLARAÇÃO DAS VARIÁVEIS DE LOG E CONTROLE
  DECLARE
    @V_ADDRESS VARCHAR(50),
    @V_DSC_DADOS_PROCESSAMENTO VARCHAR(2000);

  -- DECLARAÇÃO DO CURSOR
  DECLARE CUR_GET_ADDRESS CURSOR FOR
  SELECT ORIGEM.ADDRESS
  FROM address AS ORIGEM
  WHERE NOT EXISTS (SELECT 1
                    FROM DIM_ADDRESS DIM
                    WHERE ORIGEM.ADDRESS = DIM.ADDRESS);

  -- ABRE CURSOR PARA EXECUÇÃO
  OPEN CUR_GET_ADDRESS;

  -- CAPTURA PRIMEIRO REGISTRO PARA INICIAR O LOOP
  FETCH NEXT FROM CUR_GET_ADDRESS INTO @V_ADDRESS;

  -- LOOP QUE IRÁ EXECUTAR ENQUANTO HOUVER LINHAS NO CURSOR PARA SEREM PROCESSADAS
  WHILE (@@FETCH_STATUS = 0)
  BEGIN
    -- ATRIBUI VALORES PROCESSADOS
    SET @V_DSC_DADOS_PROCESSAMENTO = 'ADDRESS ' + CAST(@V_ADDRESS AS VARCHAR);
    
    BEGIN TRANSACTION;
         INSERT INTO DIM_ADDRESS (ADDRESS)
         VALUES (@V_ADDRESS);

         -- TRATAMENTO DE ERRO
         IF @@ERROR <> 0
         BEGIN
            ROLLBACK;
            -- EXIBE QUAL FOI O ÚLTIMO REGISTRO A SER PROCESSADO
            SELECT @V_DSC_DADOS_PROCESSAMENTO;
            -- FECHA CURSOR E LIBERA RECURSO DE MEMÓRIA
            CLOSE CUR_GET_ADDRESS;
            DEALLOCATE CUR_GET_ADDRESS;
            -- SAI DA SP
            RETURN;
         END -- IF
    COMMIT;

    -- CAPTURA PRÓXIMA LINHA DE REGISTROS PARA CONTINUAR O PROCESSAMENTO
    FETCH NEXT FROM CUR_GET_ADDRESS INTO @V_ADDRESS;
  END -- WHILE

  -- FECHA CURSOR E LIBERA RECURSO DE MEMÓRIA
  CLOSE CUR_GET_ADDRESS;
  DEALLOCATE CUR_GET_ADDRESS;
END;


-- EXECUTAR PROCEDURE PARA POPULAR A TABELA DIM_ADDRESS
EXEC PROC_ETL_ADDRESS;

-- VERIFICAR OS RESULTADOS
SELECT * FROM DIM_ADDRESS;
