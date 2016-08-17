import os
import json
from distutils.spawn import find_executable
import hashlib
import subprocess

#show command that is running
def run(cmd):
  print "Running " + cmd
  os.system(cmd)

def cmdOut(cmd):
  return subprocess.check_output(cmd, shell=True).strip()

#easily calculate checksum of file to see if it's modified'
def md5(fname):
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

def loadVars():
  with open('terraform/variables.json', 'r') as f:
    return json.load(f)

def saveVars(vars):
  with open('terraform/variables.json', 'w') as f:
    json.dump(vars, f)

def bake(bakeType):
  print "baking " + bakeType

  vars = loadVars()
  baseAmi = vars["variable"][bakeType]["id"]

  if bakeType == "deploy-ami":
    baseAmi = vars["variable"]["base-ami"]["id"]

  run("packer build -var-file=aws.json -var 'baseAmi=" + baseAmi + "' -machine-readable packer/" + bakeType + ".json | tee packer.log")
  baseAmi = cmdOut("egrep -m1 -oe 'ami-.{8}' packer.log")
  run("rm packer.log")
  
  vars["variable"][bakeType]["id"] = baseAmi
  saveVars(vars)

  print "ami baked: " + baseAmi

def bakeCheck(bakeType, diffFile):
  vars = loadVars()
  #check to see if image has been baked before

  bakeMd5 = md5(diffFile)
  oldBakeMd5 = vars["variable"][bakeType]["md5"]
  status = False
  if oldBakeMd5 != bakeMd5:
    status = True
    vars["variable"][bakeType]["md5"] = bakeMd5
    saveVars(vars)
  return status
    
    


################## Begin Pipeline ####################

#check and bake base ami
if bakeCheck('base-ami', 'packer/base-ami.json'):
  bake('base-ami')
else:
  print "Base ami already baked, skipping."

#check and bake deployment ami
if bakeCheck('deploy-ami', 'workdir/index.html'):
  bake('deploy-ami')
else:
  print "Application not changed, skipping bake and deployment."

#deploy
with open('aws.json', 'r') as f:
  creds = json.load(f)

vars = loadVars()
baseAmi = vars["variable"]["deploy-ami"]["id"]

run("cd terraform && terraform apply -refresh=true -var 'ami=" + baseAmi + "' -var 'key=" + creds["key"] + "' -var 'secret=" + creds["secret"] + "'")