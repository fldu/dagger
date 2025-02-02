---
slug: /1248/aws-sam
displayed_sidebar: '0.2'
---

# AWS SAM

This is a [Dagger](https://dagger.io/) package to help you deploy serverless functions with ease.
It is a superset of [AWS SAM](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html), which allows you to build and deploy Lambda function(s).
The aim is to integrate the lambda deployment to your current [Dagger](https://dagger.io/) pipeline. This way, you can __build__ and __deploy__ with a single [Dagger environment](../getting-started/1200-local-dev.md).

## :hammer_and_pick: Prerequisite

Before we can build, test & deploy our example app with Dagger, we need to have Docker Engine running.
We also need to [install `dagger`](../getting-started/1242-install.md).

## :beginner: Quickstart

Everyone should be able to develop and deploy their AWS SAM functions using a local pipeline.
Having to commit & push in order to test a change slows down iteration.

### Locally

An AWS SAM project requires the following environment variables:

```text
AWS_ACCESS_KEY_ID=<your AWS access key id>
AWS_REGION=<your AWS region>

// if you use a .zip archive you have to provide a S3 bucket
AWS_S3_BUCKET=<your S3 bucket>

AWS_SECRET_KEY=<your AWS secret key>
AWS_STACK_NAME=<your stack name>
```

Now we are ready to write the plan to build and deploy a SAM function with dagger.

#### Plan for a .zip archive

This is a the plan for a `.zip archives` function:

```cue file=../tests/use-cases/aws-sam/zip.cue
```

Now we can run `dagger do deploy` to build an AWS SAM function and deploy it to AWS Lambda.

#### Plan for a Docker image

This is a the plan for a `docker image` function.
In case of building a Docker image we have to define the Docker socket and we don't need the S3 bucket anymore.

```cue file=../tests/use-cases/aws-sam/image.cue
```

Now we can run `dagger do deploy` to build an AWS SAM function and deploy it to AWS Lambda.

### GitLab CI

#### Build & deploy .zip archives with GitLab CI

If we want to run the above plans in a GitLab CI environment, we can do that without any changes to the `.zip archives`.
First step is to create a `.gitlab-ci.yml` with the following content:

```yml file=../tests/use-cases/aws-sam/gitlab-ci.yml
```

Triggering the pipeline will build our AWS SAM function and deploy it to AWS Lambda.

:::tip
Remember to set the needed environment variables in your GitLab CI environment.
:::

#### Build & deploy a Docker image with GitLab CI

If we want to run the plan with the Docker image in a GitLab CI environment, we have to make small changes.
This is because in GitLab we have to use a `DinD-Service` and we cannot connect via `docker socket` - we have to use `tcp-socket`.

First we have to change the plan itself to use `tcp-socket`:

```cue file=../tests/use-cases/aws-sam/image-gitlab-ci.cue
```

Next we have to update our `.gitlab-ci.yml` with the following content:

```yml file=../tests/use-cases/aws-sam/image-gitlab-ci.yml
```

Notice that we have added `--with 'actions: ciKey: "gitlab"'` to the `dagger do deploy` command.

If we trigger the pipeline, it should build our AWS SAM function and deploy everything to AWS Lambda.

:::tip
Remember to set the needed environment variables in your GitLab CI environment.
:::

## :handshake: Contributing

If something doesn't work as expected, please open an [issue](https://github.com/dagger/dagger/issues/new/choose).

If you intend to contribute, please follow [our contributing guidelines](https://docs.dagger.io/1227/contributing/)! :rocket:

## :superhero: Maintainer(s)

- [Patrick Döring](https://github.com/munichbughunter)
