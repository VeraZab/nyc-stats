import os

from dotenv import load_dotenv
from prefect.filesystems import GitHub
from prefect_gcp import GcpCredentials

load_dotenv()

github_block = GitHub(repository=os.getenv("GITHUB_REPO_URL"))
github_block.save(os.getenv("PREFECT_GITHUB_BLOCK_NAME"), overwrite=True)

gcp_credentials_block = GcpCredentials(service_account_file=os.getenv("LOCAL_SERVICE_ACCOUNT_FILE_PATH"))
gcp_credentials_block.save(os.getenv("PREFECT_GCP_CREDENTIALS_BLOCK_NAME"), overwrite=True)
