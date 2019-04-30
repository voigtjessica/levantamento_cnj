# Planilha da avaliação da Tbrasil para as obras de escolas e creches financiadas pelo Proinfância.

library(dplyr)
library(data.table)
library(janitor)
library(tidyr)
library(scales)
library(readr)
library(stringr)
library(googledrive)
library(RPostgreSQL)

#funçõezinhas que eu vou usar:

teste_igualdade_nomes_var_df <- function(base1, base2) {
  
  x <- names(base1)
  y <- names(base2)
  n <- length(x)
  k <- length(y)
  
  teste_nome_igual_x <- numeric()
  teste_nome_igual_y <- numeric()
  
  for ( i in 1:n) {
    teste_nome_igual_x[i] <- x[i] %in% y
  }
  
  for ( i in 1:k) {
    teste_nome_igual_y[i] <- y[i] %in% x
  }
  resp_x <- paste(x[!as.logical(teste_nome_igual_x)], collapse = ", ")
  resp_y <- paste(y[!as.logical(teste_nome_igual_y)], collapse = ", ")
  
  cat(paste("Colunas de", deparse(substitute(base1)), "ausentes em" , 
            deparse(substitute(base2)), ":", resp_x,
            ".\n\nColunas de", deparse(substitute(base2)), "ausentes em" ,
            deparse(substitute(base1)), ":", resp_y,
            sep=" "))
  
}

`%notin%` = function(x,y) !(x %in% y)

perc <- function(x) { 
  paste0(round(x,2)*100, "%")
}

#Obras de novembro coletadas no SIMEC do FNDE:
setwd("C:/Users/coliv/Documents/Levantamento CNJ")
obras <- fread("obras2019-04-23.csv",sep=";", colClasses = "character", encoding = "UTF-8") %>%
  clean_names()

#Filtros:

#retirando obras que não são construção de escolas e creches:
not_project<- c("COBERTURA DE QUADRA ESCOLAR - PROJETO PRÓPRIO",
                "COBERTURA DE QUADRA ESCOLAR GRANDE - PROJETO FNDE",
                "COBERTURA DE QUADRA ESCOLAR PEQUENA - PROJETO FNDE",
                "QUADRA ESCOLAR COBERTA - PROJETO PRÓPRIO ",
                "QUADRA ESCOLAR COBERTA COM VESTIÁRIO- PROJETO FNDE",
                "Reforma",
                "QUADRA ESCOLAR COBERTA - PROJETO PRÓPRIO",
                "Ampliação",
                "QUADRA ESCOLAR COBERTA COM PALCO- PROJETO FNDE",
                "Quadra Escolar Coberta e Vestiário - Modelo 2",
                "Ampliação Módulo Tipo B", 
                "")

#  Tempo de execução dos projetos-padrão (info obtida via LAI)
tempo_projeto <- data.frame(tipo_do_projeto = c("Escola de Educação Infantil Tipo B",
                                                "Escola de Educação Infantil Tipo C",
                                                "MI - Escola de Educação Infantil Tipo B",
                                                "MI - Escola de Educação Infantil Tipo C",
                                                "Espaço Educativo - 12 Salas",
                                                "Espaço Educativo - 01 Sala",
                                                "Espaço Educativo - 02 Salas",
                                                "Espaço Educativo - 04 Salas",
                                                "Espaço Educativo - 06 Salas",
                                                "Projeto 1 Convencional",
                                                "Projeto 2 Convencional",
                                                "Construção",
                                                "Escola com projeto elaborado pelo concedente",
                                                "Escola com Projeto elaborado pelo proponente",
                                                "Espaço Educativo - 08 Salas",
                                                "Espaço Educativo Ensino Médio Profissionalizante"),
                            tempo_execucao_dias = c(270,180,180,120,390,150,150,210,210,
                                                    330,270,720,720,720,720,720))

execucao_cronogramas_lai <- fread("tempo_obra.csv") %>%
  mutate(project_id = as.character(project_id),
         tempo_obra_dias = tempo_obra*30) %>%
  rename(tempo_obra_dias_via_lai = tempo_obra_dias) %>%
  select(1,3)

#Crianco objeto geral:
# Objeto geral:

x <- as.Date("1900-01-01")

geral <- obras %>%
  filter(tipo_do_projeto %notin% not_project) %>% #apenas constru de esc e creches
  rename(responsabilidade = rede_de_ensino_publico) %>%
  left_join(execucao_cronogramas_lai, by=c("id" = "project_id")) %>% #infos que pegamos via lai
  left_join(tempo_projeto, by=c("tipo_do_projeto")) %>%      #tempo que o projeto padrão dura
  mutate(id = as.character(id),
         data_de_assinatura_do_contrato = as.Date(data_de_assinatura_do_contrato, format="%Y-%m-%d %H:%M:%S"),
         data_prevista_de_conclusao_da_obra= as.Date(data_prevista_de_conclusao_da_obra, format="%d/%m/%Y"),
         final_previsto = if_else(!is.na(data_prevista_de_conclusao_da_obra), data_prevista_de_conclusao_da_obra, 
                                  if_else(is.na(data_prevista_de_conclusao_da_obra) & 
                                            !is.na(tempo_obra_dias_via_lai), data_de_assinatura_do_contrato + tempo_obra_dias_via_lai, 
                                          if_else(is.na(data_prevista_de_conclusao_da_obra) & 
                                                    is.na(tempo_obra_dias_via_lai),
                                                  data_de_assinatura_do_contrato + tempo_execucao_dias, x))),
         tipo_data_final = ifelse(!is.na(data_prevista_de_conclusao_da_obra), "Data oficial",
                                  ifelse(is.na(data_prevista_de_conclusao_da_obra) & 
                                           !is.na(tempo_obra_dias_via_lai), "Estimada (data contrato + execução segundo pref)",
                                         ifelse(is.na(data_prevista_de_conclusao_da_obra) & 
                                                  is.na(tempo_obra_dias_via_lai) &
                                                  !is.na(tempo_execucao_dias), "Estimada (data contrato + execução cron padrão)", NA ))),
         # Status segundo TB
         percentual_de_execucao = as.numeric(percentual_de_execucao),
         nao_iniciada = ifelse( percentual_de_execucao == 0 & !situacao %in%
                                  c("Inacabada","Paralisada", "Obra Cancelada", "Concluída" ), 1, 0),
         paralisada_off = ifelse(situacao %in% c("Inacabada","Paralisada"), 1, 0),
         paralisada_nao_off = if_else(!is.na(data_de_assinatura_do_contrato) & situacao != "Execução" & nao_iniciada == 0|
                                        percentual_de_execucao > 0 & situacao != "Execução"  & nao_iniciada == 0|
                                        !is.na(data_prevista_de_conclusao_da_obra) & nao_iniciada == 0 & situacao %in% c("Licitação", "Em Reformulação","Contratação", 
                                                                                                                         "Planejamento pelo proponente"),
                                      1 , 0),
         paralisada_nao_off = ifelse(situacao %in% c("Obra Cancelada", "Concluída",
                                                     "Inacabada","Paralisada"), 0, paralisada_nao_off), #retirando concluidas e canceladas
         paralisada = ifelse(paralisada_nao_off == 1 | paralisada_off == 1, 1, 0),
         concluida = ifelse(situacao == "Concluída", 1, 0),
         cancelada = ifelse(situacao == "Obra Cancelada", 1, 0),
         atrasada = if_else(final_previsto < "2018-11-21" & situacao %notin% c("Concluída","Obra Cancelada"),
                            1, 0),
         atrasada = if_else(is.na(final_previsto), 0, atrasada),
         execucao = if_else(situacao == "Execução" & nao_iniciada == 0 , 1, 0),
         responsabilidade = as.character(responsabilidade),
         responsabilidade = if_else(id == "1063221" | id == "29054",
                                    "Municipal", responsabilidade),
         logradouro = tolower(logradouro),
         logradouro = str_trim(logradouro), # retirar espaços no fim
         logradouro = ifelse(logradouro=="", NA, logradouro),
         sem_end = if_else(is.na(logradouro), 1, 0), #obras que não tÊm endereço.
         #problema detectado:
         problema_detectado = ifelse(paralisada == 1 & sem_end == 1, #obras com problemas
                                     "paralisada; sem endereço",
                                     if_else(paralisada == 1 & atrasada == 1, "paralisada; atrasada",
                                             ifelse(paralisada == 1 & atrasada == 0, "paralisada",
                                                    ifelse(atrasada == 1 & sem_end == 1, "atrasada; sem endereço",
                                                           ifelse(atrasada == 1 & paralisada == 0, "atrasada",
                                                                  ifelse(sem_end == 1, "sem endereço",
                                                                         NA))))))) %>%
  #criando uma coluna de status para facilitar a vida:
  mutate(status = ifelse(paralisada == 1, "paralisada",
                         ifelse(cancelada == 1, "cancelada",
                                ifelse(nao_iniciada == 1, "não iniciada",
                                       ifelse(concluida == 1, "concluida",
                                              ifelse(execucao == 1, "execucao", "ERROOOOOOO"))))),
         situacao_segundo_tbrasil = ifelse(paralisada == 1 & atrasada == 0, "paralisada",
                                           ifelse(paralisada == 1 & atrasada == 1, "paralisada e já devia ter sido entregue",
                                                  ifelse(execucao == 1 & atrasada == 1, "em andamento e já devia ter sido entregue",
                                                         ifelse(execucao == 1 & atrasada == 0, "em andamento",
                                                                ifelse(concluida == 1, "obra concluída",
                                                                       ifelse(cancelada == 1, "obra cancelada",
                                                                              ifelse(nao_iniciada == 1 & atrasada == 0, "não iniciada",
                                                                                     ifelse(nao_iniciada == 1 & atrasada == 1,
                                                                                            "não iniciada e já devia ter sido entregue", "ERROOOOOO")))))))),
         logradouro = ifelse(is.na(logradouro), "Não informado", logradouro),
         ano_convenio = str_sub(termo_convenio, start= -4),
         ano_fim_vigencia_convenio = str_sub(fim_da_vigencia_termo_convenio, start= -4),
         ano_data_final_prevista_e_estimada = str_sub(final_previsto, 1, 4),
         fim_da_vigencia_termo_convenio = ifelse(fim_da_vigencia_termo_convenio == "", NA,
                                                 fim_da_vigencia_termo_convenio)) %>%
  select(id, nome, municipio, uf, responsabilidade, situacao, situacao_segundo_tbrasil, logradouro,percentual_de_execucao,
         ano_convenio, valor_pactuado_com_o_fnde, ano_fim_vigencia_convenio, termo_convenio,
         data_prevista_de_conclusao_da_obra, final_previsto, tipo_data_final, ano_data_final_prevista_e_estimada, 
         tipo_do_projeto) %>%
  rename(status_segundo_simec = situacao,
         data_final_prevista_e_estimada = final_previsto)  


# Agora um objeto para as respostas, para saber, para essas obras, o que as prefeituras / gov federal responderam:

#Conectando com a aplicação
pg = dbDriver("PostgreSQL")

con = dbConnect(pg,
                user="read_only_user", password="pandoapps",
                host ="aag6rh5j94aivq.cxbz7geveept.sa-east-1.rds.amazonaws.com",
                port = 5432, dbname="ebdb")

# Contatos, para que eu saiba futuramente quem respondeu:
contatos_sheet <- gs_title("planilha_contatos_producao_tdp")

contatos_tdp <- gs_read(contatos_sheet) %>%
  clean_names() %>%
  select(id, responsavel, municipio, uf ) %>%
  mutate_all(as.character)

# Bancos (auto-explicativos)
projetos = dbGetQuery(con, "SELECT * FROM projects")
location_cities = dbGetQuery(con, "SELECT * FROM location_cities")
location_states = dbGetQuery(con, "SELECT * FROM location_states")

respostas = dbGetQuery(con, "SELECT * FROM answers") %>%
  rename(answer_id= id,
         answer_date = created_at) %>%
  mutate_all(as.character) %>%
  select(answer_id, message_id, content, answer_date)

Encoding(respostas$content) <- "UTF-8"

messages <- dbGetQuery(con, "SELECT * FROM messages") %>%
  rename(message_id = id) %>%
  select(message_id, inspection_id, contact_id, e_ouv_protocol_number) %>%
  mutate_all(as.character)

inspections <- dbGetQuery(con, "SELECT * FROM inspections") %>%
  filter(is.na(deleted_at),          #tirando as deletadas
         !status %in% c(6, 2)) %>%
  mutate_all(as.character) %>%
  rename(inspection_id = id,
         inspection_date = created_at) %>%
  select(inspection_id, project_id, inspection_date) 

possui_alerta <- unique(inspections$project_id)

info_obra <- geral %>%
  select(id, status_segundo_simec, situacao_segundo_tbrasil)

resp_final <- respostas %>%
  left_join(messages, by=c("message_id")) %>%
  left_join(inspections, by=c("inspection_id")) %>%
  filter(!is.na(project_id)) %>%
  left_join(contatos_tdp, by=c("contact_id" = "id")) %>%
  left_join(info_obra, by=c("project_id" = "id")) %>%
  select(project_id, status_segundo_simec, situacao_segundo_tbrasil,
         inspection_id, inspection_date, responsavel, municipio, uf,
         content, answer_date)

possui_resposta <- unique(resp_final$project_id)

geral <- geral %>%
  mutate(possui_alerta = ifelse(id %in% possui_alerta, 1, 0),
         possui_resposta = ifelse(id %in% possui_resposta, 1, 0)) %>%
  rename(project_id = id,
         data_de_entrega = data_final_prevista_e_estimada) %>%
  select(-c(ano_data_final_prevista_e_estimada, data_prevista_de_conclusao_da_obra))

fwrite(geral, file="info_obras_proinfancia.csv")
fwrite(resp_final, file="info_respostas_alertas.csv")
