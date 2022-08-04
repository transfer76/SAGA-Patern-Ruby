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

        self.cursor.execute('DROP TABLE IF EXISTS brew;')
        self.cursor.execute('CREATE TABLE brew (id serial PRIMARY KEY,'
                                 'done int NOT NULL,'
                                 'created_at date DEFAULT CURRENT_TIMESTAMP,'
                                 'updated_at date DEFAULT CURRENT_TIMESTAMP);'
                                 )

        self.cursor.execute('INSERT INTO brew(done) VALUES (0);')
        self.cursor.execute('INSERT INTO brew(done) VALUES (0);')
        self.cursor.execute('INSERT INTO brew(done) VALUES (0);')
        self.cursor.execute('INSERT INTO brew(done) VALUES (0);')
        self.cursor.execute('INSERT INTO brew(done) VALUES (0);')

        self.connection.commit()

    def create(self):
        self.cursor.execute('INSERT INTO brew(done) VALUES (0);')
        self.connection.commit()

        return True

    def update(self, id, done):
        statement = "UPDATE brew SET done = {} WHERE id = {};".format(done, id)
        self.cursor.execute(statement)
        self.connection.commit()

        return True

    def index(self):
        statement = "SELECT * FROM brew ORDER BY id;"

        self.cursor.execute(statement)
        return self.cursor.fetchall()

    def show(self, id):
        statement = "SELECT * FROM brew WHERE id = {};".format(id)

        self.cursor.execute(statement)
        return self.cursor.fetchone()
