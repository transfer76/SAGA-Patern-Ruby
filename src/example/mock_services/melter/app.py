from flask import Flask
from db import DB

app = Flask(__name__)

db = DB()

# Melt grounds
@app.route("/grounds/<id>/migrate",  methods=["PUT"])
def melt(id):
    db.update(id, 1)
    grounds = db.show(id)

    return { "data": grounds }, 201

# Unmelt grounds
@app.route("/grounds/<id>/revert",  methods=["PUT"])
def unmelt(id):
    db.update(id, 0)
    grounds = db.show(id)

    return { "data": grounds }, 201

# Create grounds
@app.route("/grounds/",  methods=["POST"])
def create_grounds():
    db.create()

    return {}, 201

# Fetch all grounds
@app.route("/grounds/",  methods=["GET"])
def list_grounds():
    grounds = db.index()

    return { "data": grounds }, 200
