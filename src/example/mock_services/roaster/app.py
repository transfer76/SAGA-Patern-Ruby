from flask import Flask
from db import DB

app = Flask(__name__)

db = DB()

# Roast bean
@app.route("/beans/<id>/migrate",  methods=["PUT"])
def roast(id):
    db.update(id, 1)
    bean = db.show(id)

    return { "data": bean }, 201

# Unroast bean
@app.route("/beans/<id>/revert",  methods=["PUT"])
def unroast(id):
    db.update(id, 0)
    bean = db.show(id)

    return { "data": bean }, 201

# Create bean
@app.route("/beans/",  methods=["POST"])
def create_bean():
    db.create()

    return {}, 201

# Fetch all beans
@app.route("/beans/",  methods=["GET"])
def list_beans():
    beans = db.index()

    return { "data": beans }, 200
