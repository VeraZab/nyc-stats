import os
from datetime import date, timedelta
from typing import List

import pandas as pd
import requests
from dotenv import load_dotenv
from prefect import flow, task
from prefect_dbt import DbtCoreOperation
from prefect_gcp import GcpCredentials

load_dotenv()


@task
def transform() -> None:
    """Run the dbt transformations on our BigQuery table"""

    dbt_path = f"{os.getcwd()}/dbt/nyc_stats"

    dbt_op = DbtCoreOperation(
        commands=["dbt build"],
        working_dir=dbt_path,
        project_dir=dbt_path,
        profiles_dir=os.getcwd(),
    )

    dbt_op.run()


@task
def load(df: pd.DataFrame) -> None:
    """Loading Data to BigQuery Warehouse"""

    dataset_name = os.getenv("GCP_DATASET_NAME")
    dataset_table_name = os.getenv("GCP_DATASET_TABLE_NAME")
    gcp_credentials = GcpCredentials.load(
        os.getenv("PREFECT_GCP_CREDENTIALS_BLOCK_NAME")
    )

    df.to_gbq(
        destination_table=f"{dataset_name}.{dataset_table_name}",
        project_id=os.getenv("GCP_PROJECT_ID"),
        credentials=gcp_credentials.get_credentials_from_service_account(),
        if_exists="append",
    )


@task
def convert_to_df(results: List[dict]) -> pd.DataFrame:
    """Converting json results from api into a Pandas dataframe."""

    df = pd.DataFrame.from_records(results)

    remove_cols = ["location"]
    date_cols = [
        "created_date",
        "resolution_action_updated_date",
        "closed_date",
        "due_date",
    ]
    num_cols = [
        "unique_key",
        "incident_zip",
        "x_coordinate_state_plane",
        "y_coordinate_state_plane",
        "longitude",
        "latitude",
    ]

    for col in remove_cols:
        if col in df.columns:
            df.drop(columns=col, inplace=True)

    df = df.convert_dtypes()

    for col in date_cols:
        if col in df.columns:
            df[col] = pd.to_datetime(df[col], errors="coerce")

    for col in num_cols:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")

    return df


@task(
    task_run_name="extracting current offset: {offset}",
    retries=3,
    retry_delay_seconds=60,
)
def extract(
    results_per_page: int, offset: int, from_date: date, to_date: date
) -> List[dict]:
    """Extracting Data from API"""

    response = requests.get(
        f"https://data.cityofnewyork.us/resource/erm2-nwe9.json?$limit={results_per_page}&$offset={offset}&$where=created_date between '{from_date}T00:00:00' and '{to_date}T23:59:59'&$order=created_date ASC"
    )

    return response.json()


@flow(log_prints=True, name="extracting and loading")
def extract_and_load(from_date: date, to_date: date) -> None:
    """Extracts and Loads data to BigQuery given a time range"""

    results_per_page = 10000
    offset = 0
    results = extract(results_per_page, offset, from_date, to_date)

    while len(results):
        offset += results_per_page
        df = convert_to_df(results)
        load(df)
        results = extract(
            results_per_page, offset, from_date, to_date, wait_for=[load]
        )


@flow(log_prints=True)
def main(from_date: date, to_date: date) -> None:
    """Our main Prefect flow"""

    extract_and_load(from_date, to_date)
    transform()


if __name__ == "__main__":
    yesterday = date.today() - timedelta(days=1)
    main(from_date=yesterday, to_date=yesterday)
