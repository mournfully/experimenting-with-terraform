# ~/terraform-testbench/test.tf

# $ terraform init && terraform apply << yes
# output "text" {
# 	value = "hello world"
# 	value = file("${path.module}/text.txt")
# }

# resource resource-type resource-name
resource "null_resource" "node1" {
	# add provisioners here
	provisioner "local-exec" {
		# $ terraform init && terraform apply << yes
		command = "echo >> ${path.module}/node1.txt"
	}
	
	provisioner "local-exec" {
		# $ terraform destroy
		command = "rm ${path.module}/node1.txt"
		when = destroy
	}
}