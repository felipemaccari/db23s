-- DROP DA TABELA FATURA CASO JÁ EXISTA
DROP TABLE IF EXISTS FT_RENTAL;

-- CRIAÇÃO DA TABELA FATO FT_RENTAL
CREATE TABLE FT_RENTAL (
    TIME INT NULL DEFAULT 0,                  -- Chave Tempo
    FILM_ID INT NULL,                             -- Chave do Filme
    CATEGORY_ID INT NULL,                         -- Chave da Categoria
    CUSTOMER_ID INT NULL,                         -- Chave do Cliente
    STAFF_ID INT NULL,                            -- Chave do Funcionário
    STORE_ID INT NULL,                            -- Chave da Loja
    INVENTORY_ID INT NULL,                        -- Chave do Inventário
    ACTOR_ID INT NULL,                            -- Chave do Ator (nova coluna)
    QUANTITY INT NOT NULL,                        -- Quantidade de Aluguéis
    AMOUNT DECIMAL(10, 2) NOT NULL DEFAULT 0.00,  -- Valor Total do Aluguel
    STATUS_PAGAMENTO VARCHAR(20),                 -- Status do Pagamento (Pago/Não Pago)
    LUCRO_PREJUIZO DECIMAL(10, 2)                 -- Lucro ou Prejuízo
);

-- Verificar se a Procedure já existe, se SIM, fazer o DROP e recriar
IF EXISTS (
  SELECT * 
  FROM INFORMATION_SCHEMA.ROUTINES 
  WHERE SPECIFIC_NAME = N'PROC_ETL_FT_RENTAL' 
)
  DROP PROCEDURE PROC_ETL_FT_RENTAL;

EXEC DBO.PROC_ETL_FT_RENTAL_ANALISE1;
EXEC DBO.PROC_ETL_FT_RENTAL_ANALISE2;
EXEC DBO.PROC_ETL_FT_RENTAL_ANALISE3;
EXEC DBO.PROC_ETL_FT_RENTAL_ANALISE4;
EXEC DBO.PROC_ETL_FT_RENTAL_ANALISE5;
