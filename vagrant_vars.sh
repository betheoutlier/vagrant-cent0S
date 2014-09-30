    
##### MYSQL #####
HostName="localhost" #requried
dbName="project" #requried
dbUser="root" #requried
dbPass="pass" #requried

#the root user is used by Puppet provisioning. If you HAVE to change root user info, you will have to adjust that provisioning. 
#I recommend you just use a different user and define it above. 
dbRootPass="pass" #updating this value alone will not suffice in updating the root user password.