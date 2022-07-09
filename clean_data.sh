docker-compose -f script/postgresql/docker-compose.yaml down
rm -rf ~/.dbt logs cpbl-opendata .piperider/
read -p 'dbt project name: ' DBT_PROJECT_NAME
rm -rf $DBT_PROJECT_NAME