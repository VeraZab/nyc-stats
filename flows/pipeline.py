import os
import requests

import pandas as pd
from dotenv import load_dotenv
from prefect import flow, task
from prefect_dbt import DbtCoreOperation
from prefect_gcp import GcpCredentials

load_dotenv()


@task(log_prints=True)
def transform():
    # This path changes dynamically as the block requires an absolute path
    dbt_path = f"{os.getcwd()}/dbt/nyc_stats"

    dbt_op = DbtCoreOperation(
        commands=["dbt build"],
        working_dir=dbt_path,
        project_dir=dbt_path,
        profiles_dir=os.getcwd(),
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
def extract(date_string):
    request = requests.get(f"https://data.cityofnewyork.us/resource/ic3t-wcy2.json?pre__filing_date={date_string}")
    blob = pd.read_json(request.text)
    return blob


@flow(log_prints=True)
def main(date_string=""):
    """Run all parametrized extraction and loading flows"""
    blob = extract(date_string)
    load(blob)


if __name__ == "__main__":
    main(date_string="16/03/2023")
