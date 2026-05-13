from app.infra.llm import LLM
from app.utils.log import get_logger

class BaseAgent:
    def __init__(self, name):
        self.logger = get_logger(name)
        self.llm = LLM()
