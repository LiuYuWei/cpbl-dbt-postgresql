 #-*-coding:utf-8 -*-
import os
import glob
import pandas as pd
from sqlalchemy import create_engine

postgresql_ip = os.getenv("postgresql_ip", default = "localhost") 
postgresql_port = "5432"
postgresql_account = "cpbldatauser"
postgresql_password = "cpbldatapassword"
postgresql_database = "cpbl_data"

with create_engine("postgresql+psycopg2://{}:{}@{}:{}".format(
    postgresql_account, postgresql_password, postgresql_ip, postgresql_port), isolation_level='AUTOCOMMIT'
).connect() as connection:
    connection.execute('CREATE DATABASE {}'.format(postgresql_database))

engine = create_engine("postgresql+psycopg2://{}:{}@{}:{}/{}".format(
    postgresql_account, postgresql_password, postgresql_ip, postgresql_port, postgresql_database), echo=False)

player_type_list = ["battings", "fieldings", "pitchings"]
game_level_list = ["CPBL", "CPBLFarm", "winter"]
game_level_list_chi = ["一軍", "二軍", "冬盟"]

frame = {}

for game_level, game_level_chi in zip(game_level_list, game_level_list_chi):
    frame[game_level] = {}
    for player_type in player_type_list:
        path = './cpbl-opendata/{}/{}/'.format(game_level, player_type)
        all_files = glob.glob(os.path.join(path , "*.csv"))

        li = []

        for filename in all_files:
            df = pd.read_csv(filename, index_col=None, header=0)
            df['Year'] = filename.split("/")[3].split(".")[0]
            df['Game Level'] = game_level_chi
            li.append(df)

        frame[game_level][player_type] = pd.concat(li, axis=0, ignore_index=True)
        frame[game_level][player_type].columns = [name.lower() for name in list(frame[game_level][player_type].keys())]
        print("===========================")
        print("Game level: {}; player_type: {}".format(game_level, player_type))
        print("---------------------------")
        print(frame[game_level][player_type])

for game_level in game_level_list:
    for player_type in player_type_list:
        print("===========================")
        print("Game level: {}; player_type: {}".format(game_level, player_type))
        frame[game_level][player_type].to_sql(
            name="{}_{}".format(player_type, game_level.lower()), con=engine, 
                                if_exists='append', index=False, chunksize=10000
        )

frame = {}

for game_level in game_level_list:
    table_name = "standings_{}".format(game_level.lower())
    frame[table_name] = pd.read_csv(
        "./cpbl-opendata/{}/standings.csv".format(game_level), index_col=None, header=0)
    frame[table_name].columns = [name.lower() for name in list(frame[table_name].keys())]
    frame[table_name].to_sql(name=table_name, con=engine, if_exists='append', index=False, chunksize=10000)

print("-----------")
print("pgadmin: http://{}:5000".format(postgresql_ip))
print("-----------")
print("Login account: {}".format("pgadmin4@pgadmin.org"))
print("Login password: {}".format("admin"))
print("Database name: {}".format(postgresql_database))
print("-----------")
