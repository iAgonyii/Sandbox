import logging
import os

from .logging_formatter import CustomFormatter
from dotenv import load_dotenv


load_dotenv()
logger = logging.getLogger('Change-Logger-Name')
logger.setLevel(logging.INFO if os.getenv('ENV') == 'prod' else logging.DEBUG)

ch = logging.StreamHandler()
ch.setLevel(logging.INFO if os.getenv('ENV') == 'prod' else logging.DEBUG)

ch.setFormatter(CustomFormatter())

logger.addHandler(ch)
