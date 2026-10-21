from datetime import date, datetime
from zoneinfo import ZoneInfo


def get_today() -> date:
    return datetime.now(ZoneInfo("America/Sao_Paulo")).date()
