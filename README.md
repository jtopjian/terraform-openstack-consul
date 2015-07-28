# Using Terraform to Deploy Consul

This repository will deploy a Consul cluster inside OpenStack. You can specify the size of the cluster.

You also need an Amazon AWS account as this demo utilizes Route 53.

## Instructions

* Generate an SSH key:

```shell
$ ssh-keygen -f key/consul
```

* Source your OpenStack and AWS credentials:

```shell
$ source openrc
$ source awsrc
```

* Deploy:

```shell
$ terraform plan
$ terraform apply
var.count
  Default: 3
  Enter a value: 50!
```

## Test

Once Terraform finishes, log in and verify Consul is working:

```shell
$ ssh consul.YOUR-DOMAIN-NAME
root@consul-02:~# consul members
...
```

## Limitations

This is just a demo and should not be used for production. The security group is configured to allow all traffic. Consul is also configured to listen on all interfaces, which allows anyone to query the Consul database and service catalog.
