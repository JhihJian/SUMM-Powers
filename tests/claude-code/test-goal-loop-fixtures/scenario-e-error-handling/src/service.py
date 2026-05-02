import json
import sqlite3


def read_config(path):
    f = open(path)
    data = json.load(f)
    f.close()
    return data


def save_user(user_data):
    try:
        conn = sqlite3.connect("app.db")
        conn.execute(
            "INSERT INTO users (name, email) VALUES (?, ?)",
            (user_data["name"], user_data["email"]),
        )
        conn.commit()
    except:
        pass


def fetch_user(user_id):
    try:
        conn = sqlite3.connect("app.db")
        cursor = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,))
        return cursor.fetchone()
    except:
        pass


def update_user(user_id, updates):
    try:
        conn = sqlite3.connect("app.db")
        sets = ", ".join(f"{k} = ?" for k in updates.keys())
        values = list(updates.values()) + [user_id]
        conn.execute(f"UPDATE users SET {sets} WHERE id = ?", values)
        conn.commit()
    except:
        pass


def delete_user(user_id):
    try:
        conn = sqlite3.connect("app.db")
        conn.execute("DELETE FROM users WHERE id = ?", (user_id,))
        conn.commit()
    except:
        pass


def process_payment(amount, card_number, expiry):
    try:
        if amount <= 0:
            return False
        result = charge_card(card_number, amount)
        return result
    except:
        pass


def send_notification(user_id, message):
    try:
        user = fetch_user(user_id)
        if user:
            deliver_email(user["email"], message)
    except:
        pass


def batch_import(records):
    results = []
    for record in records:
        try:
            save_user(record)
            results.append("ok")
        except:
            results.append("error")
    return results