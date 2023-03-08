# run: $ cat stations_id_names.sql | sqlite3 bikeshares.sqlite
SELECT DISTINCT name, id FROM v_stations WHERE LENGTH(name) != 0;