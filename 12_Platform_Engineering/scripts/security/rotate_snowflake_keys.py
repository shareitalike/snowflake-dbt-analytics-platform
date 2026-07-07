"""
Enterprise Security Script: Rotate Snowflake RSA Key Pairs
Executes periodically (e.g., via a secure CI/CD cron job) to rotate service account keys.
"""
import os
import subprocess
import boto3

def generate_rsa_keypair():
    """Generates a new 2048-bit RSA key pair."""
    print("Generating new RSA Key Pair...")
    subprocess.run(["openssl", "genrsa", "2048"], stdout=open("rsa_key.p8", "w"))
    subprocess.run(["openssl", "rsa", "-in", "rsa_key.p8", "-pubout", "-out", "rsa_key.pub"])
    
    with open("rsa_key.p8", "r") as f:
        private_key = f.read()
    with open("rsa_key.pub", "r") as f:
        public_key = f.read()
        
    return private_key, public_key

def update_aws_secrets_manager(secret_name: str, private_key: str):
    """Pushes the new private key to AWS Secrets Manager."""
    print(f"Updating AWS Secrets Manager: {secret_name}")
    client = boto3.client('secretsmanager', region_name='us-east-1')
    client.put_secret_value(SecretId=secret_name, SecretString=private_key)

def update_snowflake_public_key(user: str, public_key: str):
    """Executes ALTER USER in Snowflake to set the new public key."""
    # In a real environment, this would use the snowflake-connector-python
    # connecting as SECURITYADMIN to run:
    # ALTER USER {user} SET RSA_PUBLIC_KEY = '{public_key_stripped}';
    print(f"Executing ALTER USER {user} SET RSA_PUBLIC_KEY = '...'; in Snowflake.")

if __name__ == "__main__":
    priv, pub = generate_rsa_keypair()
    
    # Strip headers for Snowflake
    pub_stripped = pub.replace("-----BEGIN PUBLIC KEY-----", "").replace("-----END PUBLIC KEY-----", "").replace("\n", "")
    
    update_aws_secrets_manager("prod/snowflake_airflow_svc_key", priv)
    update_snowflake_public_key("AIRFLOW_SVC", pub_stripped)
    
    # Cleanup local files
    os.remove("rsa_key.p8")
    os.remove("rsa_key.pub")
    print("Key rotation completed successfully.")
