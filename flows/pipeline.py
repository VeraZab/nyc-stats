import os

import pandas as pd
from dotenv import load_dotenv
from prefect import flow, task
from prefect.tasks import task_input_hash
from prefect_dbt import DbtCoreOperation
from prefect_gcp import GcpCredentials

load_dotenv()


@task(log_prints=True)
def transform():
    # This path changes dynamically when on VM
    dbt_path = f"{os.getcwd()}/dbt/template"

    dbt_op = DbtCoreOperation(
        commands=["dbt build"],
        working_dir=dbt_path,
        project_dir=dbt_path,
    )

    dbt_op.run()


@task(log_prints=True)
def load(blob):
    """Load Data to BigQuery Warehouse"""
    dataset_name = os.getenv("GCP_DATASET_NAME")
    dataset_table_name = os.getenv("GCP_DATASET_TABLE_NAME")

    gcp_credentials = GcpCredentials.load(os.getenv("PREFECT_GCP_CREDENTIALS_BLOCK_NAME"))

    blob.to_gbq(
        destination_table=f"{dataset_name}.{dataset_table_name}",
        project_id=os.getenv("GCP_PROJECT_ID"),
        credentials=gcp_credentials.get_credentials_from_service_account(),
        if_exists="append",
    )


@task(
    retries=3,
    log_prints=True,
    task_run_name="extracting:{month}-{year}",
)
def extract(month, year):
    """Extract csv data from source"""

    if len(f"{month}") == 1:
        month = f"0{month}"

    data_url = (
        f"https://github.com/DataTalksClub/nyc-tlc-data/releases/download/fhv/fhv_tripdata_{year}-{month}.csv.gz"
    )
    blob = pd.read_csv(data_url, nrows=100)
    return blob


@flow(log_prints=True)
def main(month=1, year=2019):
    """Run all parametrized extraction and loading flows"""
    blob = extract(month, year)
    load(blob)
    transform()


if __name__ == "__main__":
    main(month=1, year=2019)
