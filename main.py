from fastapi import FastAPI, File, UploadFile
from dotenv import load_dotenv
import os
from model import OutputItem
from blob_storage import BlobStorage
from datetime import timezone, timedelta

load_dotenv()
ACCOUNT_URL = os.getenv("ACCOUNT_URL")
CONTAINER_NAME = os.getenv("CONTAINER_NAME")
blob_storage = BlobStorage()


app = FastAPI()

# 一覧API
@app.get("/items")
def get_items():
    list_blobs = blob_storage.list_blobs(container_name=CONTAINER_NAME)
    JST = timezone(timedelta(hours=9))
    items: list[OutputItem] = [
        OutputItem(
            name=blob.name,
            url=f"{ACCOUNT_URL}/{CONTAINER_NAME}/{blob.name}",
            creation_time=blob.creation_time.astimezone(JST)
        )
        for blob in list_blobs
    ]
    return {"items": items}

# 詳細API
@app.get("/items/{item_name}")
def get_item(item_id: str):
    blob = blob_storage.get_blob(container_name=CONTAINER_NAME, blob_name=item_name)
    return {"item": Item(name=blob.name, url=f"{ACCOUNT_URL}/{CONTAINER_NAME}/{blob.name}", creation_time=blob.creation_time.astimezone(JST))}

# 作成API
@app.post("/items")
async def create_item(file: UploadFile = File(...)):
    try:
        data = await file.read()
        upload_file_name = f"{blob_storage.get_uuid()}.{file.filename.split('.')[-1]}"
        blob_storage.upload_blob(container_name=CONTAINER_NAME, upload_file_name=upload_file_name,data=data)

        return {"message": "Success", "filename": upload_file_name, "url": f"{ACCOUNT_URL}/{CONTAINER_NAME}/{upload_file_name}"}
    except Exception as e:
        return {"message": "Failed", "error": str(e)}

# 削除API
@app.delete("/items/{item_name:str}")
def delete_item(item_name: str):
    try:
        blob_storage.delete_blob(container_name=CONTAINER_NAME, local_file_name=item_name)
        return {"message": "Success"}
    except Exception as e:
        return {"message": "Failed", "error": str(e)}
