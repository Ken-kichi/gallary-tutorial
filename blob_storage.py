import os, uuid,io
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.storage.blob import (
    BlobServiceClient,
    BlobProperties,
    ContainerProperties,
    ContainerClient
    )
from PIL import Image
from typing import Union, BinaryIO

class BlobStorage:
    def __init__(self)->None:
        self.default_credential = DefaultAzureCredential()
        self.client = SecretClient(vault_url="https://gallery-kvey233k.vault.azure.net/", credential=self.default_credential)
        self.account_url = self.client.get_secret("ACCOUNT-URL").value
        self.container_name = self.client.get_secret("CONTAINER-NAME").value
        self.blob_service_client = BlobServiceClient(self.account_url, credential=self.default_credential)

    def get_account_url(self)->str:
        return self.client.get_secret("ACCOUNT-URL").value

    def get_container_name(self)->str:
        return self.client.get_secret("CONTAINER-NAME").value

    def get_uuid(self)->str:
        return str(uuid.uuid4())

    def square_image(self, image_source: Union[str, BinaryIO]) -> Image.Image:
        with Image.open(image_source) as img:
            size = max(img.size)
            new_img = Image.new("RGB", (size, size), (255, 255, 255))
            new_img.paste(img, ((size - img.width) // 2, (size - img.height) // 2))
            return new_img

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
    list_blobs = blob_storage.list_blobs(container_name=self.container_name)
    for blob in list_blobs:
        print(blob.name)

if __name__ == "__main__":
    main()
