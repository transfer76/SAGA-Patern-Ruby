from flask import Flask, request
from db import DB

app = Flask(__name__)

db = DB()

# Done
@app.route("/brew/<id>/migrate",  methods=["POST"])
def done(id):
    db.update(id, 1)
    brew = db.show(id)

    return { "data": brew }, 201

# Undone
@app.route("/brew/<id>/revert",  methods=["POST"])
def undone(id):
    db.update(id, 0)
    brew = db.show(id)

    return { "data": brew }, 201

# Create brew
@app.route("/brew/",  methods=["POST"])
def create_brew():
    db.create()

    return {}, 201

# Fetch all brew
@app.route("/brew/",  methods=["GET"])
def list_brew():
    brew = db.index()

    return { "data": brew }, 200
