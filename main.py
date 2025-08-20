import io
from fastapi import FastAPI, File, UploadFile
from model import OutputItem
from blob_storage import BlobStorage
from datetime import timezone, timedelta
from fastapi.middleware.cors import CORSMiddleware

blob_storage_cls = BlobStorage()

ACCOUNT_URL = blob_storage_cls.get_account_url()
CONTAINER_NAME = blob_storage_cls.get_container_name()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def get_root():
    return {"message":"Hello World"}

# 一覧API
@app.get("/items")
def get_items():
    list_blobs = blob_storage_cls.list_blobs(container_name=CONTAINER_NAME)
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
    blob = blob_storage_cls.get_blob(container_name=CONTAINER_NAME, blob_name=item_name)
    return {"item": Item(name=blob.name, url=f"{ACCOUNT_URL}/{CONTAINER_NAME}/{blob.name}", creation_time=blob.creation_time.astimezone(JST))}

# 作成API
@app.post("/items")
async def create_item(file: UploadFile = File(...)):
    try:
        data = await file.read()
        img_stream = io.BytesIO(data)
        square_img = blob_storage_cls.square_image(img_stream)
        upload_file_name = f"{blob_storage_cls.get_uuid()}.{file.filename.split('.')[-1]}"
        output_stream = io.BytesIO()
        square_img.save(output_stream, format=file.content_type.split('/')[-1])
        output_stream.seek(0)
        blob_storage_cls.upload_blob(
            container_name=CONTAINER_NAME,
            upload_file_name=upload_file_name,
            data=output_stream.getvalue()
        )

        return {
            "message": "Success",
            "filename": upload_file_name,
            "url": f"{ACCOUNT_URL}/{CONTAINER_NAME}/{upload_file_name}"
        }
    except Exception as e:
        return {"message": "Failed", "error": str(e)}

# 削除API
@app.delete("/items/{item_name:str}")
def delete_item(item_name: str):
    try:
        blob_storage_cls.delete_blob(container_name=CONTAINER_NAME, local_file_name=item_name)
        return {"message": "Success"}
    except Exception as e:
        return {"message": "Failed", "error": str(e)}
