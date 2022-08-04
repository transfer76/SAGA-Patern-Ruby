import psycopg2

class DB:
    def __init__(self):
        self.connection = psycopg2.connect(
            host='localhost',
            database='postgres',
            user='postgres',
            password='postgres'
        )

        self.cursor = self.connection.cursor()

        self.cursor.execute('DROP TABLE IF EXISTS beans;')
        self.cursor.execute('CREATE TABLE beans (id serial PRIMARY KEY,'
                                 'roasted int NOT NULL,'
                                 'created_at date DEFAULT CURRENT_TIMESTAMP,'
                                 'updated_at date DEFAULT CURRENT_TIMESTAMP);'
                                 )

        self.cursor.execute('INSERT INTO beans(roasted) VALUES (0);')
        self.cursor.execute('INSERT INTO beans(roasted) VALUES (0);')
        self.cursor.execute('INSERT INTO beans(roasted) VALUES (0);')
        self.cursor.execute('INSERT INTO beans(roasted) VALUES (0);')
        self.cursor.execute('INSERT INTO beans(roasted) VALUES (0);')

        self.connection.commit()

    def create(self):
        self.cursor.execute('INSERT INTO beans(roasted) VALUES (0);')
        self.connection.commit()

        return True

    def update(self, id, roasted):
        statement = "UPDATE beans SET roasted = {} WHERE id = {};".format(roasted, id)
        self.cursor.execute(statement)
        self.connection.commit()

        return True

    def index(self):
        statement = "SELECT * FROM beans ORDER BY id;"

        self.cursor.execute(statement)
        return self.cursor.fetchall()

    def show(self, id):
        statement = "SELECT * FROM beans WHERE id = {};".format(id)

        self.cursor.execute(statement)
        return self.cursor.fetchone()
