def format_user_report(users):
    lines = []
    lines.append("ID | Name | Email | Status")
    lines.append("---|------|-------|--------")
    for user in users:
        status = "Active" if user["active"] else "Inactive"
        line = f"{user['id']} | {user['name']} | {user['email']} | {status}"
        lines.append(line)
    return "\n".join(lines)


def format_order_report(orders):
    lines = []
    lines.append("ID | Customer | Amount | Status")
    lines.append("---|----------|--------|--------")
    for order in orders:
        status = "Fulfilled" if order["fulfilled"] else "Pending"
        line = f"{order['id']} | {order['customer']} | {order['amount']} | {status}"
        lines.append(line)
    return "\n".join(lines)


def format_product_report(products):
    lines = []
    lines.append("ID | Name | Price | In Stock")
    lines.append("---|------|-------|----------")
    for product in products:
        status = "Yes" if product["in_stock"] else "No"
        line = f"{product['id']} | {product['name']} | {product['price']} | {status}"
        lines.append(line)
    return "\n".join(lines)


def calculate_order_total(orders):
    total = 0
    for order in orders:
        if order["quantity"] > 0 and order["price"] > 0:
            subtotal = order["quantity"] * order["price"]
            tax = subtotal * 0.1
            total = total + subtotal + tax
    return total


def calculate_invoice_total(invoices):
    total = 0
    for invoice in invoices:
        if invoice["hours"] > 0 and invoice["rate"] > 0:
            subtotal = invoice["hours"] * invoice["rate"]
            tax = subtotal * 0.1
            total = total + subtotal + tax
    return total


def validate_email(email):
    if not email or "@" not in email:
        return False
    parts = email.split("@")
    if len(parts) != 2:
        return False
    if not parts[0] or not parts[1]:
        return False
    return True


def validate_phone(phone):
    if not phone or len(phone) < 10:
        return False
    digits = "".join(c for c in phone if c.isdigit())
    if len(digits) < 10:
        return False
    return True