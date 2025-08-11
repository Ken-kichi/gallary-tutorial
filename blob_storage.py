import os, uuid
from azure.identity import DefaultAzureCredential
from azure.storage.blob import (
    BlobServiceClient,
    BlobProperties,
    ContainerProperties,
    ContainerClient
    )
from dotenv import load_dotenv

load_dotenv()

class BlobStorage:
    def __init__(self)->None:
        self.account_url = os.getenv("ACCOUNT_URL")
        self.default_credential = DefaultAzureCredential()
        self.blob_service_client = BlobServiceClient(self.account_url, credential=self.default_credential)

    def get_uuid(self)->str:
        return str(uuid.uuid4())

    # コンテナーの作成
    def create_container(self,container_name:str)->ContainerClient:
        container_client = self.blob_service_client.create_container(container_name)
        return container_client

    # BLOB をアップロードする
    def upload_blob(self,container_name:str, upload_file_name:str,data:bytes)->None:
        blob_client = self.blob_service_client.get_blob_client(container=container_name, blob=upload_file_name)
        blob_client.upload_blob(data,overwrite=True)

    # BLOB を一覧表示する
    def list_blobs(self,container_name:str)->list[BlobProperties]:
        container_client = self.blob_service_client.get_container_client(container_name)
        blob_list = container_client.list_blobs()
        return blob_list

    # コンテナを一覧表示する
    def list_containers(self)->list[ContainerProperties]:
        container_list = self.blob_service_client.list_containers()
        return container_list

    # BLOB を削除する
    def delete_blob(self,container_name:str, local_file_name:str)->None:
        blob_client = self.blob_service_client.get_blob_client(container=container_name, blob=local_file_name)
        blob_client.delete_blob()

    # コンテナーを削除する
    def delete_container(self,container_name:str)->None:
        container_client = self.blob_service_client.get_container_client(container_name)
        container_client.delete_container()

def main():
    blob_storage = BlobStorage()
    list_blobs = blob_storage.list_blobs(container_name="images")
    for blob in list_blobs:
        print(blob.name)

if __name__ == "__main__":
    main()
