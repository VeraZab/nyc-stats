# NYC 311 Service Requests: from 2010 to 2023

This project was built over the course of the [2023 Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp). It's goal was to build a data pipeline that continuously fetched, transformed and loaded data into a data warehouse and visualized key insights from it. This is a batch data pipeline, it was written in a way that allows for ad hoc data loading as well as daily job runs that fetch the latest data from the [api](<(https://dev.socrata.com/foundry/data.cityofnewyork.us/erm2-nwe9)>). </br></br>
I also documented my entire 2023 Data Engineering Zoomcamp journey in my medium posts [here](https://medium.com/me/stories/public).
</br>
</br>

## What is NYC 311

NYC 311 is a 24/7 hotline that provides non-emergency services and information for residents, businesses, and visitors. It enables individuals to file complaints on various issues, ranging from poor road conditions, to various noise complaints, graffiti, poor air quality and many others. 311 reroutes service requests to one of the 23 city agencies that is most appropriate to handle them. This service is accessible through multiple channels, including phone, online web portal, mobile app, and social media, offering a centralized point of contact for all non-urgent matters in the city.
</br>
</br>

## About the Dataset

[The data](https://data.cityofnewyork.us/Social-Services/311-Service-Requests-from-2010-to-Present/erm2-nwe9) has been taken from the [NYC Open Data portal](https://opendata.cityofnewyork.us/), a publicly accessible platform that provides [an api](https://dev.socrata.com/foundry/data.cityofnewyork.us/erm2-nwe9) and free access to over 2,100 datasets related to the city of NYC. The 311 dataset is updated automatically, daily.
</br>
</br>

## Questions this Project Seeks to Answer

- What are the top complaint types received by NYC 311?
- What are the top complaint types handled by a specific agency?
- How have individual complaint types evolved over 13 years (increased/decreased)?
- Which zip codes file the most complaints?
- Which zip codes report a particular type of complaint most often?
- Which agencies handle the most 311 complaints and how has this changed year over year?
- Has the responsiveness of the various city agencies increased or decreased year over year?

</br>

## Tech Stack

- [Pandas Python Library](https://pandas.pydata.org/): To fetch data from the [Socrata api](https://dev.socrata.com/foundry/data.cityofnewyork.us/erm2-nwe9), transform it into a dataframe with appropriate data types, and load it to BigQuery
- [Terraform](https://www.terraform.io/): To easily manage infrastructure setup and changes
- [Docker](https://www.docker.com/): To containerize our code (an image for Prefect flows running on CloudRun and an image for the prefect agent running on Compute Engine)
- [Artifact Registry](https://cloud.google.com/artifact-registry): To host our Docker images for the Prefect Agent and Prefect Flows
- [Compute Engine](https://cloud.google.com/compute): To host the Prefect Agent and continuously listen to any queued up jobs in Prefect
- [Cloud Run Jobs](https://cloud.google.com/run/docs/create-jobs): To execute our Prefect flows in a serverless execution environment
- [Google BigQuery](https://cloud.google.com/bigquery): As our Data Warehouse
- [Google Looker Studio](https://lookerstudio.google.com/): To make our dashboard
- [Github](https://github.com/): To host our source code as well as for CI/CD with Github Actions
- [Prefect OSS and Prefect Cloud](https://www.prefect.io/): To orchestrate, monitor and schedule our deployments
- [DBT Core](https://www.getdbt.com/): To transform the data in our data warehouse and get it ready for visualization

</br>

## Data Pipeline Architecture

![Project Architecture Diagram](/utilities/images/architecture-diagram.png)

- Every time code is pushed to the main branch, with the help of Github Actions, a new Docker `flows` image is built and pushed to Artifact Registry, and a new CloudRunJob Prefect block is created (or overwritten) with a link to that updated image.

- Once the infrastructure to run our flows is properly configured (the CloudRunJob), a new Prefect Deployment can be built and applied specifying the remote code storage to use (Github repository) along with the infrastructure to use (the above CloudRunJob).This can be done by manually triggering the "Build and Apply Prefect Deployment" Github Action via the Github UI. This action only needs to be triggered the very first time, or when any of the arguments for the Prefect Deployment change (ex: `--name`, `--work-queue`, `--storage-block`, `--infra-block` ).

- Terraform is used to setup all of our remaining GCP resources (BigQuery, Compute Engine, IAM Service Account, Artifact Registry).

- The Prefect agent runs on Compute Engine. When we first apply our infrastructure via Terraform, a Compute Engine instance is created for our Prefect Agent, and a startup script (provided in our Terraform setup), gets the agent up and running.

- If any changes related to the Prefect agent are needed subsequently (ex: we changed the project's Python version, or the Prefect version we're using), we can trigger a manual rebuild of our Compute Engine instance with the "Rebuild Agent VM" Github Action. This action will build and push an updated `agent` image to Artifact Registry and then use that image to re-initialize a new Compute Engine instance.

- A successful flow run fetches the latest data from our api, loads it to BigQuery, runs dbt transformations on the data loaded from our api and creates the needed tables that feed our final Looker Dashboard.

- When viewing our Looker dashboard, we can make sure all the latest data is included by clicking the "Refresh Data" button.

</br>

## Structure of the Final Complaints Fact Table

| Column         | Data Type | Description                                  |
| -------------- | --------- | -------------------------------------------- |
| unique_key     | INTEGER   | Unique key identifying a specific complaint  |
| created_date   | TIMESTAMP | Date the complaint was filled                |
| closed_date    | TIMESTAMP | Date the complaint was closed                |
| agency_name    | STRING    | Full name of agency that handled the request |
| complaint_type | STRING    | A category of complaint                      |
| descriptor     | STRING    | Longer description explaining complaint      |
| incident_zip   | INTEGER   | Zip Code where incident occured              |

</br>

## DBT Lineage Graph

The lineage graph for the final Fact Complaints Table looks like this:
</br>
</br>
![Lineage](/utilities/images/lineage-graph.png)

- The `staging.complaints` table is where we've loaded up all the source data from the Socrata api.

- `stg_complaints` is a view that cleans up and standardizes the data from the `staging.complaints` table. It also applies a filter that removes around 2M records made for complaints outside of NYC Zip Codes.

- `agencies` is a table that was created from a seed csv which contained abbreviations and full names of all the agencies that deal with 311 Service Requests.

- The `stg_complaints` view and `agencies` table have been joined so as to provide the full agency name in the final `fct_complaints` table that feeds our dashboard.

- The `fct_complaints` table which feeds our dashboard, has been partitioned by month (as partitioning daily would have exceeded the max 4000 partition limit of BigQuery). It has also been clustered by `complaint_type` and `agency_name` columns.

</br>

## Dashboard Preview

You can explore the final dashboard [here](https://lookerstudio.google.com/reporting/65ee32b0-4626-4a39-8065-5d8c27380a1a).

![Dashboard Page 1](/utilities/images/dashboard1.png)
![Dashboard Page 2](/utilities/images/dashboard2.png)
![Dashboard Page 3](/utilities/images/dashboard3.png)
</br>
</br>

## Key Findings

- About a third of the 311 Service Requests filled are routed to the The New York City Police Department. It's the agency that deals with the most requests.
- The top 5 service requests to the NYPD are: Residential Noise, Illegal Parking, Blocked Driveway, Noise on Street/Sidewalk, Commercial Noise.
- Residential Noise complaints from 2019 to 2020 have spiked drastically (230k complaints in 2019 to 403k in 2020), and haven't really decreased in 2021, 2022.
- The part of town reporting the most noise complaints is in the Bronx, specifically in zip code 10466. [It's even been written about](https://www.nycitynewsservice.com/2020/12/03/noise-complaints-nyc-bronx-pandemic-house-parties/).
- The NYPD receives more complaints than any other agency, but it hasn't always been the case. Before 2015, the Department of Housing Preservation and Development used to be the agency dealing with the most complaints.
- Top complaints with the Department of Housing Preservation and Development include: Heat/Hot Water related complaints, Heating, Plumbing, Unsanitary Conditions, General Construction.
- Even if the NYPD receives such important amounts of requests (1.3M in 2022), it is pretty fast at responding to them. The average response time is less than a day.

</br>

## To Replicate

1. Go through the prerequisite steps [here](./prerequisites.md). The last step in those prerequisites will make you push your code to your own remote repository, which will create a Docker Image for your Prefect Flows, push it to GCP Artifact Registry, and register a Prefect CloudRunJob block to use this new image for your flow runs.
1. Trigger a Prefect Deployment build by activating the `Build and Apply Prefect Deployment` github action on the Github UI.
1. Once your Prefect Deployment is applied, go to Prefect Cloud, check that your Agent is running (ie: the work queue is healthy).
1. You can also retrigger a Prefect Agent deployment with the "Rebuild Agent VM" from the GitHub Actions UI. (The first VM deployment has been made with terraform when creating all our resources.)
1. Trigger a deployment by doing a quick run or custom run on the Prefect Cloud UI. Don't make your time period too long as your job can timeout, [read more about this here](https://medium.com/@verazabeida/zoomcamp-2023-project-week-4-5-6e9b5192c3dc).

</br>

## Future Improvements

- would love to add testing and set it up with Continuous Integration
- would love to add support for different environments (development, staging, production)
- would like to see if there's a possibility to add other data sources to enhance this analysis
