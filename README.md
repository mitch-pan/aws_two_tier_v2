# aws_two_tier_v2

This repo is an overhaul of the Palo Alto Networks repo found at 
https://github.com/PaloAltoNetworks/terraform-templates/tree/master/aws_two_tier.  
That repo was outdated, with old AMIs, an invalid config (no UUIDs), and required you to create your own bootstrap 
S3 bucket.  <p>
This repo will generate a new SSH key, S3 bucket based on the contents of the <code>files</code> directory and pick the 
appropriate VM-Series AMI dynamically based on your region.

##Prerequesits
Ensure that the AWS CLI is installed.  More info can be found here:<br><br>
MAC - https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-mac.html<br>
Windows - https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-windows.html


Make sure you have your AWS credentials configured, per the guidelines here: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html.  For instance on Mac or Linux machine, you should have a ~/.aws/credentials file.

## Getting Started
####Download the aws_two_tier_v2 repo:
<code>git clone https://github.com/mitch-pan/aws_two_tier_v2.git
<br>cd aws_two_tier_v2 directory</code>

####Write to license file
Make sure a registered auth code is present in the files/license/authcodes file.  This will be used during the bootstrapping
process.  You can also update the contents of the files/content directory if you like, and include more current App / Threat
and Antivirus signatures.
<br>

####Run terraform
 <code>terraform init</code><br/>
 <code>terraform plan</code><br>
 <code>terraform apply</code><br>
<br>
When completed, there will be several terraform output you will want to take note of:
<br><br>
<ul>
<li><code>FW_SSH_Command</code></li>
<li><code>FirewallManagementURL</code></li>
<li><code>Ubuntu_SSH_Command</code></li>
<li><code>WebURL</code></li>
</ul>

You can copy and paste the values of each of these variables for easier ssh and web access later.

####SSH into VM and set admin password<br>
When the script completes, chmod the private_key file to have the appropriate permissions.
<br><br><code>chmod 600 private_key</code><br><br>
After the VM-Series has come up (this takes about 10-15 minutes, due to reboot during bootstrapping), log into the CLI 
and change the password for admin.  One of the terraform outputs shown will include this command with the appropriate NGFW
MGMT IP address.
<br><br>
<code>ssh -i ./private_key admin@NGFW_IP</code><br><br>
Verify that the bootstraping procedure completed correctly.  You should see a serial number and
content for "app-version" and "av-version".<br><br>
<code>show system info</code><br><br>
If things look good, proceed with changing the admin password<br><br>
<code>configure</code><br>
<code>set mgt-config users admin password</code><br>
<code>commit</code><br>


####Log into NGFW GUI with newly configured credentials<br>
Use the terraform output "FirewallManagementURL" to determnine the IP to use for the NGFW's 
management address.


####Install Apache web server on the Linux host
If you want to observer HTTP traffic through the NGFW, install apache on the Ubuntu server that was created.  The output
from terraform will include the ssh command to log into the Linux server.  It will use port 221 to connect.  The
exact command is in the <code>Ubuntu_SSH_Command</code> output, and should look something like this:<br>
<br>
<code>ssh -i private_key ubuntu@<NGFW_Public_IP> -p 221</code>
<br>
<br>Once in, execute:<br>
<code>sudo apt-get install apache2</code>

<br>
To reach the web server, use the URL given in the scrip output, which is the NGFW's public IP address.

####Destroy Instance
When you are done, use terraform to destroy your deployment<br>
<br>
Optional - Reclaim the license associated with the authcode you used.  To do this follow the procedures 
[here](https://docs.paloaltonetworks.com/vm-series/10-0/vm-series-deployment/license-the-vm-series-firewall/deactivate-the-licenses.html) 
before you destroy the deployment.
<br><br>
When you are ready to destroy the deployment, just run:<br><br>
<code>terraform destroy</code> and answer yes if it all looks correct.

## Support
This is a community project, all input and help is welcome.

## Authors
* Mitch Rappard - [(@mitch-pan)](https://github.com/mitch-pan)
