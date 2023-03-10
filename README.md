# ELT Project Template [BigQuery, Prefect Cloud, Dbt Core, Terraform]

The intent of this template is to quickstart development of your data pipeline, with BigQuery, Prefect open source, Dbt Core, and Terraform.

## Prerequisites:

<details>
<summary>Python 3</summary>

This project was tested with Python 3.11. Use a [Python version manager](https://realpython.com/intro-to-pyenv/) and a [virtual environment](https://realpython.com/python-virtual-environments-a-primer/) to install your dependencies.

</details>

<details>
<summary>Poetry: Python Dependency Manager </summary>

To install Poetry you can view the [installation instructions here](https://python-poetry.org/docs).

</details>

<details>
<summary>Google Cloud Platform Account</summary>

Sign up for a free test account [here](https://cloud.google.com/free/), and enable billing.

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
<summary>Github Repository that you will push your project to</summary>

Creation steps for a [remote github repository here](https://docs.github.com/en/get-started/quickstart/create-a-repo).

</details>

</br>

## To setup for development:

1. Clone repository </br>
   `git clone https://github.com/VeraZab/elt-template.git`
1. Remove git history </br>
   `rm -rf .git`
1. Reinitialize git and make your initial commit on `main` branch </br>
   `git init`</br>
   `git add .` </br>
   `git commit -m 'initial commit'` </br>
1. Rename the `env` file to `.env`
1. Create a virtual environment `python -m venv venv` and activate it with `source venv/bin/activate`.
1. Run `gcloud init` and follow instructions to setup your project. </br>
1. Run `gcloud info` to check that all is configured correctly, you should see that your CLI is configured to use your created project.
1. Enter your newly created projectID into the `.env` file
1. Enable google cloud billing.
1. Enable the `gcloud` services that we'll use (bigquery, compute engine) `gcloud services enable compute.googleapis.com`
1. Fill out the rest of the environment variables that relate to GCP
1. Run `make gcp-setup`, this will create a service account with editor permissions, and download a json format api key to the path you specified in `.env` file,
   make sure to include this file to `.gitignore` so its not version controlled.
1. Run `set -o allexport && source .env && set +o allexport` to export all variables, as we're going to need some of them for Terraform setup next.
1. Make sure you have the `GOOGLE_APPLICATION_CREDENTIALS` environment variable set, this should have happened at the GCP setup step, when you exported all your env vars. You can check with `echo $GOOGLE_APPLICATION_CREDENTIALS`.
1. Go into your terraform directory `cd terraform`
1. Run `terraform init` to initialize.
1. Run `terraform plan` to see the changes to be applied.
1. Run `terraform apply` to deploy your resources. If you need to destroy the changes you can run `terraform destroy`.
1. Install the dependencies with `poetry install --no-root`. If everything is properly installed `pip list` should list all your installed dependencies into a virtual environment. [Docs here](https://python-poetry.org/docs/basic-usage/#activating-the-virtual-environment)
1. Make sure your Prefect Cloud is properly setup (see section above), and that your environment variables are exported (`echo $PREFECT_KEY` should show your Prefect API Key, if not set, reexport `set -o allexport && source .env && set +o allexport`).
1. Go back to the root of your directory, and run `make prefect-api-url` to get your Prefect api url. Uncomment the PREFECT_API_URL env var, and set it to what showed up in your terminal. If you try to run `make prefect-api-url` and the PREFECT_API_URL was exported as empty variable, you will not be able to get your PREFECT_API_URL (seems like a Prefect bug).
1. Fill out the rest of your environment variables, mainly the block names that you want to give to your Prefect blocks.
1. Reexport all environment variables with `set -o allexport && source .env && set +o allexport && export PREFECT_API_KEY=$PREFECT_KEY`. Note that reserring PREFECT_API_KEY manually is necessary because of this [bug](https://github.com/PrefectHQ/prefect/issues/7797).
1. Run `make prefect-blocks`, to create all the thirdparty Prefect blocks.
1. cd into the dbt folder, and run `dbt init`, follow the prompts. Make sure that what got saved into your `~/.dbt/.profiles.yml` as a location for your project is the same location as what you've set in GCP. Copy over just the `models/staging` folder into the dbt project that you've created, then delete the `template` folder, as well as the `models/examples` folder in your newly created project.
1. Again, fill out the appropriate environment variables for dbt core, and reexport your variables `set -o allexport && source .env && set +o allexport`.
1. Push the code to your own remote repository.</br>

   ```
   git add .
   git commit -m'describe your commit'
   git remote add origin url-of-your-git-repo
   git branch -M main
   git push -u origin main
   ```

1. Setup your Github Action Secrets and add `PREFECT_API_KEY` and `PREFECT_API_URL` and the `PREFECT_GITHUB_BLOCK_NAME` to your Action Secrets to setup CI/CD work</br>
![github action secrets](/utilities/images/github-action-secrets.png)
</details>

</br>

## To run the pipeline:

1. [Trigger a workflow run from the Github UI](https://levelup.gitconnected.com/how-to-manually-trigger-a-github-actions-workflow-4712542f1960). This will create and apply a deployment, which you should be able to see in your Prefect Cloud UI.
1. Trigger a deployment run from Prefect UI.
1. In a new terminal window run `prefect agent start --pool default-agent-pool --work-queue github`. Make sure your `PREFECT_API_KEY` and `PREFECT_API_URL` environment variables are properly set.
1. Once that succeeds you should be able to see a new view in your BigQuery table, with just 10 rows from fhv taxi dataset.

</br>

## To do:

- Use Prefect Orion
- Make a startup.sh script to reduce startup steps
- Experiment with Docker and running all this in a container
- Make prefect agent run on CloudRun, and use Artifact Registry for the Docker Image that will run Prefect Agent
