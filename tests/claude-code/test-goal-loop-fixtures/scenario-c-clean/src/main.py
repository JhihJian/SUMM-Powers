"""Clean Python module with no lint issues."""


def calculate_sum(numbers: list[int]) -> int:
    """Return the sum of a list of integers."""
    return sum(numbers)


def format_user(user: dict) -> str:
    """Format a user dictionary as a display string."""
    return f"{user['name']} ({user['email']})"