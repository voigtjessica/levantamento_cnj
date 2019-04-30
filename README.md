# Levantamento CNJ

**Descrição do repositório:** Dados levantados para o CNJ das obras do Proinfância 30/04/2019

Esse repositório contem uma pasta "interna" com a reprodução dos códigos utilizados e dois bancos formato .CSV, separador "," : 

* **info_obras_proinfancia.csv:** contém informações sobre todas as obras de construção de escolas e creches pactuadas pelo PROINFÂNCIA. A tabela contém tanto informações oficiais, disponibilizadas pelo ente executor da obra no SIMEC, quanto informações geradas pela Transparência Brasil (ver mais no codebook abaixo);
* **info_respostas_alertas.csv:** contém informações sobre respostas fornecidas pelo poder público aos alertas enviados pela Transparência Brasil.

-----

# Codebooks

### 1.info_obras_proinfancia

|Variável|Descrição|
|:----:|:---|
|project_id| Id do projeto, de acordo com o FNDE |
|nome| Nome da obra, de acordo com o FNDE|
|municipio| Município onde se encontra a obra|
|uf| Unidade federativa onde se encontra a obra|
|responsabilidade| Ente responsável pela licitação e execução da obra|
|status_segundo_simec| Status da obra em 24/04/2019, de acordo com o SIMEC|
|situacao_segundo_tbrasil| Status da obra, de acordo com a checagem da Transparência Brasil|
|logradouro|Logradouro da obra, de acordo com as informações do FNDE |         
|percentual_de_execucao| percentual de execução da obra em 24/04/2019, de acordo com o SIMEC|
|ano_convenio| Ano em que foi estabelecido o convênio entre o ente executor e o FNDE|
|valor_pactuado_com_o_fnde| Valor pactuado com o FNDE para o convênio|
|ano_fim_vigencia_convenio| Ano do fim da vigência do convênio entre o ente executor e o FNDE|     
|termo_convenio| Termo / Convênio entre ente executor e governo federal|
|data_de_entrega| Data de entrega da obra|
|tipo_data_final| Estabelece se a data de entrega da obra é oficial ou foi estimada, podendo adotar os seguintes valores:|
|  | *Data oficial* : data disponibilizada pelo FNDE|
|  | *Estimada (data contrato + execução cron padrão)* : Data estimada pela Transparência Brasil, baseada na data de assinatura de contrato para a execução da obra, disponibilizada pelo FNDE, e o tempo de execução da obra segundo o cronograma padrão disponibilizado pelo FNDE.|
|   | *Estimada (data contrato + execução segundo pref)* : Data estimada pela Transparência Brasil, baseada na data de assinatura de contrato para a execução da obra, disponibilizada pelo FNDE, e o tempo de execução da obra segundo o cronograma da obra obtido com o ente executor via Lei de Acesso à Informação.|
|   |*NA* : Quando não foi possível estimar a data de entrega da obra devido à ausência de informações sobre assinatura de contrato e/ou tempo de execução da obra.|
|tipo_do_projeto| Tipo arquitetônico do projeto, segundo SIMEC|                
|possui_alerta| Se foi feito pelo menos um alerta para essa obra pelo projeto Tá de Pé|
|possui_resposta| Se recebemos do governo ao menos uma resposta para o projeto Tá de Pé|  
