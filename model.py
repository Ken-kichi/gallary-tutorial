from pydantic import BaseModel
from datetime import datetime

class Item(BaseModel):
    name: str

class InputItem(Item):
    file_path:str

class OutputItem(Item):
    url:str
    creation_time:datetime
