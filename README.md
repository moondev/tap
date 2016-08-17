# tap: Terraform Ansible Packer

## Example deployment pipeline

### Requirements
[Terraform](https://www.ansible.com/), [Ansible](https://www.terraform.io/), [Packer](https://www.packer.io/), and [Python 2.7](https://www.python.org/) on the path

### Usage
Tested on OSX

1. Add AWS key and secret to `aws.json`

2. Start pipeline with `python deploy.py`

### Overview

`deploy.py` coordinates the different stages of the deployment pipeline.

#### Bake base image
Bakes base image with packer and terraform, only re-bakes if there is a change to base-ami.json

#### Bake deployment image
Bakes base image with packer by combining artifact `workdir/index.html` with base apache image, only re-bakes if there is a change to `workdir/index.html`

#### Deploy
Terraform sets up asg, load balancer, security group 