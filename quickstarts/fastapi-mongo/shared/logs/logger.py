import logging

from .logging_formatter import CustomFormatter

logger = logging.getLogger('Change-Logger-Name')
logger.setLevel(logging.INFO)

ch = logging.StreamHandler()
ch.setLevel(logging.INFO)

ch.setFormatter(CustomFormatter())

logger.addHandler(ch)
