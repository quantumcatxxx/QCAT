Usage Instructions:

PreRequisites:
- Docker installed and running
- Flattened Smart Contract (Already Included in Folder)
- XLINK signed private key


Run Script: 
- Add "privkey.txt" with a TEST Private key inside. (DO NOT PUSH ANY PRIV KEYS TO ANY BRANCH) They should be Git Ignored. 
- CD to the folder that you are running the script in. 
- run npm install
- configure, token/contract details For larger contracts use:
`solc --optimize --optimize-runs 200 --evm-version paris --combined-json abi,bin ${contract.path}`, { encoding: "utf8" }
- change desired EVM version in script and in dockerfile
- run node index.js

troubleshooting:

Contracts need to be flattened before adding to the .sol file used in the script, if you are using a custom contract you can flatten the contract using Remix and then copy and paste the code into one file. 


