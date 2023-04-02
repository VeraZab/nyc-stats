# Project Setup

## Prerequisites:

<details>
<summary>Python 3</summary>

This project was tested with Python 3.11. Use a [Python version manager](https://realpython.com/intro-to-pyenv/) and a [virtual environment](https://realpython.com/python-virtual-environments-a-primer/) to install your dependencies.

</details>

<details>
<summary>Poetry: Python Dependency Manager</summary>

To install Poetry you can view the [installation instructions here](https://python-poetry.org/docs).

</details>

<details>
<summary>Google Cloud Platform Account</summary>

Sign up for a free test account [here](https://cloud.google.com/free/), and enable billing.

</details>

<details>
<summary>Prefect Cloud</summary>

Sign up for a free account [here](https://www.prefect.io).

</details>

<details>
<summary>Google Cloud CLI</summary>

Installation instruction for `gcloud` [here](https://cloud.google.com/sdk/docs/install-sdk).

</details>

<details>
<summary>Terraform</summary>

You can view the [installation instructions for Terraform here](https://developer.hashicorp.com/terraform/downloads?ajs_aid=f70c2019-1bdc-45f4-85aa-cdd585d465b4&product_intent=terraform)

</details>

<details>
<summary>Git and Github Repository</summary>

To install git, check out instructions [here](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).
Creation steps for a [remote github repository here](https://docs.github.com/en/get-started/quickstart/create-a-repo).

</details>

</br>

## Setup Steps:

1. Clone this repository
1. Remove git history with `rm -rf .git`
1. Rename the `env` file to `.env`
1. Reinitialize git with `git init`</br>
1. Create a virtual environment `python -m venv venv` and activate it with `source venv/bin/activate`
1. Install dependencies with `poetry install --no-root`
1. Go to Prefect Cloud create a workspace and an API Key
1. Fill out all the PREFECT related environment variables in your `.env` file except PREFECT_API_URL and PREFECT_API_KEY
1. Export your environment variables `set -o allexport && source .env && set +o allexport`
1. Run `make prefect-api-url` to get your Prefect api url. If you're getting authentication errors, make sure your `PREFECT_API_KEY` environment variable is unset. See this [bug](https://github.com/PrefectHQ/prefect/issues/7797).
1. Uncomment the PREFECT_API_URL env var, and set it to what showed up in your terminal. Also uncomment the `PREFECT_API_KEY` env variable.
1. Run `gcloud init` and follow instructions to setup your project. </br>
1. Run `gcloud info` to check that all is configured correctly, you should see that your CLI is configured to use your created project.
1. Enter your newly created projectID into the `.env` file, and fill out the other environment variables that relate to GCP. The GCP environment variables are the names of resources that you would like to be created, but that haven't been created yet except for the ProjectID. More info in comments of `.env` file. Make sure you do not have trailing spaces in your environment variable names.
1. Export your environment variables again as you've added some new ones, with `set -o allexport && source .env && set +o allexport`
1. [Enable google cloud billing](https://support.google.com/googleapi/answer/6158867?hl=en).
1. Run `make gcp-setup`, this will enable the GCP services that we'll use for this project, create a service account with editor permissions, and download a json format api key to the path you specified in `.env` file.
1. Make sure to included the GCP service account file to your `.gitignore` so its not version controlled.
1. In Prefect Cloud, create 2 blocks: a Github Storage block, and a GCP credentials block. For the GCP credentials block, enter the JSON directly as the block will be accessed by CloudRun and will not have access to your local file system.
1. Go into your terraform directory `cd terraform`
1. Run `terraform init` to initialize.
1. Run `terraform plan` to see the changes to be applied.
1. Run `terraform apply` to deploy your resources.
1. Setup your Github Action Secrets for CI/CD (most are same as env vars in `.env` file)</br>
   ![github action secrets](/utilities/images/github-action-secrets.png)
   | SECRET NAME | Description |
   | -------------- | -- |
   | GCP_COMPUTE_ENGINE_NAME | Same as in `.env` |
   | GCP_COMPUTE_ENGINE_REGION |`TF_VAR_COMPUTE_ENGINE_REGION` in `.env` |
   | GCP_DATASET_NAME |Same as in `.env` |
   | GCP_DATASET_TABLE_NAME |Same as in `.env` |
   | GCP_PROJECT_ID |Same as in `.env` |
   | GCP_RESOURCE_REGION |Same as in `.env` |
   | GCP_SERVICE_ACCOUNT_API_KEY_BASE64 |Transform the JSON key of your GCP Service Account, into a base64 encoded string. Blog post about it [here](https://medium.com/@verazabeida/using-json-in-your-github-actions-when-authenticating-with-gcp-856089db28cf) |
   | GCP_SERVICE_ACCOUNT_EMAIL | Same as in `.env` |
   | PREFECT_AGENT_QUEUE_NAME | Same as in `.env` |
   | PREFECT_API_KEY | Same as in `.env` |
   | PREFECT_API_URL | Same as in `.env` |
   | PREFECT_CLOUD_RUN_BLOCK_NAME | Name that you would like to give your Cloud Run block in the Prefect UI. You don't need to create this block, the Github Actions will. Just choose the name. |
   | PREFECT_GCP_CREDENTIALS_BLOCK_NAME | This is the name of the block you created in the Prefect UI a few steps above. |
   | PREFECT_GITHUB_BLOCK_NAME | This is the name of the block you created in the Prefect UI a few steps above. |

   </br>

1. In the `dbt/nyc_stats/models`, make sure that the `schema.yml` file matches up with your BigQuery setup. Also in `stg_complaints.sql`, make sure that the `source` reference matches up the name of your BigQuery table. Also check that all the references to db and tables in the `core` folder are ok.
1. Push the code to your own remote repository. This will automatically (with the help of Github Actions), create a Docker image and push it to Artifact Registry, so that your flows can use that infrastructure when running. It will also create a CloudRunJob block in Prefect Cloud. </br>

   ```
   git add .
   git commit -m 'initial commit'
   git remote add origin url-of-your-git-repo
   git branch -M main
   git push -u origin main
   ```

</br>
