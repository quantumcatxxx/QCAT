import { ethers } from "ethers";
import { execSync } from "child_process";
import { existsSync, readFileSync } from "fs";

// ensure privkey.txt was present in the docker build context
const privKeyPath = 'privkey.txt'
if(!existsSync(privKeyPath)){
    console.error(`private key '${privKeyPath}' was not found! exiting.`);
    process.exit(1);
}

// init rpc provider
const provider = new ethers.providers.JsonRpcProvider('https://rpc-testnet.qanplatform.com');

// init wallet using mounted private key, then connect provider to it
const privKey = readFileSync(privKeyPath).toString('utf8').trim();
const wallet = new ethers.Wallet(privKey).connect(provider);

// define contract object, set path and name (rest will be defined later below)
const contract = {
    path: 'sample.sol',
    name: 'SampleToken',
    abi: null,
    bin: null,
    txHash: null,
    address: null,
    instance: null
}

// compile and parse contract
const compiled = JSON.parse(
    execSync(`solc --evm-version paris --combined-json abi,bin ${contract.path}`, { encoding: "utf8" })
);

// extract abi and binary bytecode
contract.abi = compiled.contracts[`${contract.path}:${contract.name}`].abi;
contract.bin = compiled.contracts[`${contract.path}:${contract.name}`].bin;

// create contract factory for deployment
let factory = new ethers.ContractFactory(
    contract.abi,
    contract.bin,
    wallet
);

// define constructor arguments and deploy contract
const constructorArgs = {
    _name: "The Quantum Cat",
    _sym: "QCAT",
    _dec: 18,
    _ts: 2000000000
};
factory = await factory.deploy(...Object.values(constructorArgs))

// save deployment tx hash of contract, await deployment completion, then save contract addr
contract.txHash = factory.deployTransaction.hash;
console.log(`deployment tx in progress: ${contract.txHash}`);
await factory.deployTransaction.wait();
contract.address = factory.address;

// initialize a fresh, on-chain instance of the contract using the deployer wallet as signer
contract.instance = new ethers.Contract(contract.address, contract.abi, wallet);

// issue a read operation to a contract function on-chain
const onChainName = await contract.instance.name();
console.log(`on-chain contract name: ${onChainName}`)

// issue a write operation to a contract function on-chain (transfer to self)
const tx = await contract.instance.transfer(wallet.address, 1);
console.log(`transfer tx in progress: ${tx.hash}`);
await tx.wait();

// transfer completed
console.log(`transfer completed!`);
