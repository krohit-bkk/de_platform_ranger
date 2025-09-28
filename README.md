### How to run
1. Setup the environment variables
- Registers the functions and aliases
- Setup the `PROJECT_ROOT` and builds `.env.evaluated` file
```shell
source setup.sh
bash setup.sh
```

2. Starting the services
- Launch the services manually
    - Please maintain the order of launching the services
        - **base** -> command: `start_base`
        - **vault** -> command: `start_vault`
        - **minio** -> command: `start_minio`
        - **hive-metastore** -> command: `start_hms`
        - **hiveserver2** -> command: `start_hs2`
        - **spark-history-server** -> command: `start_sparkhistory`
        - **spark-master**, **spark-worker-1**, **spark-worker-2** -> command: `start_spark`
            - **spark-test** -> command: `spark_test`
            - **delta-lake-test** -> command: `deltalake_test`
        - **trino-coordinator**, **trino-worker-1**, **trino-worker-2** -> command: `start_trino`
            - **trino-test** -> command: `TBS`

- Launch the services automatically
    - Ensures the order of execution as mentioned above -> command: `start_all`

3. Stopping the services
- Stop all the services in the reverese order of launching the services -> command: `stop_all` 

4. Wipe everything & Reset
- Kill & delete all services -> command: `wipe_everything`
    - ⚠️ **Caution**
        - This function deletes all containers which are listed in `docker ps -a`!
        - If working on multiple projects in your docker setup, the above command would kill all of the containers!
    

To do:

-> [DONE] Standardize the Key/Value pairs in vault.

-> [DONE] HMS & MinIO service related naming convension is not consistent

-> [DONE] Once changed, to unit and integration test across all components

-> [TBD ] Start applying access control for managing users in each service

-> [TBD ] Start exploring exposing local storage/volume via s3 protocol using Apache Ceph (maybe)



    