import os

from dotenv import load_dotenv
from prefect.filesystems import GitHub
from prefect_gcp import GcpCredentials

load_dotenv()

gcp_credentials_block = GcpCredentials(service_account_file=os.getenv("LOCAL_SERVICE_ACCOUNT_FILE_PATH"))
gcp_credentials_block.save(os.getenv("PREFECT_GCP_CREDENTIALS_BLOCK_NAME"), overwrite=True)
