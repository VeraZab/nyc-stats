import os
from datetime import date, timedelta

import pandas as pd
import requests
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


def load(df):
    """Load Data to BigQuery Warehouse"""

    dataset_name = os.getenv("GCP_DATASET_NAME")
    dataset_table_name = os.getenv("GCP_DATASET_TABLE_NAME")
    gcp_credentials = GcpCredentials.load(os.getenv("PREFECT_GCP_CREDENTIALS_BLOCK_NAME"))

    df.to_gbq(
        destination_table=f"{dataset_name}.{dataset_table_name}",
        project_id=os.getenv("GCP_PROJECT_ID"),
        credentials=gcp_credentials.get_credentials_from_service_account(),
        if_exists="append",
    )


def correct_types(df):
    df.drop(columns="location", inplace=True)
    df = df.convert_dtypes()

    df["created_date"] = pd.to_datetime(df["created_date"])
    df["resolution_action_updated_date"] = pd.to_datetime(df["resolution_action_updated_date"])
    df["closed_date"] = pd.to_datetime(df["closed_date"])
    df["x_coordinate_state_plane"] = pd.to_numeric(df["x_coordinate_state_plane"])
    df["y_coordinate_state_plane"] = pd.to_numeric(df["y_coordinate_state_plane"])
    df["longitude"] = pd.to_numeric(df["longitude"])
    df["latitude"] = pd.to_numeric(df["latitude"])

    return df


@task(
    retries=3,
    log_prints=True,
    task_run_name="extracting: from {from_date} (inclusive) to {to_date} (inclusive)",
)
def extract_and_load(from_date, to_date):
    results_per_page = 1000000
    offset = 0

    response = requests.get(
        f"https://data.cityofnewyork.us/resource/erm2-nwe9.json?&$limit={results_per_page}&$offset={offset}&$where=created_date between '{from_date}T00:00:00' and '{to_date}T23:59:59'"
    )

    while len(response.json()):
        offset += results_per_page
        df = pd.DataFrame.from_records(response.json())
        adjusted_df = correct_types(df)
        load(adjusted_df)
        response = requests.get(
            f"https://data.cityofnewyork.us/resource/erm2-nwe9.json?&$limit={results_per_page}&$offset={offset}&$where=created_date between '{from_date}T00:00:00' and '{to_date}T23:59:59'"
        )


@flow(log_prints=True)
def main(from_date, to_date):
    extract_and_load(from_date, to_date)


if __name__ == "__main__":
    yesterday = date.today() - timedelta(days=1)
    main(from_date=yesterday, to_date=yesterday)
