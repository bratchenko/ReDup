[![ReDup](logo.png)]()

[![CircleCI](https://circleci.com/gh/azurefireice/ReDup.svg?style=svg&circle-token=8b4ce0d90d061d83094365eb7e8c731d62d4aae7)](https://circleci.com/gh/azurefireice/ReDup)

# ReDup

>  Repository Duplication

This application produces an URL to a github application.
The application behind the URL requests access to the user's GitHub profile and creates
a repository with its own (application's) code.
The application does not ask for the users's password or require access to user's private repositories.

The project is a
 - Cloud-native application based on
    - GitHub app
    - AWS lambda
        - Based on Python 3.8
    - API Gateway
 - Is deployed using terraform
 - With enabled CICD workflow provided by [CircleCI](https://circleci.com)

---

## Table of Contents

1. [Installation](#installation)
    1. [Pre-deploy setup](#pre-deploy-setup)
    2. [Local Setup](#local-Setup)
    3. [CICD Setup](#cicd-setup)
2. [Specification](#specification)
3. [What could be improved](#What could be improved)
4. [Team](#team)
5. [License](#license)

---

## Installation

>  It is strongly recommended to set up CICD workflow from the start, <br> as local deployments are not encouraged.

- All CICD deployment instructions are contained in [config.yml](.circleci/config.yml)
- Set up AWS credentials in circleci project settings
- Enable usage of 3-rd party orbs
- You are ready to go

### Pre-deploy setup

1. You will need an AWS account
    - Setup Access keys (**access key ID** and **secret access key**) on your AWS account
2. Setup **private** s3 bucket on AWS. You will need it for storing terraform state.
    - Choose unique **name** for it
    - Add it to [main.tf](terraform/main.tf) as **bucket** value
3. Create a [GitHub OAuth app](https://github.com/settings/developers)
    - You will need **Client ID**
    - You will need **Client Secret**
    - Leave **Homepage URL** and **Authorization callback URL** fields empty.
     You will update them from [Local Setup](#local-Setup) or [CICD Setup](#cicd-setup) steps later on.

### Local Setup

The project was developed in Intellij Idea IDE and it is recommended to use it for development. <br>
It is intended for linux or MacOs environment, though it is possible to develop on Windows. <br>
> To develop on Windows one way would be is to setup local environment with [Cygwin](https://cygwin.com/install.html), <br>
> satisfying linux environment dependencies like python, pip, make, zip. <br>

In order to build and deploy it locally, you will need:

- Python 3.8
- Pip
- make
- zip
- AWS-CLI
- Terraform v0.12.16 or greater

Deploying from local machine can be done with the following sequence:
> Setup AWS credentials and config on local environment <br>
> execute commands below from the project root

```shell
    $ make clean
    $ make test
    $ make lint
    $ make build
    $ cd terraform
    $ terraform init
    $ terraform validate
    $ terraform plan
    $ terraform apply -auto-approve
```

> on the last step you will need to provide the following **environment variables**:
>   - TF_VAR_GITHUB_CLIENT_ID and TF_VAR_GITHUB_CLIENT_SECRET - from [Pre-deploy setup](#pre-deploy-setup), step 1
>   - TF_VAR_GITHUB_TEMPLATE_REPO_OWNER_NAME - your GitHub user name

The last command will produce 2 endpoints:
 - *homepage_url* - Homepage from which user can start application workflow
 - *auth_redirect_url* - redirect URL that should be added to GitHub OAuth app from [Pre-deploy setup](#pre-deploy-setup), step 3

### CICD Setup

> Application was deployed and tested using [CircleCI](https://circleci.com). <br>
> Please follow the [CircleCI official setup](https://circleci.com/docs/2.0/getting-started/) to set it up.

- To AWS Permissions section of CircleCI project add AWS details from [Pre-deploy setup](#pre-deploy-setup), step 1
- Setup environment variables of CircleCI project
    - TF_VAR_GITHUB_CLIENT_ID and TF_VAR_GITHUB_CLIENT_SECRET - from [Pre-deploy setup](#pre-deploy-setup), step 1
    - TF_VAR_GITHUB_TEMPLATE_REPO_OWNER_NAME - your GitHub user name
- Start building project
- Approve build step "approve_deploy"
- When step "tf-apply" finishes, copy the results:
    - *homepage_url* - Homepage from which user can start application workflow
    - *auth_redirect_url* - redirect URL that should be added to GitHub OAuth app from [Pre-deploy setup](#pre-deploy-setup), step 3
---

## Specification

Please see the [Specification document](http://htmlpreview.github.com/?https://github.com/azurefireice/ReDup/blob/master/SpecificationReDup.html)

---

## What could be improved
Due to time limitations, only essential functionality was implemented.

At the current state there are lot of improvements that can be done. Here are some of them:

1. GitHub improvements
    1. Use "code" GitHub parameter in authentication part.
    2. Use specific GitHub API libraries: [RAuth](https://github.com/litl/rauth), [Authomatic](https://authomatic.github.io/authomatic/index.html).
    3. User OAuth libraries with GitHub provider support: [AuthLib](https://github.com/lepture/authlib), [requests-oauthlib](https://requests-oauthlib.readthedocs.io/en/latest/).
2. Infrastructure improvements
    1. Staging environment, branching.
    1. Build
        1. Provide python code as wheel packages.
        2. Simplify lambda zip and get rid of the only "requests" lib for callback lambda. Use urllib3 instead. Opposite to with 1.ii, 1.iii.
        3. Filter trash from pip dependencies in zip, to reduce lambda size.
    5. Separate repository creation from callback part and link it with callback function via SNS or SQS.
    7. Terraform
        1. GitHub app creation with terraform.
        2. Add terraform syntax linting and testing.
        3. Terraform initial setup automation(s3 bucket, dynamoDB lock table).
        4. Terraform backend bucket name as env variable
3. UI
    1. Create UI
    2. Create hosting for front-end part of application and leverage static content distribution via CDN using s3.
4. Security
    1. Users Authorization/Authentication.
    2. Implement storing of tokens received from GItHub.
5. Monitoring and alerting
    1. Implement monitoring and alerting
    3. Error rate
    4. API usage rate
    5. GitHub repo creation errors detection
    6. Create repo from template feature discontinuation on GitHub side

## Team

> Andrii Gryshchenko


 [![Andrii](https://avatars1.githubusercontent.com/u/43616610?s=260)]() 

---

## License

[![License](https://www.gnu.org/graphics/gplv3-127x51.png)](https://opensource.org/licenses/GPL-3.0)

- **[GPL-3.0 license](LICENSE)**

- Copyright 2019 © Andrii Gryshchenko
