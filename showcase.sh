info() {
  echo "\033[0;32m$1\033[0m"
}

warn() {
  echo "\033[0;93m$1\033[0m"
}

error() {
  echo "\033[0;91m$1\033[0m" >&2
}

function install_docker(){
    if [[ "$(command -v docker)" == "" ]]; then
        mkdir ./script/docker/
        curl -fsSL https://get.docker.com -o ./script/docker/get-docker.sh
        sudo sh ./script/docker/get-docker.sh
    else
        info "[Check] Passed checking: docker."
    fi
}

function install_docker_compose(){
    if [[ "$(command -v docker-compose)" == "" ]]; then
        sudo apt-get update
        sudo apt-get install docker-compose-plugin
    else
        info "[Check] Passed checking: docker-compose."
    fi
}

function get_cpbl_opendata(){
    if [ -d "./cpbl-opendata/" ]; then
        info "[Check] Finish clone the cpbl-opendata."
    else
        git clone https://github.com/ldkrsi/cpbl-opendata.git
    fi
}

function import_csv_postgresql(){
    if [[ "$(command -v python3)" == "" ]]; then
        sudo apt-get update
        sudo apt-get install python3 python3-pip
    else
        info "[Check] Passed checking: docker-compose."
    fi
    
    pip3 install sqlalchemy pandas psycopg2-binary
    python3 ./script/postgresql/transfer_csv_postgresql.py
}

function install_dbt(){
    if [[ "$(command -v dbt)" == "" ]]; then
        pip3 install dbt
    else
        info "[Check] Passed checking: dbt."
    fi
}

function setting_dbt_profile(){
    if [ -d "~/.dbt/" ]; then
        info "[Check] Finish clone the cpbl-opendata."
    else
        dbt init
        read -p 'dbt project name: ' DBT_PROJECT_NAME
        sed -i '' 's/\[1 or more\]/1/g' ~/.dbt/profiles.yml
        sed -i '' 's/\[host\]/\localhost/g' ~/.dbt/profiles.yml
        sed -i '' 's/\[port\]/5432/g' ~/.dbt/profiles.yml
        sed -i '' 's/\[dev_username\]/cpbldatauser/g' ~/.dbt/profiles.yml
        sed -i '' 's/\[prod_username\]/cpbldatauser/g' ~/.dbt/profiles.yml
        sed -i '' 's/pass\:/password\:/g' ~/.dbt/profiles.yml
        sed -i '' 's/\[dev_password\]/cpbldatapassword/g' ~/.dbt/profiles.yml
        sed -i '' 's/\[prod_password\]/cpbldatapassword/g' ~/.dbt/profiles.yml
        sed -i '' 's/\[dbname\]/cpbl_data/g' ~/.dbt/profiles.yml
        sed -i '' 's/\[dev_schema\]/public/g' ~/.dbt/profiles.yml
        sed -i '' 's/\[prod_schema\]/public/g' ~/.dbt/profiles.yml
    fi

    
}

function dbt_transform(){
    cp -fR ./script/dbt_model/ ./$DBT_PROJECT_NAME/models/example/
    cp ./script/dbt_model/cfchen.sql ./$DBT_PROJECT_NAME/models/example/player.sql
    cd ./$DBT_PROJECT_NAME/
    dbt debug 2>&1 | tee debug.log
    if [[ "$(cat debug.log | grep 'All checks passed!')" == "[32mAll checks passed![0m" ]]; then
        dbt run
        dbt test
    else
        error "[ERROR] dbt debug error"
    fi
}

function install_piperider(){
    if [[ "$(command -v piperider)" == "" ]]; then
        pip3 install piperider
    else
        info "[Check] Passed checking: piperider."
    fi
}

function piperider_test(){
    pwd
    piperider init
    piperider diagnose
    piperider run
    cd ..
    cp ./script/dbt_model/cmpeng.sql ./$DBT_PROJECT_NAME/models/example/player.sql
    cd ./$DBT_PROJECT_NAME/
    dbt run
    piperider run
    piperider compare-reports
}

echo "Step 1: Install docker."
install_docker
echo "Step 2: Install docker-compose."
install_docker_compose
echo "Step 3: get CPBL opendata from Github."
get_cpbl_opendata
echo "Step 4: start postgresql service."
docker-compose -f script/postgresql/docker-compose.yaml down
docker-compose -f script/postgresql/docker-compose.yaml up -d
echo "Step 5: Import the csv data to postgresql database."
read -p 'PostgreSQL database IP address: ' POSTGRESQL_IP
echo $POSTGRESQL_IP
import_csv_postgresql
echo "Step 6: Install dbt"
install_dbt
echo "Step 7: Initial dbt and setting dbt profile."
setting_dbt_profile
echo "Step 8: Transfer the dbt files."
dbt_transform
echo "Step 9: Piperider testing."
install_piperider
piperider_test