from flask import Flask, request, jsonify
import sqlite3
import hashlib
import json

app = Flask(__name__)

DATABASE = "app.db"


def get_db():
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row
    return conn


@app.route("/users", methods=["GET"])
def get_users():
    conn = get_db()
    cursor = conn.execute("SELECT * FROM users")
    users = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return jsonify(users)


@app.route("/users", methods=["POST"])
def create_user():
    data = request.get_json()
    conn = get_db()
    hashed_pw = hashlib.md5(data["password"].encode()).hexdigest()
    conn.execute(
        "INSERT INTO users (name, email, password) VALUES (?, ?, ?)",
        (data["name"], data["email"], hashed_pw),
    )
    conn.commit()
    conn.close()
    return jsonify({"status": "created"}), 201


@app.route("/users/<int:user_id>", methods=["GET"])
def get_user(user_id):
    conn = get_db()
    cursor = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    user = cursor.fetchone()
    conn.close()
    if user:
        return jsonify(dict(user))
    return jsonify({"error": "not found"}), 404


@app.route("/orders", methods=["GET"])
def get_orders():
    conn = get_db()
    user_id = request.args.get("user_id")
    if user_id:
        cursor = conn.execute("SELECT * FROM orders WHERE user_id = ?", (user_id,))
    else:
        cursor = conn.execute("SELECT * FROM orders")
    orders = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return jsonify(orders)


@app.route("/orders", methods=["POST"])
def create_order():
    data = request.get_json()
    conn = get_db()
    total = sum(item["price"] * item["quantity"] for item in data["items"])
    conn.execute(
        "INSERT INTO orders (user_id, items, total) VALUES (?, ?, ?)",
        (data["user_id"], json.dumps(data["items"]), total),
    )
    conn.commit()
    conn.close()
    return jsonify({"status": "created", "total": total}), 201


@app.route("/report/sales", methods=["GET"])
def sales_report():
    conn = get_db()
    cursor = conn.execute(
        "SELECT user_id, SUM(total) as total_sales FROM orders GROUP BY user_id"
    )
    report = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return jsonify(report)


if __name__ == "__main__":
    app.run(debug=True)