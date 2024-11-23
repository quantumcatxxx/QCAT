// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract SampleToken {

    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowances;

    uint public totalSupply;
    string public name;
    string public symbol;
    uint public decimals;
    
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor(string memory _name, string memory _sym, uint _dec, uint _ts) {
        name = _name;
        symbol = _sym;
        decimals = _dec;
        totalSupply = _ts * 10 ** _dec;
        balances[msg.sender] = totalSupply;
    }

    function allowance(address owner, address spender) external view returns(uint) {
        return allowances[owner][spender];
    }
    
    function balanceOf(address owner) external view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) external returns(bool) {
        require(balances[msg.sender] >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balances[from] >= value, 'balance too low');
        require(allowances[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}
