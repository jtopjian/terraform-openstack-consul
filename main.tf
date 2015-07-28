variable "count" {
  default = 3
}

resource "openstack_compute_keypair_v2" "consul" {
  name = "consul"
  public_key = "${file("key/consul.pub")}"
}

resource "openstack_compute_secgroup_v2" "consul" {
  name = "consul"
  description = "Rules for consul tests"
  rule {
    from_port = 1
    to_port = 65535
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = 1
    to_port = 65535
    ip_protocol = "tcp"
    cidr = "::/0"
  }
  rule {
    from_port = 1
    to_port = 65535
    ip_protocol = "udp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = 1
    to_port = 65535
    ip_protocol = "udp"
    cidr = "::/0"
  }
  rule {
    from_port = -1
    to_port = -1
    ip_protocol = "icmp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = -1
    to_port = -1
    ip_protocol = "icmp"
    cidr = "::/0"
  }
}

resource "openstack_compute_servergroup_v2" "consul" {
  name = "consul"
  policies = ["anti-affinity"]
}

resource "openstack_compute_instance_v2" "consul" {
  count = "${var.count}"
  name = "${format("consul-%02d", count.index+1)}"
  image_name = "Ubuntu 14.04"
  flavor_name = "m1.tiny"
  key_pair = "consul"
  security_groups = ["${openstack_compute_secgroup_v2.keepalived.name}"]
  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.consul.id}"
  }
}

resource "null_resource" "consul" {
  count = "${var.count}"

  connection {
    user = "ubuntu"
    key_file = "key/consul"
    host = "${element(openstack_compute_instance_v2.consul.*.access_ip_v6, count.index)}"
  }

  provisioner "file" {
    source = "files"
    destination = "files"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/",
      "sudo bash /home/ubuntu/files/install.sh"
    ]
  }
}

resource "aws_route53_record" "consul-aaaa" {
  zone_id = "YOUR-ZONE-ID"
  name = "consul.YOUR-DOMAIN-NAME"
  type = "AAAA"
  ttl = "60"
  records = ["${replace(openstack_compute_instance_v2.consul.*.access_ip_v6, "/[\[\]]/", "")}"]
}

resource "aws_route53_record" "consul-txt" {
  zone_id = "YOUR-ZONE-ID"
  name = "consul.YOUR-DOMAIN-NAME"
  type = "TXT"
  ttl = "60"
  records = ["${formatlist("%s.YOUR-DOMAIN-NAME", openstack_compute_instance_v2.consul.*.name)}"]
}

resource "aws_route53_record" "consul-individual" {
  count = "${var.count}"
  zone_id = "YOUR-ZONE-ID"
  name = "${format("consul-%02d.YOUR-DOMAIN-NAME", count.index+1)}"
  type = "AAAA"
  ttl = "60"
  records = ["${replace(element(openstack_compute_instance_v2.consul.*.access_ip_v6, count.index), "/[\[\]]/", "")}"]
}
