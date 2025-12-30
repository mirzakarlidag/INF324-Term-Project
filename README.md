# INF324-Term-Project

This project contains all source code and documentation for the term project of INF 324 course. A Github repository is created to maintain and show the progress of the project. You can access the repository with the link below:

[Github Repo Link](https://github.com/mirzakarlidag/INF324-Term-Project)

Source code can be found in "src/" folder. I decided to use postgresql on docker. Below resources helped me to get started:

* [Source-1](https://medium.com/@aedemirsen/execute-sql-commands-at-postgresql-db-startup-with-docker-2be0abadec48)
* [Source-2](https://docs.docker.com/guides/pgadmin/)

pgAdmin used in this project since it is PostgreSQL's official tool and serves as GUI. "src/init.sql"is used to easily create tables and indexes. Using commands below anyone can create the database system from scratch:

```bash
docker-compose up -d # to run the containers

docker-compose down # to destroy the containers
```

Locate "http://localhost/" to access pgAdmin GUI.