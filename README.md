## Script to count tags in a registry

### AWS ECR

Uses `aws ecr get-login` to validate credentials.

Identifies all repositories in ECR registry and counts the unique tags for each. Sums up the total tags.

### 

Uses DockerHub username and password to create API token.

Identifies all repositories in DockerHub registry and counts the unique tags for each. Sums up the total tags.

"DockerHub organization, username, or repository. Ex. anchore, jvalance, consul" - Options here are:

- An organization: ex. anchore
- An individual user: ex. jvalance
- A single repository in DockerHub library: ex. ubuntu

If choosing a single repository in Dockerhub library, answer "yes to the last question: "Is this repository in the DockerHub library (Ex. library/ubuntu, library/consul)? yes or no:"